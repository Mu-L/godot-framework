class_name Utf8StreamDecoder
extends RefCounted

## Incrementally decodes UTF-8 from byte chunks and replaces malformed input with U+FFFD.

const REPLACEMENT_CHARACTER := "�"

var pending: PackedByteArray = PackedByteArray()


func push(chunk: PackedByteArray) -> String:
	if chunk.is_empty():
		return StringUtils.EMPTY
	pending.append_array(chunk)
	return decode_complete()


func flush() -> String:
	if pending.is_empty():
		return StringUtils.EMPTY
	var text := decode_complete()
	if not pending.is_empty():
		text += REPLACEMENT_CHARACTER
	pending.clear()
	return text


func clear() -> void:
	pending.clear()
	pass


static func is_valid_utf8(data: PackedByteArray) -> bool:
	var i := 0
	while i < data.size():
		var seq_len := leading_byte_length(data[i])
		if seq_len == 0:
			return false
		if i + seq_len > data.size():
			return false
		for j in range(1, seq_len):
			if (data[i + j] & 0xC0) != 0x80:
				return false
		if seq_len > 1 and not is_valid_second_byte(data[i], data[i + 1]):
			return false
		i += seq_len
	return true


static func leading_byte_length(b: int) -> int:
	if b < 0x80:
		return 1
	if b >= 0xC2 and b <= 0xDF:
		return 2
	if b >= 0xE0 and b <= 0xEF:
		return 3
	if b >= 0xF0 and b <= 0xF4:
		return 4
	return 0


static func is_valid_second_byte(leading: int, second: int) -> bool:
	if leading == 0xE0:
		return second >= 0xA0 and second <= 0xBF
	if leading == 0xED:
		return second >= 0x80 and second <= 0x9F
	if leading == 0xF0:
		return second >= 0x90 and second <= 0xBF
	if leading == 0xF4:
		return second >= 0x80 and second <= 0x8F
	return (second & 0xC0) == 0x80


func decode_complete() -> String:
	var out := StringBuilder.new()
	var i := 0
	while i < pending.size():
		var b: int = pending[i]
		var seq_len := leading_byte_length(b)
		if seq_len == 0:
			out.append(REPLACEMENT_CHARACTER)
			i += 1
			continue
		var valid := true
		var available_len := mini(seq_len, pending.size() - i)
		for j in range(1, available_len):
			if (pending[i + j] & 0xC0) != 0x80:
				valid = false
				break
		if valid and available_len > 1:
			valid = is_valid_second_byte(b, pending[i + 1])
		if not valid:
			out.append(REPLACEMENT_CHARACTER)
			i += 1
			continue
		if available_len < seq_len:
			break
		out.append(pending.slice(i, i + seq_len).get_string_from_utf8())
		i += seq_len
	if i > 0:
		pending = pending.slice(i)
	return out.build_string()
