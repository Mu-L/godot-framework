class_name OpenAiClient
extends Object

## Local-dev only. Replace with a backend proxy before shipping.
## Reads from env OPENAI_API_KEY by default; can still override at runtime.
const API_KEY_ENV := "OPENAI_API_KEY"
static var api_key: String = OS.get_environment(API_KEY_ENV)
static var base_url: String = "https://api.deepseek.com/chat/completions"
static var model: String = "deepseek-v4-flash"


static func build_messages(prompt: String, system_prompt: String = "") -> Array[ChatMessage]:
	var messages: Array[ChatMessage] = []
	if StringUtils.is_not_blank(system_prompt):
		messages.append(ChatMessage.new(ChatMessage.ROLE_SYSTEM, system_prompt))
	messages.append(ChatMessage.new(ChatMessage.ROLE_USER, prompt))
	return messages


static func build_headers(stream: bool = false) -> PackedStringArray:
	var headers := PackedStringArray([StringUtils.format("Authorization: Bearer {}", api_key)])
	if stream:
		headers.append("Accept: text/event-stream")
	return headers

static func validate_messages(messages: Array[ChatMessage]) -> bool:
	if StringUtils.is_blank(api_key):
		Log.error("OpenAI api_key is empty, set env {}", API_KEY_ENV)
		return false
	if messages.is_empty():
		Log.error("OpenAI messages is empty")
		return false
	return true


# ----------------------------------------------------------------------------------------------------------------------

static func async_chat(prompt: String, system_prompt: String = "") -> String:
	return await async_chat_messages(build_messages(prompt, system_prompt))


static func async_chat_stream(prompt: String, system_prompt: String = "", on_delta: Callable = Callable()) -> String:
	return await async_chat_messages_stream(build_messages(prompt, system_prompt), on_delta)

static func async_chat_messages(messages: Array[ChatMessage]) -> String:
	if not validate_messages(messages):
		return StringUtils.EMPTY
	var request := OpenAiRequest.new(model, messages, false)
	var response := await HttpHelper.async_post(base_url, JsonUtils.object_to_json(request), build_headers())
	var body := response.get_body_string()
	Log.info("OpenAI response body:[{}]", StringUtils.truncate(body, 512))
	if not response.success or response.code != 200:
		Log.error("OpenAI request failed code:[{}] body:[{}]", response.code, StringUtils.truncate(body, 512))
		return StringUtils.EMPTY
	var chat_response: OpenAiResponse = JsonUtils.json_to_object(body, OpenAiResponse)
	if chat_response == null or chat_response.choices.is_empty():
		Log.error("OpenAI response parse failed body:[{}]", StringUtils.truncate(body, 512))
		return StringUtils.EMPTY
	var message := chat_response.choices[0].message
	if message == null or StringUtils.is_blank(message.content):
		Log.error("OpenAI response missing content body:[{}]", StringUtils.truncate(body, 512))
		return StringUtils.EMPTY
	return message.content



# ----------------------------------------------------------------------------------------------------------------------
class StreamState:
	var pending: String = ""
	var text: String = ""

	func append_delta(delta: String, on_delta: Callable = Callable()) -> void:
		text += delta
		if on_delta.is_valid():
			on_delta.call(delta)
		pass

## Streams assistant text via SSE. Optional on_delta receives each content fragment; returns full text.
static func async_chat_messages_stream(messages: Array[ChatMessage], on_delta: Callable = Callable()) -> String:
	if not validate_messages(messages):
		return StringUtils.EMPTY
	var state := StreamState.new()
	var request := OpenAiRequest.new(model, messages, true)
	var on_chunk := func(chunk: PackedByteArray) -> void:
		state.pending = consume_sse_buffer(state.pending + chunk.get_string_from_utf8(), state, on_delta)
		pass
	var response := await HttpHelper.async_post(base_url, JsonUtils.object_to_json(request), build_headers(true), AsyncHttp.DEFAULT_TIMEOUT_MILLIS, "", on_chunk)
	finish_sse_parse(state, on_delta, response.get_body_string())
	if not response.success or response.code != 200:
		Log.error("OpenAI stream failed code:[{}] body:[{}]", response.code, StringUtils.truncate(response.get_body_string(), 512))
		return StringUtils.EMPTY
	if StringUtils.is_blank(state.text):
		Log.error("OpenAI stream empty code:[{}] body:[{}]", response.code, StringUtils.truncate(response.get_body_string(), 512))
		return StringUtils.EMPTY
	return state.text


static func finish_sse_parse(state: StreamState, on_delta: Callable, body: String) -> void:
	if not state.pending.is_empty():
		state.pending = consume_sse_buffer(state.pending + "\n", state, on_delta)
	if StringUtils.is_blank(state.text) and StringUtils.is_not_blank(body):
		consume_sse_buffer(body, state, on_delta)
	pass


static func consume_sse_buffer(buffer: String, state: StreamState, on_delta: Callable = Callable()) -> String:
	if buffer.is_empty():
		return StringUtils.EMPTY
	var lines: PackedStringArray = buffer.split("\n", false)
	var remaining := StringUtils.EMPTY
	if not buffer.ends_with("\n"):
		remaining = lines[lines.size() - 1]
		lines = lines.slice(0, lines.size() - 1)
	for line: String in lines:
		line = line.strip_edges()
		if line.is_empty() or not line.begins_with("data:"):
			continue
		var payload := StringUtils.substring_after(line, "data:").strip_edges()
		if payload.to_upper() == "[DONE]":
			continue
		var delta := extract_stream_delta(payload)
		if StringUtils.is_not_empty(delta):
			state.append_delta(delta, on_delta)
	return remaining


static func extract_stream_delta(json_line: String) -> String:
	var chunk: OpenAiStreamChunk = JsonUtils.json_to_object(json_line, OpenAiStreamChunk)
	if chunk == null or chunk.choices.is_empty():
		return StringUtils.EMPTY
	var delta := chunk.choices[0].delta
	if delta == null:
		return StringUtils.EMPTY
	if StringUtils.is_not_empty(delta.content):
		return delta.content
	if StringUtils.is_not_empty(delta.reasoning_content):
		return delta.reasoning_content
	return StringUtils.EMPTY
