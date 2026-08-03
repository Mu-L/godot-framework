extends Node


@onready var chatButton: Button = $ChatRequest


func _ready() -> void:
	chatButton.pressed.connect(on_chat_pressed)
	pass


func on_chat_pressed() -> void:
	var text := await OpenAiClient.async_chat("用一句话介绍 godot-framework")
	if StringUtils.is_blank(text):
		Log.error("OpenAI returned empty text")
		return
	Log.info("OpenAI reply:[{}]", text)
	pass
