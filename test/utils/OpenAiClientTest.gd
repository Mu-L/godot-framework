func consume_sse_buffer_test() -> void:
	var state := OpenAiClient.StreamState.new()
	var remainder := OpenAiClient.consume_sse_buffer(
		"data: {\"choices\":[{\"delta\":{\"content\":\"Hel\"}}]}\n\ndata: {\"choices\":[{\"delta\":{\"content\":\"lo\"}}]}\n",
		state
	)
	assert(state.text == "Hello")
	assert(remainder == StringUtils.EMPTY)
	pass


func consume_sse_buffer_partial_line_test() -> void:
	var state := OpenAiClient.StreamState.new()
	var remainder := OpenAiClient.consume_sse_buffer("data: {\"choices\":[{\"delta\":{\"content\":\"Hi\"}}]}", state)
	assert(state.text.is_empty())
	assert(remainder.begins_with("data:"))
	var remainder2 := OpenAiClient.consume_sse_buffer(remainder + "\n", state)
	assert(state.text == "Hi")
	assert(remainder2 == StringUtils.EMPTY)
	pass


func extract_stream_delta_test() -> void:
	var delta := OpenAiClient.extract_stream_delta("{\"choices\":[{\"delta\":{\"role\":\"assistant\",\"content\":\"OK\"}}]}")
	assert(delta == "OK")
	pass


func extract_stream_delta_reasoning_test() -> void:
	var delta := OpenAiClient.extract_stream_delta("{\"choices\":[{\"delta\":{\"role\":\"assistant\",\"content\":null,\"reasoning_content\":\"think\"}}]}")
	assert(delta == "think")
	pass


func extract_stream_delta_whitespace_test() -> void:
	var delta := OpenAiClient.extract_stream_delta("{\"choices\":[{\"delta\":{\"content\":\" \"}}]}")
	assert(delta == " ")
	pass


func consume_sse_buffer_multichunk_test() -> void:
	var state := OpenAiClient.StreamState.new()
	state.pending = OpenAiClient.consume_sse_buffer(state.pending + "data: {\"choices\":[{\"delta\":{\"content\":\"Hel", state)
	state.pending = OpenAiClient.consume_sse_buffer(state.pending + "lo\"}}]}\n\ndata: {\"choices\":[{\"delta\":{\"content\":\"!\"}}]}\n", state)
	assert(state.text == "Hello!")
	pass
