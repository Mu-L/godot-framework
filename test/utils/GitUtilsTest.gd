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
