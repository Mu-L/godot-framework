class_name OpenAiResponse
extends RefCounted


class Message:
	var role: String = ""
	var content: String = ""
	pass


class Choice:
	var index: int = 0
	var message: Message = Message.new()
	var finish_reason: String = ""
	pass


var id: String = ""
var model: String = ""
var choices: Array[Choice] = []
