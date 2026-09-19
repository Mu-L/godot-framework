class_name IdUtils
extends Object

## Epoch of the uuid timestamp: 2021-01-01T00:00:00Z in milliseconds, the ids stay unique for about 69 years.
const UUID_EPOCH: int = 1609459200000

## uuid layout: 41 bits timestamp | 10 bits worker id | 12 bits sequence
##
## The timestamp is the wall clock, but when more than [constant UUID_MAX_SEQUENCE] + 1 ids are
## requested inside one millisecond the generator borrows the next millisecond instead of waiting
## for the clock, so [method uuid] never blocks and never burns CPU in a spin loop.
const UUID_SEQUENCE_BITS: int = 12
const UUID_WORKER_ID_BITS: int = 10
const UUID_MAX_WORKER_ID: int = (1 << UUID_WORKER_ID_BITS) - 1
const UUID_MAX_SEQUENCE: int = (1 << UUID_SEQUENCE_BITS) - 1
const UUID_WORKER_ID_SHIFT: int = UUID_SEQUENCE_BITS
const UUID_TIMESTAMP_SHIFT: int = UUID_SEQUENCE_BITS + UUID_WORKER_ID_BITS

static var _local_id: int = 0

## Returns an id which is unique inside the current run, it restarts from 1 after every run.
static func local_id() -> int:
	_local_id += 1
	return _local_id


static var _mutex: Mutex = Mutex.new()
static var _sequence: int = 0
static var _last_timestamp: int = 0
static var _worker_id: int = -1

## Returns a globally unique id, it increases monotonically inside one process and keeps unique
## after restarting, because the current timestamp is a part of it.
## The call never waits and never blocks another thread: once more than [constant UUID_MAX_SEQUENCE] + 1
## ids have been generated inside one millisecond, the following ones borrow the next millisecond,
## so the timestamp inside the id can lead the wall clock by a few milliseconds under a burst.
static func uuid() -> int:
	_mutex.lock()
	var timestamp: int = TimeUtils.current_time_millis()
	if timestamp > _last_timestamp:
		# A new millisecond, the sequence restarts from zero.
		_sequence = 0
	else:
		# The same millisecond, or the clock moved backwards: reuse the last timestamp to stay monotonic.
		_sequence += 1
		if _sequence > UUID_MAX_SEQUENCE:
			# The sequence of this millisecond is exhausted, borrow the next millisecond instead of
			# waiting for the clock, so the ids stay unique and no thread is blocked.
			timestamp = _last_timestamp + 1
			_sequence = 0
		else:
			timestamp = _last_timestamp
	_last_timestamp = timestamp
	if _worker_id < 0:
		_worker_id = _random_worker_id()
	var id: int = ((timestamp - UUID_EPOCH) << UUID_TIMESTAMP_SHIFT) | (_worker_id << UUID_WORKER_ID_SHIFT) | _sequence
	_mutex.unlock()
	return id

# A random worker id is used to lower the chance of duplicated ids between processes.
static func _random_worker_id() -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = TimeUtils.current_time_millis() ^ (OS.get_process_id() * 1_000_003)
	return rng.randi() & UUID_MAX_WORKER_ID
