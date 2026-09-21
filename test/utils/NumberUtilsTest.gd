func int64_bounds_test() -> void:
	assert(NumberUtils.INT32_MAX == 2_147_483_647)
	assert(NumberUtils.INT32_MIN == -2_147_483_648)
	assert(NumberUtils.INT64_MAX == 9_223_372_036_854_775_807)
	assert(NumberUtils.INT64_MIN == -9_223_372_036_854_775_808)
	@warning_ignore("assert_always_true")
	assert(NumberUtils.INT64_MAX + 1 == NumberUtils.INT64_MIN)
	pass


func parse_bool_test() -> void:
	assert(NumberUtils.parse_bool(true))
	assert(NumberUtils.parse_bool(1))
	assert(NumberUtils.parse_bool(1.0))
	assert(NumberUtils.parse_bool(2))
	assert(NumberUtils.parse_bool(" TRUE "))
	assert(NumberUtils.parse_bool("yes"))
	assert(NumberUtils.parse_bool("Y"))
	assert(NumberUtils.parse_bool("on"))
	assert(!NumberUtils.parse_bool(false))
	assert(!NumberUtils.parse_bool(0))
	assert(!NumberUtils.parse_bool("0"))
	assert(!NumberUtils.parse_bool("off"))
	assert(!NumberUtils.parse_bool("no"))
	assert(!NumberUtils.parse_bool(""))
	assert(!NumberUtils.parse_bool(null))
	pass


func parse_int_test() -> void:
	assert(NumberUtils.parse_int(12, 0) == 12)
	assert(NumberUtils.parse_int(" 12 ", 0) == 12)
	assert(NumberUtils.parse_int("+12", 0) == 12)
	assert(NumberUtils.parse_int("-12", 0) == -12)
	assert(NumberUtils.parse_int("007", 0) == 7)
	assert(NumberUtils.parse_int(true, 0) == 1)
	assert(NumberUtils.parse_int(1.0, 0) == 1)
	assert(NumberUtils.parse_int("9223372036854775807", 0) == NumberUtils.INT64_MAX)
	assert(NumberUtils.parse_int("-9223372036854775808", 0) == NumberUtils.INT64_MIN)
	# Malformed text and non whole floats fall back to the default value.
	assert(NumberUtils.parse_int("abc", 7) == 7)
	assert(NumberUtils.parse_int("", 7) == 7)
	assert(NumberUtils.parse_int(null, 7) == 7)
	assert(NumberUtils.parse_int(1.5, 7) == 7)
	assert(NumberUtils.parse_int(1e30, 7) == 7)
	assert(NumberUtils.parse_int("99999999999999999999", 7) == 7)
	pass


# int(INF) and int(NAN) silently return INT64_MIN, the parser must fall back to the default value.
func parse_int_non_finite_test() -> void:
	assert(NumberUtils.parse_int(INF, -1) == -1)
	assert(NumberUtils.parse_int(-INF, -1) == -1)
	assert(NumberUtils.parse_int(NAN, -1) == -1)
	pass


func parse_float_test() -> void:
	assert(NumberUtils.parse_float(1.5, 0.0) == 1.5)
	assert(NumberUtils.parse_float(2, 0.0) == 2.0)
	assert(NumberUtils.parse_float(true, 0.0) == 1.0)
	assert(NumberUtils.parse_float(" 2.5 ", 0.0) == 2.5)
	assert(NumberUtils.parse_float("1e3", 0.0) == 1000.0)
	assert(NumberUtils.parse_float("abc", -1.0) == -1.0)
	assert(NumberUtils.parse_float("", -1.0) == -1.0)
	# "1e400" is valid text but overflows to INF, so it must fall back too.
	assert(NumberUtils.parse_float(1e400, -1.0) == -1.0)
	pass


func parse_float_non_finite_test() -> void:
	assert(NumberUtils.parse_float(INF, -1.0) == -1.0)
	assert(NumberUtils.parse_float(-INF, -1.0) == -1.0)
	assert(NumberUtils.parse_float(NAN, -1.0) == -1.0)
	pass
