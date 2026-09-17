
func StringBuilder_from_array_test() -> void:
	var builder := StringBuilder.new(["a", "b", "c"])
	assert(builder.build_joined(", ") == "a, b, c")
	pass


func StringBuilder_append_all_test() -> void:
	var builder := StringBuilder.new()
	builder.append("x").append_all(["y", "z"])
	assert(builder.build_string() == "xyz")
	pass


func StringBuilder_append_test() -> void:
	var builder := StringBuilder.new()
	builder.append("Hel").append("lo")
	assert(builder.build_string() == "Hello")
	pass


func StringBuilder_append_line_test() -> void:
	var builder := StringBuilder.new()
	builder.append_line("a").append_line("b")
	assert(builder.build_string() == "a\nb\n")
	pass


func StringBuilder_clear_test() -> void:
	var builder := StringBuilder.new()
	builder.append("x")
	builder.clear()
	assert(builder.is_empty())
	assert(builder.length() == 0)
	assert(builder.build_string() == StringUtils.EMPTY)
	pass


func StringBuilder_length_test() -> void:
	var builder := StringBuilder.new()
	builder.append("ab").append("cde")
	assert(builder.size() == 2)
	assert(builder.length() == 5)
	pass


func StringBuilder_build_joined_test() -> void:
	var builder := StringBuilder.new()
	builder.append("a").append("b").append("c")
	assert(builder.build_joined(", ") == "a, b, c")
	pass


func StringBuilder_append_empty_test() -> void:
	var builder := StringBuilder.new()
	builder.append("").append("x")
	assert(builder.size() == 2)
	assert(builder.build_string() == "x")
	pass


func StringBuilder_append_if_not_empty_test() -> void:
	var builder := StringBuilder.new()
	builder.append_if_not_empty("").append_if_not_empty("x")
	assert(builder.size() == 1)
	assert(builder.build_string() == "x")
	pass


func StringBuilder_truncate_by_line_test() -> void:
	var builder := StringBuilder.new()
	builder.append_line("aaa").append_line("bbb").append_line("ccc")
	assert(builder.truncate_by_line(8))
	assert(builder.size() == 2)
	assert(builder.build_string() == "aaa\nbbb\n")
	assert(builder.length() == 8)

	builder = StringBuilder.new()
	builder.append_line("aaa").append_line("bbb").append_line("ccc")
	assert(builder.truncate_by_line(100) == false)
	assert(builder.size() == 3)
	assert(builder.build_string() == "aaa\nbbb\nccc\n")

	builder = StringBuilder.new(["0123456789"])
	assert(builder.truncate_by_line(5))
	assert(builder.size() == 1)
	assert(builder.build_string() == "01...")

	builder = StringBuilder.new()
	builder.append_line("keep-me").append_line("drop-me")
	assert(builder.truncate_by_line(0))
	assert(builder.is_empty())

	builder = StringBuilder.new()
	assert(builder.truncate_by_line(999) == false)
	assert(builder.is_empty())

	builder = StringBuilder.new()
	builder.append_line("12").append_line("34")
	assert(builder.truncate_by_line(6) == false)
	assert(builder.size() == 2)
	assert(builder.build_string() == "12\n34\n")

	builder = StringBuilder.new()
	builder.append_line("12").append_line("34")
	assert(builder.truncate_by_line(5))
	assert(builder.size() == 1)
	assert(builder.build_string() == "12\n")
	assert(builder.length() <= 5)

	builder = StringBuilder.new()
	for i in 10:
		builder.append_line("row-%02d-end" % i)
	assert(builder.truncate_by_line(35))
	assert(builder.size() == 3)
	assert(
		builder.build_string()
		== "row-00-end\nrow-01-end\nrow-02-end\n"
	)
	assert(builder.length() == 33)

	builder = StringBuilder.new()
	builder.append_line("grep: agent/A.gd:10:short hit")
	builder.append_line("grep: agent/B.gd:200:another match on this line")
	builder.append_line("grep: zfoo/common/StringBuilder.gd:88:func truncate_by_line(max_length: int)")
	builder.append_line("... (truncated at 500 entries)")
	assert(builder.truncate_by_line(100))
	assert(builder.size() == 2)
	assert(builder.build_string().contains("agent/A.gd"))
	assert(builder.build_string().contains("agent/B.gd"))
	assert(builder.build_string().contains("StringBuilder.gd") == false)
	assert(builder.length() <= 100)

	builder = StringBuilder.new()
	for i in 6:
		builder.append_line("block-%d-padding" % i)
	assert(builder.truncate_by_line(80))
	var size_after_first := builder.size()
	assert(builder.truncate_by_line(35))
	assert(builder.size() <= size_after_first)
	assert(builder.length() <= 35)

	builder = StringBuilder.new()
	builder.append("frag-A-xxxxx").append("frag-B-xxxxx").append("frag-C-xxxxx")
	assert(builder.truncate_by_line(24))
	assert(builder.size() == 2)
	assert(builder.build_string() == "frag-A-xxxxxfrag-B-xxxxx")
	assert(builder.length() == 24)

	builder = StringBuilder.new()
	builder.append_line("only-line-is-very-long-for-truncate-by-line-test-case")
	assert(builder.truncate_by_line(20))
	assert(builder.size() == 1)
	assert(builder.build_string() == "only-line-is-very...")
	assert(builder.length() == 20)

	builder = StringBuilder.new()
	builder.append_line("aaa").append_line("bbb").append_line("ccc")
	assert(builder.truncate_by_line(100) == false)
	assert(builder.truncate_by_line(100) == false)
	pass
