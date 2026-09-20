class_name AgentCheckpoint
extends RefCounted

## Workspace snapshots for chat revert — one shared shadow git repo under `.gai/checkpoints/`.
##
## Every call passes `--git-dir=<shadow>` + `--work-tree=<workspace root>`, so the user's own
## repository is never read or written (and the agent's `git` commands cannot disturb the shadow).
## A snapshot is taken before each user turn; reverting a chat entry restores that state.

const CHECKPOINTS_SUBDIR := ".gai/checkpoints"
const EXCLUDE_FILE := "info/exclude"
## `.git` is the user's real repository — snapshots must never swallow it.
const EXCLUDE_RULES := ".git/\n.gai/\n.godot/\n"
const COMMIT_MESSAGE := "checkpoint"

## Injected per call so the shadow repo ignores whatever global git config the machine has.
const GIT_CONFIG_ARGS: PackedStringArray = [
	"-c", "user.name=gai",
	"-c", "user.email=gai@gai.local",
	"-c", "commit.gpgsign=false",
	"-c", "core.autocrlf=false",
	"-c", "core.filemode=false",
	"-c", "core.quotepath=false",
]

## Cleared after the first failure — no git, no checkpoints; the agent keeps working.
static var available: bool = true


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
	if not available:
		return false
	var git_dir := get_git_dir()
	if DirAccess.dir_exists_absolute(git_dir):
		return true
	DirAccess.make_dir_recursive_absolute(git_dir.get_base_dir())
	var init := await OSUtils.async_execute(PackedStringArray(["git", "init", "--bare", "--quiet", git_dir]), false)
	if init.exit_code != 0:
		disable(init)
		return false
	FileUtils.write_string_to_file(git_dir.path_join(EXCLUDE_FILE), EXCLUDE_RULES)
	return true


static func stage_all() -> bool:
	var add := await run_git(PackedStringArray(["add", "-A"]))
	if add.exit_code == 0:
		return true
	disable(add)
	return false


static func disable(result: OSUtils.ExecResult) -> void:
	available = false
	Log.error("agent checkpoint disabled, git failed:[{}]", result.output.build_string())
	pass


# ---------------------------------------------------------------------------
# Snapshot / restore
# ---------------------------------------------------------------------------

## Commits the current workspace state and returns the commit id; empty when unavailable.
static func async_snapshot() -> String:
	if not await ensure_repo() or not await stage_all():
		return StringUtils.EMPTY
	var commit := await run_git(PackedStringArray(["commit", "--quiet", "--allow-empty", "-m", COMMIT_MESSAGE]))
	if commit.exit_code != 0:
		disable(commit)
		return StringUtils.EMPTY
	var head := await run_git(PackedStringArray(["rev-parse", "HEAD"]))
	return head.output.build_string().strip_edges() if head.exit_code == 0 else StringUtils.EMPTY


## Reverts the workspace to [param sha]: files changed since then are put back, files created since are removed.
static func async_restore(sha: String) -> void:
	if StringUtils.is_blank(sha) or not DirAccess.dir_exists_absolute(get_git_dir()):
		return
	if not await stage_all():
		return
	var diff := await run_git(PackedStringArray(["diff", "--cached", "--name-status", sha]))
	if diff.exit_code != 0:
		return
	var removed := collect_removed_paths(diff.output.build_string())
	# `:/` is the worktree root regardless of the process working directory.
	await run_git(PackedStringArray(["checkout", sha, "--", ":/"]))
	for path in removed:
		FileUtils.delete_file(AgentWorkspace.get_root().path_join(path))
	Alert.alert("Workspace restored", Colors.success)
	pass


## Added / copied / renamed targets did not exist at the checkpoint — revert removes them.
static func collect_removed_paths(name_status_text: String) -> PackedStringArray:
	var paths := PackedStringArray()
	for line in name_status_text.split(FileUtils.NEWLINE_LF, false):
		var parts := line.split("\t", false)
		if parts.size() < 2:
			continue
		var status := parts[0].strip_edges()
		if status.begins_with("A") or status.begins_with("C") or status.begins_with("R"):
			paths.append(parts[parts.size() - 1].strip_edges())
	return paths
