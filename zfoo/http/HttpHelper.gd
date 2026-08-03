class_name HttpHelper
extends Object

static var http: AsyncHttp = AsyncHttp.new()


static func async_get(url: String) -> HttpResponse:
	return await http.async_request(HTTPClient.METHOD_GET, url)

static func async_post(url: String, json: String, extra_headers: PackedStringArray = PackedStringArray()) -> HttpResponse:
	var headers := PackedStringArray(["Content-Type: application/json"])
	headers.append_array(extra_headers)
	return await http.async_request(HTTPClient.METHOD_POST, url, headers, json)
