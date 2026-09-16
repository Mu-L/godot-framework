class_name CharStreamUtils
extends RefCounted

## Stream text segmentation and display shortening for the orb overlay.

const MAX_SEGMENTS_PER_DRAIN := 32
const MAX_PHRASE_LEN := 64
const MIN_PHRASE_LEN := 2


static func is_delimiter(ch: String) -> bool:
	if ch == "\n" or ch == "\r":
		return true
	return (
		ch == "。" or ch == "！" or ch == "？" or ch == "!" or ch == "?"
		or ch == ";" or ch == "；" or ch == "，" or ch == "," or ch == "."
	)


static func append_and_take(buffer: StringBuilder, chunk: String, max_segments: int = MAX_SEGMENTS_PER_DRAIN) -> Array[String]:
	if not chunk.is_empty():
		buffer.append(chunk)
	var split := split_with_tail(buffer.build_string(), max_segments)
	buffer.clear()
	if not split.tail.is_empty():
		buffer.append(split.tail)
	return split.segments


static func drain_remainder(buffer: StringBuilder) -> String:
	var text := buffer.build_string().strip_edges()
	buffer.clear()
	return text


static func split_line_segments(text: String) -> Array[String]:
	var segments: Array[String] = []
	for line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n", false):
		var seg := line.strip_edges()
		if not seg.is_empty():
			segments.append(seg)
	return segments


static func split_with_tail(text: String, max_segments: int) -> Dictionary:
	var segments: Array[String] = []
	if text.is_empty():
		return {"segments": segments, "tail": ""}
	var current := ""
	var i := 0
	while i < text.length():
		var ch := text.substr(i, 1)
		current += ch
		if is_delimiter(ch):
			var seg := current.strip_edges()
			if not seg.is_empty():
				segments.append(seg)
			current = ""
			if segments.size() >= max_segments:
				i += 1
				break
		i += 1
	var tail := text.substr(i) if i < text.length() else current
	return {"segments": segments, "tail": tail}


static func truncate_at_punctuation(text: String, max_len: int) -> String:
	var phrase := text.strip_edges()
	if phrase.length() <= max_len:
		return phrase
	var cut := -1
	for i in mini(phrase.length(), max_len):
		if is_delimiter(phrase.substr(i, 1)):
			cut = i
	if cut >= MIN_PHRASE_LEN:
		return phrase.substr(0, cut).strip_edges()
	return phrase.substr(0, max_len).strip_edges() + "…"
