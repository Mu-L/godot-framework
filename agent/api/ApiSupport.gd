class_name ApiSupport
extends RefCounted

## Recommended OpenAI-compatible providers used to autofill connection settings.

const CUSTOM_PROVIDER := "Custom"
static var PROVIDERS: Array[ApiProvider] = [
	ApiProvider.new("DeepSeek", "https://api.deepseek.com/chat/completions", "deepseek-v4-flash"),
	ApiProvider.new("OpenAI", "https://api.openai.com/v1/chat/completions", "gpt-5.4"),
	ApiProvider.new("xAI", "https://api.x.ai/v1/chat/completions", "grok-4.7"),
	ApiProvider.new("Mistral AI", "https://api.mistral.ai/v1/chat/completions", "mistral-large-latest"),
	ApiProvider.new("OpenRouter", "https://openrouter.ai/api/v1/chat/completions", "~openai/gpt-latest"),
	ApiProvider.new("Together AI", "https://api.together.xyz/v1/chat/completions", "meta-llama/Llama-3.3-70B-Instruct-Turbo"),
	ApiProvider.new("Fireworks AI", "https://api.fireworks.ai/inference/v1/chat/completions", "accounts/fireworks/models/llama-v3p3-70b-instruct"),
	ApiProvider.new("Cerebras", "https://api.cerebras.ai/v1/chat/completions", "gpt-oss-120b"),
	ApiProvider.new("NVIDIA NIM", "https://integrate.api.nvidia.com/v1/chat/completions", "meta/llama-3.3-70b-instruct"),
	ApiProvider.new("Alibaba Cloud Model Studio", "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions", "qwen-plus"),
	ApiProvider.new("Moonshot AI", "https://api.moonshot.ai/v1/chat/completions", "kimi-k2.5"),
	ApiProvider.new("Z.ai", "https://api.z.ai/api/paas/v4/chat/completions", "glm-4.7"),
	ApiProvider.new("SiliconFlow", "https://api.siliconflow.com/v1/chat/completions", "deepseek-ai/DeepSeek-V3.2"),
	ApiProvider.new("MiniMax", "https://api.minimax.io/v1/chat/completions", "MiniMax-M2.7"),
]


static func get_provider(index: int) -> ApiProvider:
	if index < 0 or index >= PROVIDERS.size():
		return null
	return PROVIDERS[index]
