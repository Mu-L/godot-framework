class_name Audios
extends Object

# Multi-channel audio: a pool of AudioStreamPlayers that can play multiple sounds concurrently.

const COUNT: int = 8
const BUS_NAME: String = "SoundEffect"

static var audios: Array[AudioStreamPlayer] = []

static func init() -> void:
	AudioServer.add_bus()
	var bus_index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, BUS_NAME)

	var sfx_node := Node.new()
	sfx_node.name = BUS_NAME
	gdf.gdf_node.add_child(sfx_node)
	for i in range(COUNT):
		var player := AudioStreamPlayer.new()
		player.name = StringUtils.format("sfx_{}", i)
		player.bus = BUS_NAME
		player.finished.connect(func() -> void: player.stream = null)
		sfx_node.add_child(player)
		audios.append(player)
	pass

static func set_bus_volume_linear(volume_linear: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(BUS_NAME), clampf(volume_linear, 0.0, 1.0))
	pass

static func play(path: String, volume_linear: float = 1.0) -> void:
	var resource := await ResourceHelper.async_load(path) as AudioStream
	if resource == null:
		return
	for audio in audios:
		if !audio.playing:
			audio.volume_linear = clampf(volume_linear, 0.0, 1.0)
			audio.stream = resource
			audio.play()
			break
	pass

static func stop_all() -> void:
	for player in audios:
		player.stop()
		player.stream = null
	pass
