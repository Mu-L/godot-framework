class_name IdUtils
extends Object

# ---------------------------------------------------------------------------
# Constants — epochs and bit layouts
# ---------------------------------------------------------------------------

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

## short_uuid layout: 21 bits timestamp in seconds | 10 bits sequence.
## 21 + 10 = 31 bits, so every id fits [constant NumberUtils.INT32_MAX] (2147483647).
##
## Only 31 bits are available, so this id is best effort, not globally unique:
## - the timestamp has second resolution (instead of millisecond) and its 21 bits wrap every
##   2^21 seconds (about 24 days), so an id can repeat an id generated 24 days earlier;
## - there is no worker id, so two processes can generate the same id in the same second.
const SHORT_SEQUENCE_BITS: int = 10
const SHORT_MAX_SEQUENCE: int = (1 << SHORT_SEQUENCE_BITS) - 1
const SHORT_SECOND_BITS: int = 21
const SHORT_MAX_SECOND: int = (1 << SHORT_SECOND_BITS) - 1


# ---------------------------------------------------------------------------
# Local id — unique inside the current run
# ---------------------------------------------------------------------------

static var _local_id: int = 0

## Returns an id which is unique inside the current run, it restarts from 1 after every run.
static func local_id() -> int:
	_local_id += 1
	return _local_id


# ---------------------------------------------------------------------------
# Uuid — globally unique, 63 bits
# ---------------------------------------------------------------------------

## Guards [method uuid] and [method short_uuid].
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
		# The worker id is random, which lowers the chance of duplicated ids between processes.
		var rng := RandomNumberGenerator.new()
		rng.seed = TimeUtils.current_time_millis() ^ (OS.get_process_id() * 1_000_003)
		_worker_id = rng.randi() & UUID_MAX_WORKER_ID
	var id: int = ((timestamp - UUID_EPOCH) << UUID_TIMESTAMP_SHIFT) | (_worker_id << UUID_WORKER_ID_SHIFT) | _sequence
	_mutex.unlock()
	return id


# ---------------------------------------------------------------------------
# Short uuid — int32, best effort
# ---------------------------------------------------------------------------

static var _short_second: int = 0
static var _short_sequence: int = 0

## Returns a short best effort id that always fits a positive 32 bit integer
## (0 <= id <= [constant NumberUtils.INT32_MAX]), for ids that only have to be unique inside one
## process: chat / session numbers, UI element ids, log tags, and so on.
##
## Unlike [method uuid] this id is not globally unique, see the notes on [constant SHORT_SECOND_BITS]:
## after about 24 days the 21 bit second counter wraps and an id can repeat, and without a worker id
## two processes can generate the same id in the same second.
## Within one process the ids still increase monotonically, and the call never waits: once more than
## [constant SHORT_MAX_SEQUENCE] + 1 ids have been generated inside one second, the following ones
## borrow the next second, so the encoded second can lead the wall clock.
static func short_uuid() -> int:
	_mutex.lock()
	@warning_ignore("integer_division")
	var second: int = (TimeUtils.current_time_millis() - UUID_EPOCH) / TimeUtils.MILLIS_PER_SECOND
	if second > _short_second:
		# A new second, the sequence restarts from zero.
		_short_sequence = 0
	else:
		# The same second, or the clock moved backwards: reuse the last second to stay monotonic.
		_short_sequence += 1
		if _short_sequence > SHORT_MAX_SEQUENCE:
			# The sequence of this second is exhausted, borrow the next second instead of waiting.
			second = _short_second + 1
			_short_sequence = 0
		else:
			second = _short_second
	_short_second = second
	var id: int = ((second & SHORT_MAX_SECOND) << SHORT_SEQUENCE_BITS) | _short_sequence
	_mutex.unlock()
	return id
