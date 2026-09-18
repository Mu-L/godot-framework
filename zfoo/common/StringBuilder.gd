class_name StringBuilder
extends RefCounted

## Mutable string buffer. Collects fragments in a PackedStringArray and joins once in build_string().

var parts: PackedStringArray = PackedStringArray()


func _init(items: Array[String] = []) -> void:
	append_all(items)
	pass


## Appends every string in [param items]. Returns self for chaining.
func append_all(items: Array[String]) -> StringBuilder:
	for item: String in items:
		parts.append(item)
	return self


## Appends text. Returns self for chaining.
func append(text: String) -> StringBuilder:
	parts.append(text)
	return self


## Appends text only when not empty. Returns self for chaining.
func append_if_not_empty(text: String) -> StringBuilder:
	if StringUtils.is_not_empty(text):
		parts.append(text)
	return self


## Appends text followed by a newline. Returns self for chaining.
func append_line(text: String = "") -> StringBuilder:
	parts.append(text + FileUtils.NEWLINE_LF)
	return self


## Clears all buffered fragments.
func clear() -> void:
	parts.clear()
	pass


## Returns true when no fragments have been appended.
func is_empty() -> bool:
	return parts.is_empty()


## Returns the number of buffered fragments.
func size() -> int:
	return parts.size()


## Returns the total character count across all fragments.
func length() -> int:
	var total := 0
	for part: String in parts:
		total += part.length()
	return total


## Joins buffered fragments into one string.
func build_string() -> String:
	return "".join(parts)


## Joins buffered fragments with a separator.
func build_joined(separator: String) -> String:
	return separator.join(parts)


## Drops trailing parts when [method build_string] exceeds [param max_length].
## Returns true when any part was removed or shortened.
## If the first part alone exceeds [param max_length], it is shortened with [method StringUtils.truncate].
func truncate_by_part(max_length: int) -> bool:
	if parts.is_empty():
		return false
	if max_length <= 0:
		parts.clear()
		return true
	var total := length()
	if total <= max_length:
		return false
	var end := parts.size()
	var running := total
	while end > 1 and running > max_length:
		end -= 1
		running -= parts[end].length()
	if end == 1 and parts[0].length() > max_length:
		parts = PackedStringArray([StringUtils.truncate(parts[0], max_length)])
		return true
	parts = parts.slice(0, end)
	return true
