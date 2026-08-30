class_name OSUtils
extends Object

## Subprocess execution. Sync `execute` uses OS.execute; async `async_execute`
## uses OS.execute_with_pipe on a worker thread. Output chunks append to
## ExecResult.output and Log.info.

static var process_pids: RingIntList = RingIntList.new(32)


static func is_windows() -> bool:
	return OS.get_name().strip_edges().to_lower() == "windows"


class ExecResult:
	var exit_code: int = -1
	var output: PackedStringArray = PackedStringArray()

	func output_text() -> String:
		return "".join(output)


static func stop_current() -> void:
	var pid := process_pids.latest()
	if pid > 0 and OS.is_process_running(pid):
		OS.kill(pid)
	pass


static func stop_all() -> void:
	for pid in process_pids.to_array():
		if pid > 0 and OS.is_process_running(pid):
			OS.kill(pid)
	process_pids.clear()
	pass


static func execute(argv: PackedStringArray) -> ExecResult:
	var result := ExecResult.new()
	if argv.is_empty():
		return result

	var lines: Array = []
	result.exit_code = OS.execute(argv[0], argv.slice(1), lines, true)
	var parts := PackedStringArray()
	for line in lines:
		parts.append(str(line))
	append_output(result, "\n".join(parts))
	return result


static func async_execute(argv: PackedStringArray) -> ExecResult:
	var result := ExecResult.new()
	if argv.is_empty():
		return result

	var thread := Thread.new()
	thread.start(_run_process_async.bind(argv, result))
	while thread.is_alive():
		await Engine.get_main_loop().process_frame
	thread.wait_to_finish()
	return result


static func _run_process_async(argv: PackedStringArray, result: ExecResult) -> void:
	var proc := OS.execute_with_pipe(argv[0], argv.slice(1), false)
	if proc.is_empty():
		result.exit_code = -1
		return

	var pid: int = int(proc.get("pid", -1))
	if pid > 0:
		process_pids.add(pid)
	var stdio: FileAccess = proc.get("stdio")
	var stderr_pipe: FileAccess = proc.get("stderr")

	while pid > 0 and OS.is_process_running(pid):
		drain_pipe(result, stdio)
		drain_pipe(result, stderr_pipe)
		OS.delay_msec(16)

	drain_pipe(result, stdio, true)
	drain_pipe(result, stderr_pipe, true)
	close_pipe(stdio)
	close_pipe(stderr_pipe)

	result.exit_code = OS.get_process_exit_code(pid) if pid > 0 else -1
	if pid > 0:
		process_pids.remove_value(pid)
	pass


static func drain_pipe(result: ExecResult, pipe: FileAccess, final: bool = false) -> void:
	if pipe == null or not pipe.is_open():
		return

	while true:
		var chunk := pipe.get_buffer(4096)
		var err := pipe.get_error()
		if chunk.is_empty():
			if final or err != OK:
				break
			return

		if is_windows():
			append_output(result, chunk.get_string_from_multibyte_char(""))
		else:
			append_output(result, chunk.get_string_from_utf8())
		if err != OK:
			break
	pass


static func append_output(result: ExecResult, text: String) -> void:
	if StringUtils.is_empty(text):
		return
	result.output.append(text)
	Log.info("[Output] {}", text)
	pass


static func close_pipe(pipe: FileAccess) -> void:
	if pipe != null and pipe.is_open():
		pipe.close()
	pass
