class_name AgentCheckpoint
extends RefCounted

## Workspace snapshots for chat revert — one shared shadow git repo under `.gai/checkpoints/`.
##
## Every call passes `--git-dir=<shadow>` + `--work-tree=<workspace root>`, so the user's own
## repository is never read or written (and the agent's `git` commands cannot disturb the shadow).
## A snapshot is taken before each user turn; reverting a chat entry restores that state.

const CHECKPOINTS_SUBDIR := ".gai/checkpoints"
const EXCLUDE_FILE := "info/exclude"
const SHALLOW_FILE := "shallow"
const COMMIT_MESSAGE := "checkpoint"
const MAX_CHECKPOINTS := 100
const CHECKPOINTS_AFTER_CLEANUP := 50

## Injected per call so the shadow repo ignores whatever global git config the machine has.
const GIT_CONFIG_ARGS: PackedStringArray = [
	"-c", "user.name=gai",
	"-c", "user.email=gai@gai.local",
	"-c", "commit.gpgsign=false",
	"-c", "core.autocrlf=false",
	"-c", "core.filemode=false",
	"-c", "core.quotepath=false",
]

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

static func get_git_dir() -> String:
	return AgentWorkspace.get_root().path_join(CHECKPOINTS_SUBDIR)


# ---------------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------------

static func run_git(args: PackedStringArray) -> OSUtils.ExecResult:
	var argv := PackedStringArray(["git", "--git-dir", get_git_dir(), "--work-tree", AgentWorkspace.get_root()])
	argv.append_array(GIT_CONFIG_ARGS)
	argv.append_array(args)
	return await OSUtils.async_execute(argv, false)


static func ensure_repo() -> bool:
	var git_dir := get_git_dir()
	if DirAccess.dir_exists_absolute(git_dir):
		# Supplying --work-tree makes Git report false even for a valid bare repository.
		var check_args := PackedStringArray(["git", "--git-dir", git_dir])
		check_args.append_array(GIT_CONFIG_ARGS)
		check_args.append_array(PackedStringArray(["rev-parse", "--is-bare-repository"]))
		var check := await OSUtils.async_execute(check_args, false)
		if check.exit_code == 0 and check.output.build_string().strip_edges() == "true":
			return write_exclude_rules(git_dir)
		# A missing Git executable is an environment failure, not repository corruption.
		if check.exit_code < 0:
			Log.error("agent checkpoint validation failed to start git:[{}]", check.output.build_string())
			return false
		Log.error("agent checkpoint repository is invalid, recreating:[{}]", check.output.build_string())
		if not remove_checkpoint_repo(git_dir):
			return false
	var mkdir_error := DirAccess.make_dir_recursive_absolute(git_dir.get_base_dir())
	if mkdir_error != OK:
		Log.error("agent checkpoint parent directory create failed path:[{}] error:[{}]", git_dir.get_base_dir(), mkdir_error)
		return false
	var init := await OSUtils.async_execute(PackedStringArray(["git", "init", "--bare", "--quiet", git_dir]), false)
	if init.exit_code != 0:
		Log.error("agent checkpoint init failed:[{}]", init.output.build_string())
		return false
	return write_exclude_rules(git_dir)


static func write_exclude_rules(git_dir: String) -> bool:
	var project_rules := FileUtils.read_file_to_string(AgentWorkspace.get_root().path_join(".gitignore"))
	var exclude_rules := project_rules
	if not exclude_rules.is_empty() and not exclude_rules.ends_with(FileUtils.NEWLINE_LF):
		exclude_rules += FileUtils.NEWLINE_LF
	## `.git` is the user's real repository — snapshots must never swallow it.
	## Mandatory rules come last so project negation rules cannot re-include these directories.
	exclude_rules += ".git/\n.gai/\n.godot/\n"
	if FileUtils.write_string_to_file(git_dir.path_join(EXCLUDE_FILE), exclude_rules):
		return true
	Log.error("agent checkpoint exclude write failed:[{}]", git_dir.path_join(EXCLUDE_FILE))
	return false


## Deletes only the exact shadow repository path after validation has declared it invalid.
static func remove_checkpoint_repo(git_dir: String) -> bool:
	var expected := AgentWorkspace.get_root().path_join(CHECKPOINTS_SUBDIR).simplify_path()
	if git_dir.simplify_path() != expected:
		Log.error("agent checkpoint refused unexpected delete path:[{}]", git_dir)
		return false
	if FileUtils.delete_directory_recursive(git_dir):
		return true
	Log.error("agent checkpoint repository delete failed:[{}]", git_dir)
	return false


static func stage_all() -> bool:
	var add := await run_git(PackedStringArray(["add", "-A"]))
	if add.exit_code == 0:
		return true
	Log.error("agent checkpoint stage failed:[{}]", add.output.build_string())
	return false


# ---------------------------------------------------------------------------
# Snapshot / restore
# ---------------------------------------------------------------------------

## Commits the current workspace state and returns the commit id; empty when unavailable.
static func async_snapshot() -> String:
	if not await ensure_repo() or not await stage_all():
		return StringUtils.EMPTY
	var previous_head := await run_git(PackedStringArray(["rev-parse", "--verify", "HEAD"]))
	if previous_head.exit_code == 0:
		var diff := await run_git(PackedStringArray(["diff", "--cached", "--quiet", "HEAD", "--"]))
		if diff.exit_code == 0:
			return previous_head.output.build_string().strip_edges()
		if diff.exit_code > 1:
			Log.error("agent checkpoint tree comparison failed:[{}]", diff.output.build_string())
			return StringUtils.EMPTY
	var commit := await run_git(PackedStringArray(["commit", "--quiet", "-m", COMMIT_MESSAGE]))
	if commit.exit_code != 0:
		Log.error("agent checkpoint commit failed:[{}]", commit.output.build_string())
		return StringUtils.EMPTY
	var head := await run_git(PackedStringArray(["rev-parse", "HEAD"]))
	if head.exit_code != 0:
		Log.error("agent checkpoint head lookup failed:[{}]", head.output.build_string())
		return StringUtils.EMPTY
	var sha := head.output.build_string().strip_edges()
	await async_cleanup(false)
	return sha


## When history exceeds [constant MAX_CHECKPOINTS], keeps the newest [constant CHECKPOINTS_AFTER_CLEANUP] commits.
static func async_cleanup(force_gc: bool = true) -> void:
	if not await ensure_repo():
		return
	var history := await run_git(PackedStringArray(["rev-list", "--max-count=" + str(MAX_CHECKPOINTS + 1), "HEAD"]))
	if history.exit_code != 0:
		# An initialized repository without its first commit has nothing to clean.
		return
	var commits := history.output.build_string().strip_edges().split(FileUtils.NEWLINE_LF, false)
	var truncated := commits.size() > MAX_CHECKPOINTS
	if truncated:
		var boundary := commits[CHECKPOINTS_AFTER_CLEANUP - 1].strip_edges()
		if not FileUtils.write_string_to_file(get_git_dir().path_join(SHALLOW_FILE), boundary + FileUtils.NEWLINE_LF):
			Log.error("agent checkpoint shallow boundary write failed:[{}]", boundary)
			return
	if not truncated and not force_gc:
		return
	var reflog := await run_git(PackedStringArray(["reflog", "expire", "--expire=now", "--all"]))
	if reflog.exit_code != 0:
		Log.error("agent checkpoint reflog cleanup failed:[{}]", reflog.output.build_string())
		return
	var gc := await run_git(PackedStringArray(["gc", "--prune=now", "--quiet"]))
	if gc.exit_code != 0:
		Log.error("agent checkpoint gc failed:[{}]", gc.output.build_string())
	pass


## Reverts the workspace to [param sha]: files changed since then are put back, files created since are removed.
## Returns false when Git cannot complete the restore; callers must keep chat history intact on failure.
static func async_restore(sha: String) -> bool:
	if StringUtils.is_blank(sha) or not await ensure_repo():
		return false
	if not await stage_all():
		return false
	var diff := await run_git(PackedStringArray(["diff", "--cached", "--name-status", sha]))
	if diff.exit_code != 0:
		Log.error("agent checkpoint restore diff failed:[{}]", diff.output.build_string())
		return false
	# Added / copied / renamed targets did not exist at the checkpoint — revert removes them.
	var removed := PackedStringArray()
	for line in diff.output.build_string().split(FileUtils.NEWLINE_LF, false):
		var parts := line.split("\t", false)
		if parts.size() < 2:
			continue
		var status := parts[0].strip_edges()
		if status.begins_with("A") or status.begins_with("C") or status.begins_with("R"):
			removed.append(parts[parts.size() - 1].strip_edges())
	# `:/` is the worktree root regardless of the process working directory.
	var checkout := await run_git(PackedStringArray(["checkout", sha, "--", ":/"]))
	if checkout.exit_code != 0:
		Log.error("agent checkpoint restore checkout failed:[{}]", checkout.output.build_string())
		return false
	for path in removed:
		var absolute_path := AgentWorkspace.get_root().path_join(path)
		if not FileAccess.file_exists(absolute_path):
			continue
		var error := DirAccess.remove_absolute(absolute_path)
		if error != OK:
			Log.error("agent checkpoint restore delete failed path:[{}] error:[{}]", absolute_path, error)
			return false
	return true
