static func OSUtils_is_windows_test() -> void:
	assert(OSUtils.is_windows() == (OS.get_name().strip_edges().to_lower() == "windows"))
	pass


static func OSUtils_empty_argv_test() -> void:
	OSUtils.stop_all()
	var result := await OSUtils.async_execute(PackedStringArray())
	assert(result.exit_code == -1)
	assert(result.output.is_empty())
	assert(OSUtils.process_pids.is_empty())
	pass


static func OSUtils_echo_test() -> void:
	OSUtils.stop_all()
	var result := await OSUtils.async_execute(echo_argv("OSUtilsTestHello"))
	assert(result.exit_code == 0)
	assert("".join(result.output).contains("OSUtilsTestHello"))
	assert(OSUtils.process_pids.is_empty())
	pass


static func OSUtils_command_not_found_test() -> void:
	OSUtils.stop_all()
	var result := await OSUtils.async_execute(command_not_found_argv())
	assert(result.exit_code != 0)
	assert(OSUtils.process_pids.is_empty())
	pass


static func OSUtils_stop_all_empty_test() -> void:
	OSUtils.stop_all()
	assert(OSUtils.process_pids.is_empty())
	OSUtils.stop_all()
	assert(OSUtils.process_pids.is_empty())
	pass


static func OSUtils_stop_current_test() -> void:
	OSUtils.stop_all()
	gdf.callable_deferred(func() -> void: await OSUtils.async_execute(sleep_argv(15)))
	await ThreadUtils.async_sleep(800)
	assert(OSUtils.process_pids.size() > 0)
	OSUtils.stop_current()
	await ThreadUtils.async_sleep(1500)
	assert(OSUtils.process_pids.is_empty())
	pass


static func OSUtils_stop_all_test() -> void:
	OSUtils.stop_all()
	gdf.callable_deferred(func() -> void: await OSUtils.async_execute(sleep_argv(15)))
	await ThreadUtils.async_sleep(800)
	assert(OSUtils.process_pids.size() > 0)
	OSUtils.stop_all()
	assert(OSUtils.process_pids.is_empty())
	await ThreadUtils.async_sleep(500)
	pass


static func command_not_found_argv() -> PackedStringArray:
	if OSUtils.is_windows():
		return PackedStringArray(["cmd", "/c", "__godot_osutils_missing_executable__"])
	return PackedStringArray(["sh", "-c", "__godot_osutils_missing_executable__"])


static func echo_argv(text: String) -> PackedStringArray:
	if OSUtils.is_windows():
		return PackedStringArray(["cmd", "/c", "echo " + text])
	return PackedStringArray(["sh", "-c", "echo " + text])


static func sleep_argv(seconds: int) -> PackedStringArray:
	if OSUtils.is_windows():
		return PackedStringArray(["cmd", "/c", "ping -n " + str(seconds + 1) + " 127.0.0.1 > nul"])
	return PackedStringArray(["sleep", str(seconds)])
