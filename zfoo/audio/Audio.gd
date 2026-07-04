class_name Audio
extends Object

# Single-channel audio: one AudioStreamPlayer per bus; a new sound replaces the current one.

enum AudioBusType {
	Music,
	Sound,
	Voice,
	Ambience,
}

const ENDING_THRESHOLD: float = 4.0

static var audio_map: Dictionary[AudioBusType, AudioStreamPlayer] = {}

static func init() -> void:
	for bus_name in AudioBusType.keys():
		AudioServer.add_bus()
		var bus_index := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, bus_name)

		var bus_value: AudioBusType = AudioBusType[bus_name]
		var audio_stream_player := AudioStreamPlayer.new()
		audio_stream_player.name = bus_name
		audio_stream_player.bus = bus_name
		gdf.gdf_node.add_child(audio_stream_player)
		audio_map[bus_value] = audio_stream_player
	pass

####################################################################################################
# music update
static var musics: Array[String] = []
static var music_change_timestamp: int = 0

static func async_update() -> void:
	var audio: AudioStreamPlayer = audio_map[AudioBusType.Music]
	if !audio.playing:
		return
	if musics.is_empty():
		return
	var total_length: float = audio.stream.get_length()
	var position: float = audio.get_playback_position()
	if total_length <= 0.0 || position <= 0.0 || (total_length - position) > ENDING_THRESHOLD:
		return
	if TimeUtils.now() - music_change_timestamp < TimeUtils.MILLIS_PER_SECOND_10:
		return
	gdf.callable_deferred(Callable(Audio, "play_music_random").bind(3.0))
	music_change_timestamp = TimeUtils.now()
	pass
####################################################################################################

static func set_audio_bus_volume_linear(type: AudioBusType, volume_linear: float) -> void:
	var bus_name: String = AudioBusType.keys()[type]
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus_name), clampf(volume_linear, 0.0, 1.0))
	pass

static func stop_all() -> void:
	for audio_bus in audio_map.keys():
		stop_stream_fade(audio_bus)
	pass

####################################################################################################
# stream
static func play_stream(bus: AudioBusType, path: String) -> void:
	var resource := await ResourceHelper.async_load(path) as AudioStream
	if resource == null:
		return
	var player: AudioStreamPlayer = audio_map[bus]
	player.stream = resource
	player.play()
	pass

static func stop_stream(bus: AudioBusType) -> void:
	var player: AudioStreamPlayer = audio_map[bus]
	player.stop()
	pass

static func play_stream_fade(bus: AudioBusType, path: String, duration: float = 1.0) -> void:
	var resource := await ResourceHelper.async_load(path) as AudioStream
	if resource == null:
		return
	var audio: AudioStreamPlayer = audio_map[bus]
	if audio.playing:
		var tween := audio.create_tween()
		tween.tween_property(audio, "volume_linear", 0, duration)
		await tween.finished
	else:
		audio.volume_linear = 0
	audio.stream = resource
	audio.play()
	audio.create_tween().tween_property(audio, "volume_linear", 1, duration)
	pass

static func stop_stream_fade(bus: AudioBusType, duration: float = 1.0) -> void:
	var audio: AudioStreamPlayer = audio_map[bus]
	if !audio.playing:
		return
	var tween := audio.create_tween()
	tween.tween_property(audio, "volume_linear", 0, duration)
	await tween.finished
	audio.stop()
	pass
####################################################################################################
# music
static func play_music(path: String) -> void:
	musics = [path]
	play_music_random()
	pass

static func play_musics(paths: Array[String]) -> void:
	musics = paths
	play_music_random()
	pass

static func play_music_random(duration: float = 1.0) -> void:
	if musics.is_empty():
		return
	var path: String = RandomUtils.random_ele(musics)
	await play_stream_fade(AudioBusType.Music, path, duration)
	pass

####################################################################################################
# sound
static func play_sound(path: String) -> void:
	await play_stream(AudioBusType.Sound, path)
	pass

static func is_playing_sound() -> bool:
	var audio := audio_map[AudioBusType.Sound]
	return audio.playing
	
static func stop_sound() -> void:
	stop_stream(AudioBusType.Sound)
	pass
####################################################################################################
# voice
static func play_voice(path: String) -> void:
	await play_stream(AudioBusType.Voice, path)
	pass

static func is_playing_voice() -> bool:
	var audio := audio_map[AudioBusType.Voice]
	return audio.playing
	
static func stop_voice() -> void:
	stop_stream(AudioBusType.Voice)
	pass
####################################################################################################
# ambience
static func play_ambience(path: String) -> void:
	await play_stream(AudioBusType.Ambience, path)
	pass

static func play_ambience_fade(path: String, duration: float = 1.0) -> void:
	await play_stream_fade(AudioBusType.Ambience, path, duration)
	pass

static func is_playing_ambience() -> bool:
	var audio := audio_map[AudioBusType.Ambience]
	return audio.playing

static func stop_ambience() -> void:
	stop_stream(AudioBusType.Ambience)
	pass

static func stop_ambience_fade(duration: float = 1.0) -> void:
	await stop_stream_fade(AudioBusType.Ambience, duration)
	pass