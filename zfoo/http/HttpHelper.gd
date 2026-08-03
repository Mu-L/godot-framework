class_name HttpHelper
extends Object

static var http: AsyncHttp = AsyncHttp.new()


## proxy: optional proxy address, e.g. "127.0.0.1:10809"
static func async_get(url: String, proxy: String = "") -> HttpResponse:
	return await http.async_request(HTTPClient.METHOD_GET, url, PackedStringArray(), "", proxy)

static func async_post(url: String, json: String, extra_headers: PackedStringArray = PackedStringArray(), proxy: String = "") -> HttpResponse:
	var headers := PackedStringArray(["Content-Type: application/json"])
	headers.append_array(extra_headers)
	return await http.async_request(HTTPClient.METHOD_POST, url, headers, json, proxy)
