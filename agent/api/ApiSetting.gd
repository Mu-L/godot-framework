class_name ApiSetting
extends RefCounted

## Persisted OpenAI-compatible API connection settings.

const API_URL_KEY := "agent_ai_api_url"
const API_TOKEN_KEY := "agent_ai_api_token"
const PROXY_ADDRESS_KEY := "agent_ai_proxy_address"
const MODEL_KEY := "agent_ai_model"


const DEFAULT_API_URL := "https://api.deepseek.com/chat/completions"
const DEFAULT_MODEL := "deepseek-v4-flash"
const API_KEY_ENV := "OPENAI_API_KEY"


static func get_api_url() -> String:
	return Setting.get_string(API_URL_KEY, DEFAULT_API_URL)


static func get_api_token() -> String:
	return Setting.get_string(API_TOKEN_KEY, OS.get_environment(API_KEY_ENV))


static func get_model() -> String:
	return Setting.get_string(MODEL_KEY, DEFAULT_MODEL)


static func get_proxy_address() -> String:
	return Setting.get_string(PROXY_ADDRESS_KEY).strip_edges()


static func save(api_url: String, api_token: String, model: String, proxy_address: String) -> void:
	Setting.set_string(API_URL_KEY, api_url.strip_edges())
	Setting.set_string(API_TOKEN_KEY, api_token.strip_edges())
	Setting.set_string(MODEL_KEY, model.strip_edges())
	Setting.set_string(PROXY_ADDRESS_KEY, proxy_address.strip_edges())
	Setting.save()
	pass


static func get_client() -> OpenAiClient:
	return OpenAiClient.new(get_api_token(), get_api_url(), get_model())
