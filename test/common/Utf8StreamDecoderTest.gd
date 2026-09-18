
func Utf8StreamDecoder_split_multibyte_across_chunks_test() -> void:
	var text := "你好世界"
	var bytes := text.to_utf8_buffer()
	var decoder := Utf8StreamDecoder.new()
	var out := StringUtils.EMPTY
	for i in range(bytes.size()):
		out += decoder.push(bytes.slice(i, i + 1))
	out += decoder.flush()
	assert(out == text)
	pass


func Utf8StreamDecoder_ascii_and_cjk_mixed_chunks_test() -> void:
	var decoder := Utf8StreamDecoder.new()
	var part1 := decoder.push("data: {\"content\":\"".to_utf8_buffer())
	var part2 := decoder.push("你".to_utf8_buffer().slice(0, 1))
	var part3 := decoder.push("你".to_utf8_buffer().slice(1))
	part3 += decoder.push("好\"}\n".to_utf8_buffer())
	part3 += decoder.flush()
	assert(part1 + part2 + part3 == "data: {\"content\":\"你好\"}\n")
	pass


func Utf8StreamDecoder_is_valid_utf8_test() -> void:
	assert(Utf8StreamDecoder.is_valid_utf8(PackedByteArray()))
	assert(Utf8StreamDecoder.is_valid_utf8("hello".to_utf8_buffer()))
	assert(Utf8StreamDecoder.is_valid_utf8("你好".to_utf8_buffer()))
	assert(not Utf8StreamDecoder.is_valid_utf8(PackedByteArray([0x1F, 0x8B])))
	assert(not Utf8StreamDecoder.is_valid_utf8(PackedByteArray([0xE4])))
	assert(not Utf8StreamDecoder.is_valid_utf8(PackedByteArray([0xFF])))
	pass


func Utf8StreamDecoder_empty_push_and_flush_test() -> void:
	var decoder := Utf8StreamDecoder.new()
	assert(decoder.push(PackedByteArray()).is_empty())
	assert(decoder.flush().is_empty())
	assert(decoder.flush().is_empty())
	pass


func Utf8StreamDecoder_complete_chunk_test() -> void:
	var decoder := Utf8StreamDecoder.new()
	assert(decoder.push("ASCII 中文 😀".to_utf8_buffer()) == "ASCII 中文 😀")
	assert(decoder.flush().is_empty())
	pass


func Utf8StreamDecoder_two_byte_character_split_test() -> void:
	var bytes := "é".to_utf8_buffer()
	var decoder := Utf8StreamDecoder.new()
	assert(decoder.push(bytes.slice(0, 1)).is_empty())
	assert(decoder.push(bytes.slice(1)) == "é")
	assert(decoder.flush().is_empty())
	pass


func Utf8StreamDecoder_four_byte_character_split_test() -> void:
	var bytes := "😀".to_utf8_buffer()
	var decoder := Utf8StreamDecoder.new()
	assert(decoder.push(bytes.slice(0, 1)).is_empty())
	assert(decoder.push(bytes.slice(1, 2)).is_empty())
	assert(decoder.push(bytes.slice(2, 3)).is_empty())
	assert(decoder.push(bytes.slice(3)) == "😀")
	assert(decoder.flush().is_empty())
	pass


func Utf8StreamDecoder_multiple_characters_cross_chunk_test() -> void:
	var bytes := "A你😀B".to_utf8_buffer()
	var decoder := Utf8StreamDecoder.new()
	var output := decoder.push(bytes.slice(0, 3))
	output += decoder.push(bytes.slice(3, 7))
	output += decoder.push(bytes.slice(7))
	output += decoder.flush()
	assert(output == "A你😀B")
	pass


func Utf8StreamDecoder_clear_discards_pending_bytes_test() -> void:
	var decoder := Utf8StreamDecoder.new()
	var bytes := "你".to_utf8_buffer()
	assert(decoder.push(bytes.slice(0, 2)).is_empty())
	decoder.clear()
	assert(decoder.push("好".to_utf8_buffer()) == "好")
	assert(decoder.flush().is_empty())
	pass


func Utf8StreamDecoder_invalid_bytes_recover_test() -> void:
	var decoder := Utf8StreamDecoder.new()
	assert(decoder.push(PackedByteArray([0xFF, 0x41])) == "A")
	assert(decoder.push(PackedByteArray([0xE4])).is_empty())
	assert(decoder.push(PackedByteArray([0x42])) == "B")
	assert(decoder.flush().is_empty())
	pass


func Utf8StreamDecoder_is_valid_utf8_boundaries_test() -> void:
	assert(Utf8StreamDecoder.is_valid_utf8("é".to_utf8_buffer()))
	assert(Utf8StreamDecoder.is_valid_utf8("😀".to_utf8_buffer()))
	assert(not Utf8StreamDecoder.is_valid_utf8(PackedByteArray([0x80])))
	assert(not Utf8StreamDecoder.is_valid_utf8(PackedByteArray([0xC2])))
	assert(not Utf8StreamDecoder.is_valid_utf8(PackedByteArray([0xE4, 0xBD])))
	assert(not Utf8StreamDecoder.is_valid_utf8(PackedByteArray([0xF0, 0x9F, 0x98])))
	assert(not Utf8StreamDecoder.is_valid_utf8(PackedByteArray([0xE4, 0x41, 0xA0])))
	pass
