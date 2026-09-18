
func Utf8StreamDecoder_split_multibyte_across_chunks_test() -> void:
	var text := "你好世界"
	var bytes := text.to_utf8_buffer()
	var decoder := Utf8StreamDecoder.new()
	var out := StringUtils.EMPTY
	for i in range(bytes.size()):
		out += decoder.push(bytes.slice(i, i + 1))
	assert(out == text)
	pass


func Utf8StreamDecoder_ascii_and_cjk_mixed_chunks_test() -> void:
	var decoder := Utf8StreamDecoder.new()
	var part1 := decoder.push("data: {\"content\":\"".to_utf8_buffer())
	var part2 := decoder.push("你".to_utf8_buffer().slice(0, 1))
	var part3 := decoder.push("你".to_utf8_buffer().slice(1))
	part3 += decoder.push("好\"}\n".to_utf8_buffer())
	assert(part1 + part2 + part3 == "data: {\"content\":\"你好\"}\n")
	pass


func Utf8StreamDecoder_empty_push_test() -> void:
	var decoder := Utf8StreamDecoder.new()
	assert(decoder.push(PackedByteArray()).is_empty())
	pass


func Utf8StreamDecoder_complete_chunk_test() -> void:
	var decoder := Utf8StreamDecoder.new()
	assert(decoder.push("ASCII 中文 😀".to_utf8_buffer()) == "ASCII 中文 😀")
	pass


func Utf8StreamDecoder_two_byte_character_split_test() -> void:
	var bytes := "é".to_utf8_buffer()
	var decoder := Utf8StreamDecoder.new()
	assert(decoder.push(bytes.slice(0, 1)).is_empty())
	assert(decoder.push(bytes.slice(1)) == "é")
	pass


func Utf8StreamDecoder_four_byte_character_split_test() -> void:
	var bytes := "😀".to_utf8_buffer()
	var decoder := Utf8StreamDecoder.new()
	assert(decoder.push(bytes.slice(0, 1)).is_empty())
	assert(decoder.push(bytes.slice(1, 2)).is_empty())
	assert(decoder.push(bytes.slice(2, 3)).is_empty())
	assert(decoder.push(bytes.slice(3)) == "😀")
	pass


func Utf8StreamDecoder_multiple_characters_cross_chunk_test() -> void:
	var bytes := "A你😀B".to_utf8_buffer()
	var decoder := Utf8StreamDecoder.new()
	var output := decoder.push(bytes.slice(0, 3))
	output += decoder.push(bytes.slice(3, 7))
	output += decoder.push(bytes.slice(7))
	assert(output == "A你😀B")
	pass


func Utf8StreamDecoder_clear_discards_pending_bytes_test() -> void:
	var decoder := Utf8StreamDecoder.new()
	var bytes := "你".to_utf8_buffer()
	assert(decoder.push(bytes.slice(0, 2)).is_empty())
	decoder.clear()
	assert(decoder.push("好".to_utf8_buffer()) == "好")
	pass


func Utf8StreamDecoder_every_split_position_test() -> void:
	var text := "Aé你😀Z"
	var bytes := text.to_utf8_buffer()
	for split_at in range(bytes.size() + 1):
		var decoder := Utf8StreamDecoder.new()
		var output := decoder.push(bytes.slice(0, split_at))
		output += decoder.push(bytes.slice(split_at))
		assert(output == text)
	pass


func Utf8StreamDecoder_every_chunk_size_test() -> void:
	var text := "ASCII-é-中文-😀-结束"
	var bytes := text.to_utf8_buffer()
	for chunk_size in range(1, bytes.size() + 1):
		var decoder := Utf8StreamDecoder.new()
		var output := StringUtils.EMPTY
		for start in range(0, bytes.size(), chunk_size):
			output += decoder.push(bytes.slice(start, mini(start + chunk_size, bytes.size())))
		assert(output == text)
	pass


func Utf8StreamDecoder_reuse_after_clear_test() -> void:
	var decoder := Utf8StreamDecoder.new()
	assert(decoder.push("first".to_utf8_buffer()) == "first")
	decoder.clear()
	assert(decoder.push("第二".to_utf8_buffer()) == "第二")
	assert(decoder.push("😀".to_utf8_buffer()) == "😀")
	pass
