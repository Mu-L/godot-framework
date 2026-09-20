func consume_sse_buffer_tools_test() -> void:
	var tool_calls_acc: Array[OpenAiToolCall] = []
	var deltas: Array[String] = []
	var on_delta := func(delta: String, stream_kind: String) -> void:
		deltas.append(delta)
		pass
	var remainder := OpenAiClient.consume_sse_buffer_tools(
		"data: {\"choices\":[{\"delta\":{\"content\":\"Hel\"}}]}\n\ndata: {\"choices\":[{\"delta\":{\"content\":\"lo\"}}]}\n",
		tool_calls_acc,
		on_delta
	)
	assert(deltas == ["Hel", "lo"])
	assert(remainder == StringUtils.EMPTY)
	pass


func consume_sse_buffer_tools_partial_line_test() -> void:
	var tool_calls_acc: Array[OpenAiToolCall] = []
	var deltas: Array[String] = []
	var on_delta := func(delta: String, stream_kind: String) -> void:
		deltas.append(delta)
		pass
	var remainder := OpenAiClient.consume_sse_buffer_tools(
		"data: {\"choices\":[{\"delta\":{\"content\":\"Hi\"}}]}",
		tool_calls_acc,
		on_delta
	)
	assert(deltas.is_empty())
	assert(remainder.begins_with("data:"))
	var remainder2 := OpenAiClient.consume_sse_buffer_tools(remainder + "\n", tool_calls_acc, on_delta)
	assert(deltas == ["Hi"])
	assert(remainder2 == StringUtils.EMPTY)
	pass


func consume_sse_buffer_tools_on_delta_test() -> void:
	var tool_calls_acc: Array[OpenAiToolCall] = []
	var deltas := StringBuilder.new()
	var on_delta := func(delta: String, stream_kind: String) -> void:
		deltas.append_if_not_empty(delta)
		pass
	OpenAiClient.consume_sse_buffer_tools(
		"data: {\"choices\":[{\"delta\":{\"content\":\"Hel\"}}]}\n\ndata: {\"choices\":[{\"delta\":{\"content\":\"lo\"}}]}\n",
		tool_calls_acc,
		on_delta
	)
	assert(deltas.build_string() == "Hello")
	pass


func consume_sse_buffer_tools_reasoning_one_arg_on_delta_test() -> void:
	var tool_calls_acc: Array[OpenAiToolCall] = []
	var deltas: Array[String] = []
	var on_delta := func(delta: String) -> void:
		deltas.append(delta)
		pass
	OpenAiClient.consume_sse_buffer_tools(
		"data: {\"choices\":[{\"delta\":{\"reasoning_content\":\"think\"}}]}\n"
		+ "data: {\"choices\":[{\"delta\":{\"content\":\"OK\"}}]}\n",
		tool_calls_acc,
		on_delta
	)
	assert(deltas.size() == 1)
	assert(deltas[0] == "OK")
	pass


func consume_sse_buffer_tools_reasoning_on_delta_test() -> void:
	var tool_calls_acc: Array[OpenAiToolCall] = []
	var kinds: Array[String] = []
	var on_delta := func(delta: String, stream_kind: String) -> void:
		kinds.append(stream_kind)
		pass
	OpenAiClient.consume_sse_buffer_tools(
		"data: {\"choices\":[{\"delta\":{\"reasoning_content\":\"think\"}}]}\n"
		+ "data: {\"choices\":[{\"delta\":{\"content\":\"OK\"}}]}\n",
		tool_calls_acc,
		on_delta
	)
	assert(kinds.size() == 2)
	assert(kinds[0] == OpenAiClient.STREAM_KIND_REASONING)
	assert(kinds[1] == OpenAiClient.STREAM_KIND_CONTENT)
	pass


func extract_finish_reason_test() -> void:
	var body := "data: {\"choices\":[{\"delta\":{\"content\":\"OK\"}}]}\n\ndata: {\"choices\":[{\"index\":0,\"delta\":{},\"finish_reason\":\"stop\"}]}\n"
	assert(OpenAiClient.extract_finish_reason(OpenAiClient.parse_stream_chunks(body)) == "stop")
	pass


func consume_sse_buffer_tools_multichunk_test() -> void:
	var pending_build := StringBuilder.new()
	var deltas: Array[String] = []
	var tool_calls_acc: Array[OpenAiToolCall] = []
	var on_delta := func(delta: String, stream_kind: String) -> void:
		deltas.append(delta)
		pass
	var append_chunk := func(chunk_text: String) -> void:
		var buffer := pending_build.build_string() + chunk_text
		pending_build.clear()
		var remaining := OpenAiClient.consume_sse_buffer_tools(buffer, tool_calls_acc, on_delta)
		if StringUtils.is_not_empty(remaining):
			pending_build.append_if_not_empty(remaining)
		pass
	append_chunk.call("data: {\"choices\":[{\"delta\":{\"content\":\"Hel")
	append_chunk.call("lo\"}}]}\n\ndata: {\"choices\":[{\"delta\":{\"content\":\"!\"}}]}\n")
	assert(deltas == ["Hello", "!"])
	pass


func consume_sse_buffer_tools_tool_calls_test() -> void:
	var deltas: Array[String] = []
	var on_delta := func(delta: String, stream_kind: String) -> void:
		deltas.append(delta)
		pass
	var tool_calls_acc: Array[OpenAiToolCall] = []
	OpenAiClient.consume_sse_buffer_tools(
		"data: {\"choices\":[{\"delta\":{\"tool_calls\":[{\"index\":0,\"id\":\"call_1\",\"type\":\"function\",\"function\":{\"name\":\"read\",\"arguments\":\"\"}}]}}]}\n"
		+ "data: {\"choices\":[{\"delta\":{\"tool_calls\":[{\"index\":0,\"function\":{\"arguments\":\"{\\\"path\\\":\\\"a.txt\\\"}\"}}]}}]}\n",
		tool_calls_acc,
		on_delta
	)
	assert(deltas.is_empty())
	assert(tool_calls_acc.size() == 1)
	assert(tool_calls_acc[0].id == "call_1")
	assert(tool_calls_acc[0].function.name == "read")
	assert(tool_calls_acc[0].function.arguments == "{\"path\":\"a.txt\"}")
	pass


func build_request_json_test() -> void:
	var messages: Array[ChatMessage] = []
	messages.append(ChatMessage.user("hello"))
	var request := OpenAiRequest.new("test-model", messages, true)
	request.max_tokens = 8192
	var tool := OpenAiToolDef.new()
	tool.function.name = "read"
	tool.function.description = "Read a file"
	tool.function.parameters.string_prop("path", "File path", true)
	request.tools.append(tool)
	var json := OpenAiClient.build_request_json(request)
	assert(json.contains("\"model\": \"test-model\""))
	assert(json.contains("\"stream\": true"))
	assert(json.contains("\"max_tokens\": 8192"))
	assert(json.contains("\"content\": \"hello\""))
	assert(json.contains("\"name\": \"read\""))
	pass


func extract_stream_usage_test() -> void:
	var body := (
		"data: {\"choices\":[{\"delta\":{\"content\":\"OK\"}}]}\n\n"
		+ "data: {\"choices\":[{\"index\":0,\"delta\":{},\"finish_reason\":\"stop\"}],"
		+ "\"usage\":{\"prompt_tokens\":12,\"completion_tokens\":5,\"total_tokens\":17}}\n"
	)
	var usage := OpenAiClient.extract_stream_usage(OpenAiClient.parse_stream_chunks(body))
	assert(usage.total_tokens == 17)
	assert(usage.prompt_tokens == 12)
	assert(usage.completion_tokens == 5)
	pass


func collect_stream_text_test() -> void:
	var body := (
		"data: {\"choices\":[{\"delta\":{\"reasoning_content\":\"thin\"}}]}\n\n"
		+ "data: {\"choices\":[{\"delta\":{\"reasoning_content\":\"king\"}}]}\n\n"
		+ "data: {\"choices\":[{\"delta\":{\"content\":\"Hel\"}}]}\n\n"
		+ "data: {\"choices\":[{\"delta\":{\"content\":\"lo\"}}]}\n\n"
		+ "data: [DONE]\n"
	)
	var chunks := OpenAiClient.parse_stream_chunks(body)
	assert(chunks.size() == 4)
	assert(OpenAiClient.extract_stream_content(chunks, OpenAiClient.STREAM_KIND_CONTENT) == "Hello")
	assert(OpenAiClient.extract_stream_content(chunks, OpenAiClient.STREAM_KIND_REASONING) == "thinking")
	pass


func parse_stream_chunks_skips_blank_body_test() -> void:
	assert(OpenAiClient.parse_stream_chunks(StringUtils.EMPTY).is_empty())
	pass


func build_request_json_escapes_control_characters_test() -> void:
	var messages: Array[ChatMessage] = []
	messages.append(ChatMessage.tool_result("call_1", "ansi" + char(0x1B) + "[0m"))
	var request := OpenAiRequest.new("test-model", messages, true)
	var json := OpenAiClient.build_request_json(request)
	assert(JSON.parse_string(json) != null)
	assert(json.contains("\\u001b"))
	assert(not json.contains(char(0x1B)))
	pass


func chat_message_tool_calls_reasoning_roundtrip_test() -> void:
	var tool_call := OpenAiToolCall.new()
	tool_call.id = "call_1"
	tool_call.function.name = "read"
	var message := ChatMessage.assistant_tool_calls([tool_call], "", "thinking")
	assert(message.reasoning_content == "thinking")
	assert(message.to_api_dict()["reasoning_content"] == "thinking")
	pass


func chat_message_tool_calls_blank_reasoning_omitted_test() -> void:
	var tool_call := OpenAiToolCall.new()
	tool_call.id = "call_1"
	tool_call.function.name = "read"
	var message := ChatMessage.assistant_tool_calls([tool_call], "")
	assert(not message.to_api_dict().has("reasoning_content"))
	pass


func chat_message_plain_assistant_omits_reasoning_test() -> void:
	var message := ChatMessage.assistant("done")
	message.reasoning_content = "thinking"
	assert(not message.to_api_dict().has("reasoning_content"))
	pass


func build_request_json_tool_calls_reasoning_test() -> void:
	var tool_call := OpenAiToolCall.new()
	tool_call.id = "call_1"
	tool_call.function.name = "read"
	var messages: Array[ChatMessage] = []
	messages.append(ChatMessage.user("hi"))
	messages.append(ChatMessage.assistant_tool_calls([tool_call], "", "thinking"))
	messages.append(ChatMessage.tool_result("call_1", "ok"))
	var json := OpenAiClient.build_request_json(OpenAiRequest.new("test-model", messages, true))
	var parsed: Dictionary = JSON.parse_string(json)
	var wire_messages: Array = parsed["messages"]
	assert(wire_messages[1]["reasoning_content"] == "thinking")
	assert(wire_messages[1]["tool_calls"].size() == 1)
	assert(not wire_messages[2].has("reasoning_content"))
	pass
