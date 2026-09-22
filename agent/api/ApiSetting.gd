class_name ApiSetting
extends RefCounted

## Persisted OpenAI-compatible API connection settings.

const API_URL_KEY := "agent_ai_api_url"
const API_TOKEN_KEY := "agent_ai_api_token"
const PROXY_ADDRESS_KEY := "agent_ai_proxy_address"


static func get_api_url() -> String:
	return Setting.get_string(API_URL_KEY, OpenAiClient.base_url)


static func get_api_token() -> String:
	return Setting.get_string(API_TOKEN_KEY, OpenAiClient.api_key)


static func get_proxy_address() -> String:
	return Setting.get_string(PROXY_ADDRESS_KEY).strip_edges()


static func save(api_url: String, api_token: String, proxy_address: String) -> void:
	Setting.set_string(API_URL_KEY, api_url.strip_edges())
	Setting.set_string(API_TOKEN_KEY, api_token.strip_edges())
	Setting.set_string(PROXY_ADDRESS_KEY, proxy_address.strip_edges())
	Setting.save()
	apply_to_client()
	pass


static func apply_to_client() -> void:
	OpenAiClient.base_url = get_api_url()
	OpenAiClient.api_key = get_api_token()
	pass
