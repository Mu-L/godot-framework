class_name OpenAiClient
extends Object

## Local-dev only. Replace with a backend proxy before shipping.
static var api_key: String = "xxx"
static var base_url: String = "https://api.deepseek.com/chat/completions"
static var model: String = "deepseek-v4-flash"


static func async_chat(prompt: String, system_prompt: String = "") -> String:
	var messages: Array = []
	if not StringUtils.is_blank(system_prompt):
		messages.push_back({"role": "system", "content": system_prompt})
	messages.push_back({"role": "user", "content": prompt})

	var body := {
		"model": model,
		"messages": messages,
		"stream": false
	}
	var headers := PackedStringArray([
		StringUtils.format("Authorization: Bearer {}", api_key),
	])
	var response := await HttpHelper.async_post(base_url, JSON.stringify(body), headers)
	Log.info("OpenAI response body:[{}]", response.get_body_string())
	if not response.success or response.code != 200:
		Log.error("OpenAI request failed code:[{}] body:[{}]", response.code, response.get_body_string())
		return ""

	var chat_response: OpenAiResponse = JsonUtils.json_to_object(response.get_body_string(), OpenAiResponse)
	if chat_response == null or chat_response.choices.is_empty():
		Log.error("OpenAI response parse failed body:[{}]", response.get_body_string())
		return ""

	var message := chat_response.choices[0].message
	if message == null or StringUtils.is_blank(message.content):
		Log.error("OpenAI response missing content body:[{}]", response.get_body_string())
		return ""
	return message.content
