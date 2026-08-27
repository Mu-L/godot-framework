class_name ProcessRunner
extends RefCounted

## Runs a subprocess with OS.execute_with_pipe; reads stdout/stderr on a worker
## thread and streams complete lines to the main thread without blocking the UI.

const READ_CHUNK_SIZE := 4096
const POLL_DELAY_MSEC := 16

static var active_pid: int = -1


class ExecResult:
	var exit_code: int = -1
	var output: Array[String] = []


class PipeLineBuffer:
	var partial: String = ""
	var collected: Array[String] = []
	var on_output_line: Callable = Callable()

	func _init(p_collected: Array[String], p_on_output_line: Callable = Callable()) -> void:
		collected = p_collected
		on_output_line = p_on_output_line
		pass

	func feed(text: String) -> void:
		partial += text
		while true:
			var newline_index := partial.find("\n")
			if newline_index < 0:
				break
			var line := partial.substr(0, newline_index).strip_edges()
			partial = partial.substr(newline_index + 1)
			emit_line(line)
		pass

	func flush_partial() -> void:
		var line := partial.strip_edges()
		partial = ""
		emit_line(line)
		pass

	func emit_line(line: String) -> void:
		if line.is_empty():
			return
		collected.append(line)
		var captured := line
		gdf.callable_deferred(func() -> void:
			Log.info("[Output] {}", captured)
			if on_output_line.is_valid():
				on_output_line.call(captured)
		)
		pass


static func stop_current() -> void:
	var pid := active_pid
	if pid > 0 and OS.is_process_running(pid):
		OS.kill(pid)
	active_pid = -1
	pass


static func async_execute(
	argv: PackedStringArray,
	on_output_line: Callable = Callable(),
) -> ExecResult:
	var result := ExecResult.new()
	if argv.is_empty():
		return result

	var thread := Thread.new()
	thread.start(_run_in_thread.bind(argv, result, on_output_line))
	while thread.is_alive():
		await Engine.get_main_loop().process_frame
	thread.wait_to_finish()
	return result


static func _run_in_thread(
	argv: PackedStringArray,
	result: ExecResult,
	on_output_line: Callable,
) -> void:
	var proc := OS.execute_with_pipe(argv[0], argv.slice(1), false)
	if proc.is_empty():
		result.exit_code = -1
		return

	var pid: int = int(proc.get("pid", -1))
	active_pid = pid
	var stdio: FileAccess = proc.get("stdio")
	var stderr_pipe: FileAccess = proc.get("stderr")
	var stdout_buffer := PipeLineBuffer.new(result.output, on_output_line)
	var stderr_buffer := PipeLineBuffer.new(result.output, on_output_line)

	while pid > 0 and OS.is_process_running(pid):
		drain_pipe_chunk(stdio, stdout_buffer)
		drain_pipe_chunk(stderr_pipe, stderr_buffer)
		OS.delay_msec(POLL_DELAY_MSEC)

	drain_pipe_chunk(stdio, stdout_buffer, true)
	drain_pipe_chunk(stderr_pipe, stderr_buffer, true)
	stdout_buffer.flush_partial()
	stderr_buffer.flush_partial()

	close_pipe(stdio)
	close_pipe(stderr_pipe)

	if pid > 0:
		result.exit_code = OS.get_process_exit_code(pid)
	if result.exit_code == -1 and pid <= 0:
		result.exit_code = -1
	active_pid = -1
	pass


static func drain_pipe_chunk(pipe: FileAccess, buffer: PipeLineBuffer, final: bool = false) -> void:
	if pipe == null or not pipe.is_open():
		return

	while true:
		var chunk := pipe.get_buffer(READ_CHUNK_SIZE)
		var err := pipe.get_error()
		if chunk.is_empty():
			if final or err != OK:
				break
			return

		buffer.feed(chunk.get_string_from_utf8())
		if err != OK:
			break
	pass


static func close_pipe(pipe: FileAccess) -> void:
	if pipe != null and pipe.is_open():
		pipe.close()
	pass
