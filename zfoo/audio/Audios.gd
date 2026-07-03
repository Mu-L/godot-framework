class_name Audios
extends Object

const COUNT: int = 8
const NAME: String = "SoundEffect"

static var audios: Array[AudioStreamPlayer] = []

static func init() -> void:
	var sound_effect_node := Node.new()
	sound_effect_node.name = NAME
	gdf.gdf_node.add_child(sound_effect_node)
	for i in range(COUNT):
		var player := AudioStreamPlayer.new()
		player.name = StringUtils.format("sfx_{}", i)
		player.bus = NAME
		player.finished.connect(func() -> void: player.stream = null)
		sound_effect_node.add_child(player)
		audios.append(player)
	pass

static func play(path: String, volume_linear: float = 1.0) -> void:
	if StringUtils.is_blank(path):
		return
	var resource: Variant = await ResourceHelper.async_load(path)
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
