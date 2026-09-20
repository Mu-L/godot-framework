class_name HttpHelper
extends Object

static var http: AsyncHttp = AsyncHttp.new()


## timeout_millis: request timeout in milliseconds (default 60s)
## proxy: optional proxy address, e.g. "127.0.0.1:10809"
static func async_get(url: String, timeout_millis: int = AsyncHttp.DEFAULT_TIMEOUT_MILLIS, proxy: String = "", extra_headers: PackedStringArray = PackedStringArray()) -> HttpResponse:
	return await http.async_request(HTTPClient.METHOD_GET, url, "", extra_headers, timeout_millis, proxy)

static func async_post(url: String, json: String, extra_headers: PackedStringArray = PackedStringArray(), timeout_millis: int = AsyncHttp.DEFAULT_TIMEOUT_MILLIS, proxy: String = "", on_body_chunk: Callable = Callable()) -> HttpResponse:
	var headers := extra_headers.duplicate()
	if not HttpUtils.has_header(headers, "Content-Type"):
		headers.insert(0, "Content-Type: application/json")
	return await http.async_request(HTTPClient.METHOD_POST, url, json, headers, timeout_millis, proxy, on_body_chunk)

## Stops the most recently started HTTP request that is still running.
static func stop_last() -> void:
	http.stop_last()
	pass

## Stops all HTTP requests that are still running.
static func stop_all() -> void:
	http.stop_all()
	pass
