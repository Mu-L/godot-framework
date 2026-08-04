class_name StringUtils
extends Object

const EMPTY: String = ""
const EMPTY_ARRAY: PackedStringArray = PackedStringArray()
const EMPTY_JSON: String = "{}"

const SPACE: String = " "
const SPACE_REGEX: String = "\\s+"

const TAB: String = "    "
const TAB_ASCII: String = "\t"

const COMMA: String = "," # [com·ma || 'kɒmə] n. comma
const COMMA_REGEX: String = ",|，"
const COMMON_SPLIT_REGEX: String = "[,，\\s]+"

const PERIOD: String = "." # period
const PERIOD_REGEX: String = "\\."

const LEFT_SQUARE_BRACKET: String = "[" # left square bracket
const RIGHT_SQUARE_BRACKET: String = "]" # right square bracket

const COLON: String = ":" # colon [co·lon || 'kəʊlən]
const COLON_REGEX: String = ":|："

const SEMICOLON: String = ";" # semicolon ['semi'kәulәn]
const SEMICOLON_REGEX: String = ";|；"

const QUOTATION_MARK: String = "\"" # quotation mark [quo·ta·tion || kwəʊ'teɪʃn]
const ELLIPSIS: String = "..." # ellipsis
const EXCLAMATION_POINT: String = "!" # exclamation point
const DASH: String = "-" # dash
const QUESTION_MARK: String = "?" # question mark
const HYPHEN: String = "-" # hyphen, the difference from DASH is that hyphen has no spaces on either side
const SLASH: String = "/" # slash
const EQUAL: String = "=" # equal sign
const BACK_SLASH: String = "\\" # back slash

const VERTICAL_BAR: String = "|" # vertical bar
const VERTICAL_BAR_REGEX: String = "\\|"

const SHARP: String = "#"
const SHARP_REGEX: String = "\\#"

const DOLLAR: String = "$" # dollar sign

const LS: String = "\n"

# Checks if a String is empty ("") or null
static func is_empty(s: String) -> bool:
	return s == null or s.length() == 0

static func is_not_empty(s: String) -> bool:
	return !is_empty(s)

static func is_blank(s: String) -> bool:
	if is_empty(s):
		return true
	
	if is_empty(s.strip_edges(true, true)):
		return true
		
	return false

static func is_not_blank(s: String) -> bool:
	return !is_blank(s)

static func format(template: String, ...args: Array) -> String:
	if is_empty(template):
		return template
	if (ArrayUtils.is_empty(args)):
		return template
	return template.format(args, EMPTY_JSON)

static func substring_before(s: String, delimiter: String) -> String:
	if is_empty(s):
		return EMPTY
	var index := s.find(delimiter)
	if index == -1:
		return EMPTY
	return s.substr(0, index)

static func substring_after(s: String, delimiter: String) -> String:
	if is_empty(s):
		return EMPTY
	var index := s.find(delimiter)
	if index == -1:
		return EMPTY
	return s.substr(index + delimiter.length(), s.length())

static func substring_before_last(s: String, delimiter: String) -> String:
	if is_empty(s):
		return EMPTY
	var index := s.rfind(delimiter)
	if index == -1:
		return EMPTY
	return s.substr(0, index)

static func substring_after_last(s: String, delimiter: String) -> String:
	if is_empty(s):
		return EMPTY
	var index := s.rfind(delimiter)
	if index == -1:
		return EMPTY
	return s.substr(index + delimiter.length(), s.length())


static func enum_to_string(enum_obj: Dictionary, value: int) -> String:
	for key in enum_obj.keys():
		if enum_obj[key] == value:
			return key
	return "UNKNOWN"

# ----------------------------------------------------------------------------------------------------------------------
const ANIMAL_EMOJIS: PackedStringArray = [
	"🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐻‍","🐨","🐯","🦁","🐮","🐷","🐽","🐸","🐵","🙈","🙉","🙊",
	"🐒","🐔","🐧","🐦","🐤","🐣","🐥","🦆","🦅","🦉","🦇","🐺","🐗","🐴","🦄","🐝","🐛","🦋","🐌","🐞",
	"🕷️","🦂","🦟","🦀","🦞","🦐","🦑","🐙","🐡","🐠","🐟","🐬","🐳","🐋","🦈","🐊","🐅","🐆","🦓","🦍",
	"🦧","🐘","🦛","🦏","🐪","🐫","🦒","🦘","🐃","🐂","🐄","🐎","🐖","🐏","🐑","🦙","🐐","🦌","🐕","🐩",
	"🦮","🐕‍🦺","🐈","🐓","🦃","🦚","🦜","🦢","🦩","🕊️","🐇","🦝","🦨","🦡","🦦","🦥","🐁","🐀","🐿️","🦔",
	"🐉","🐲"]

# random emoji
static func random_emoji() -> String:
	# emoji Unicode range
	var ranges := [
		[0x1F600, 0x1F64F], # emoj
		[0x1F300, 0x1F5FF], # other
		[0x1F680, 0x1F6FF], # traffic
		[0x1F900, 0x1F9FF], # emoj
	]

	var r = ranges.pick_random()

	var codepoint := randi_range(r[0], r[1])

	var emoji := char(codepoint)

	if StringUtils.is_blank(emoji):
		return emoji
	
	return RandomUtils.random_ele(ANIMAL_EMOJIS)