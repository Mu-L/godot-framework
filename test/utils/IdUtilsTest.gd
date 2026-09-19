# --------------------------------------------------------------------------------------------------
func local_id_test() -> void:
	var localId := IdUtils.local_id()
	assert(IdUtils.local_id() == localId + 1)
	pass


func uuid_test() -> void:
	var uniqueIds: Dictionary = {}
	var previous := 0
	var uuid := 0
	for i in 1000:
		uuid = IdUtils.uuid()
		assert(uuid > previous)
		assert(!uniqueIds.has(uuid))
		uniqueIds[uuid] = true
		previous = uuid
	# The timestamp stored in the id must be close to the wall clock.
	var idTimestamp := (uuid >> IdUtils.UUID_TIMESTAMP_SHIFT) + IdUtils.UUID_EPOCH
	assert(absi(idTimestamp - TimeUtils.current_time_millis()) <= 1000)
	# The worker id is stable inside one process.
	var workerId := (uuid >> IdUtils.UUID_WORKER_ID_SHIFT) & IdUtils.UUID_MAX_WORKER_ID
	assert(workerId == (IdUtils.uuid() >> IdUtils.UUID_WORKER_ID_SHIFT) & IdUtils.UUID_MAX_WORKER_ID)
	pass


# White-box test of the sequence overflow: the generator must borrow the next millisecond instead of
# spinning until the wall clock catches up, otherwise every overflowing call blocks all threads for 1 ms.
func uuid_sequence_overflow_test() -> void:
	var count := 200
	var start := Time.get_ticks_usec()
	var previous := 0
	var uniqueIds: Dictionary = {}
	for i in count:
		# Force the sequence to the end of its millisecond on every call.
		IdUtils._sequence = IdUtils.UUID_MAX_SEQUENCE
		var uuid := IdUtils.uuid()
		assert(uuid > previous)
		assert(!uniqueIds.has(uuid))
		uniqueIds[uuid] = true
		previous = uuid
	# The old spin implementation needed count ms, the borrow needs about 1 us per call.
	assert(Time.get_ticks_usec() - start < count * 250)
	pass


func small_uuid_test() -> void:
	var uniqueIds: Dictionary = {}
	var previous := -1
	var id := 0
	for i in 2000:
		id = IdUtils.small_uuid()
		assert(id >= 0 and id <= NumberUtils.INT32_MAX)
		assert(id > previous)
		assert(!uniqueIds.has(id))
		uniqueIds[id] = true
		previous = id
	# 21 bits second + 10 bits sequence uses at most 31 bits.
	var second: int = (id >> IdUtils.SMALL_SEQUENCE_BITS) & IdUtils.SMALL_MAX_SECOND
	assert(second <= IdUtils.SMALL_MAX_SECOND)
	assert(id == (second << IdUtils.SMALL_SEQUENCE_BITS) | (id & IdUtils.SMALL_MAX_SEQUENCE))
	pass


# The small id must borrow the next second instead of spinning, and stay inside int32 even when the
# 21 bit second counter wraps.
func small_uuid_sequence_overflow_test() -> void:
	var count := 200
	var start := Time.get_ticks_usec()
	var uniqueIds: Dictionary = {}
	var previous := -1
	for i in count:
		# Force the sequence to the end of its second on every call.
		IdUtils._small_sequence = IdUtils.SMALL_MAX_SEQUENCE
		var id := IdUtils.small_uuid()
		assert(id >= 0 and id <= NumberUtils.INT32_MAX)
		assert(id > previous)
		assert(!uniqueIds.has(id))
		uniqueIds[id] = true
		previous = id
	assert(Time.get_ticks_usec() - start < count * 250)

	# The packed layout must fill exactly the positive int32 range, so no combination can overflow it.
	assert((IdUtils.SMALL_MAX_SECOND << IdUtils.SMALL_SEQUENCE_BITS) | IdUtils.SMALL_MAX_SEQUENCE == NumberUtils.INT32_MAX)
	pass
