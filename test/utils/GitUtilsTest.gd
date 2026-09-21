## GitUtils — git availability probe.


static func GitUtils_is_git_installed_test() -> void:
	# The probe returns a plain bool and stays stable across calls.
	var installed := GitUtils.is_git_installed()
	assert(installed is bool)
	assert(GitUtils.is_git_installed() == installed)
	# An independent shell probe must agree with the direct executable call.
	var probe := OSUtils.execute(OSUtils.build_shell_argv("git --version"), false)
	assert(installed == (probe.exit_code == 0))
	if installed:
		assert(probe.output.build_string().contains("git version"))
	pass


static func GitUtils_Git_command_context_test() -> void:
	if not GitUtils.is_git_installed():
		return
	var git := GitUtils.Git.new("repo path/.git", "repo path")
	assert(git.git_dir == "repo path/.git")
	assert(git.work_tree == "repo path")
	assert(git.config == GitUtils.GIT_CONFIG)
	pass
