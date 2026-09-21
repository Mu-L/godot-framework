class_name NumberUtils
extends Object

const INT32_MAX: int = 0x7fffffff
const INT32_MIN: int = -0x80000000
const INT64_MAX: int = 0x7fffffffffffffff
const INT64_MIN: int = -0x8000000000000000

# int64 bounds as float, float holds -2^63 but not 2^63 - 1, so the max bound is exclusive
const INT64_MIN_FLOAT: float = -9223372036854775808.0
const INT64_MAX_FLOAT: float = 9223372036854775808.0

const INT64_MAX_TEXT := "9223372036854775807"
const INT64_MIN_TEXT := "9223372036854775808"

const TRUE_TOKENS: PackedStringArray = ["true", "1", "yes", "y", "on"]


## Accepts bool, any non zero number, and text like "true" / "1" / "yes" / "y" / "on".
static func parse_bool(raw: Variant) -> bool:
	if typeof(raw) == TYPE_BOOL:
		return bool(raw)
	if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
		return raw != 0
	return TRUE_TOKENS.has(str(raw).strip_edges().to_lower())


## Accepts bool, int, whole float and int text. Empty, malformed and out of int64 range values return default_value.
static func parse_int(raw: Variant, default_value: int) -> int:
	if typeof(raw) == TYPE_INT:
		return int(raw)
	if typeof(raw) == TYPE_BOOL:
		return 1 if raw else 0
	if typeof(raw) == TYPE_FLOAT:
		var number := float(raw)
		if not is_finite(number) or number != floor(number) or number < INT64_MIN_FLOAT or number >= INT64_MAX_FLOAT:
			return default_value
		return int(number)
	var text := str(raw).strip_edges()
	if not text.is_valid_int() or not is_int64_text(text):
		return default_value
	return int(text)


## Accepts bool, int, float and float text. Malformed and infinite / NaN values return default_value.
static func parse_float(raw: Variant, default_value: float) -> float:
	if typeof(raw) == TYPE_FLOAT:
		var number := float(raw)
		return number if is_finite(number) else default_value
	if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_BOOL:
		return float(raw)
	var text := str(raw).strip_edges()
	if not text.is_valid_float():
		return default_value
	var number := float(text)
	return number if is_finite(number) else default_value


# String.to_int silently clamps text outside int64 like "99999999999999999999"
static func is_int64_text(text: String) -> bool:
	var negative := text.begins_with("-")
	var digits := text.trim_prefix("-").trim_prefix("+").lstrip("0")
	if digits.is_empty():
		return true
	var limit := INT64_MIN_TEXT if negative else INT64_MAX_TEXT
	return digits.length() < limit.length() or (digits.length() == limit.length() and digits <= limit)
