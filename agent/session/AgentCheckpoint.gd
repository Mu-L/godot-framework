class_name AgentCheckpoint
extends RefCounted

## Workspace snapshots for chat revert — one shared shadow git repo under `.gai/checkpoints/`.
##
## Every command uses an isolated [GitUtils.Git] context, so the user's own repository is never
## read or written. A snapshot is taken before each user turn and reverting restores that state.

const CHECKPOINTS_SUBDIR := ".gai/checkpoints"
const SHALLOW_FILE := "shallow"
const COMMIT_MESSAGE := "gai checkpoint"
const MAX_CHECKPOINTS := 100
const CHECKPOINTS_AFTER_CLEANUP := 50

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

static func get_git_dir() -> String:
	return AgentWorkspace.get_root().path_join(CHECKPOINTS_SUBDIR)


static func ensure_repo() -> bool:
	var git_dir := get_git_dir()
	var git := GitUtils.Git.new(git_dir, AgentWorkspace.get_root())
	if DirAccess.dir_exists_absolute(git_dir):
		# Supplying --work-tree makes Git report false even for a valid bare repository.
		var check := await git.async_is_bare()
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
	var init := await git.async_init_bare()
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
	var git_exclude_path := git_dir.path_join("info/exclude")
	if FileUtils.write_string_to_file(git_exclude_path, exclude_rules):
		return true
	Log.error("agent checkpoint exclude write failed:[{}]", git_exclude_path)
	return false


## Deletes only the exact shadow repository path after validation has declared it invalid.
static func remove_checkpoint_repo(git_dir: String) -> bool:
	var expected := AgentWorkspace.get_root().path_join(CHECKPOINTS_SUBDIR).simplify_path()
	if git_dir.simplify_path() != expected:
		Log.error("agent checkpoint refused unexpected delete path:[{}]", git_dir)
		return false
	if FileUtils.delete_file_or_directory(git_dir):
		return true
	Log.error("agent checkpoint repository delete failed:[{}]", git_dir)
	return false


static func stage_all() -> bool:
	var git := GitUtils.Git.new(get_git_dir(), AgentWorkspace.get_root())
	var add := await git.async_stage_all()
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
	var git := GitUtils.Git.new(get_git_dir(), AgentWorkspace.get_root())
	var previous_head := await git.async_get_head()
	if previous_head.exit_code == 0:
		var diff := await git.async_has_staged_changes()
		if diff.exit_code == 0:
			return previous_head.output.build_string().strip_edges()
		if diff.exit_code > 1:
			Log.error("agent checkpoint tree comparison failed:[{}]", diff.output.build_string())
			return StringUtils.EMPTY
	var commit := await git.async_commit(COMMIT_MESSAGE)
	if commit.exit_code != 0:
		Log.error("agent checkpoint commit failed:[{}]", commit.output.build_string())
		return StringUtils.EMPTY
	var head := await git.async_get_head()
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
	var git := GitUtils.Git.new(get_git_dir(), AgentWorkspace.get_root())
	var history := await git.async_list_commits(MAX_CHECKPOINTS + 1)
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
	var reflog := await git.async_expire_reflogs()
	if reflog.exit_code != 0:
		Log.error("agent checkpoint reflog cleanup failed:[{}]", reflog.output.build_string())
		return
	var gc := await git.async_gc_prune_now()
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
	var git := GitUtils.Git.new(get_git_dir(), AgentWorkspace.get_root())
	var diff := await git.async_get_staged_name_status(sha)
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
	var checkout := await git.async_checkout_tree(sha)
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
