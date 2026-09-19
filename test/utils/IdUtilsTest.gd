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
