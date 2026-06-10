extends Node

const _TIME_PRIV := "B5dPJ74M6kWxbY77FOjY0g46GFvrz93kCvIJSVjD0nuA"
const _TIME_PUB := "6a28628e8f40bb17b0924f49"
const _DIST_PRIV := "bTidzlnIr0KhoxJehhEidAbGGpMUO_REqNcAMPUFR8FQ"
const _DIST_PUB := "6a2860018f40bb17b09231bf"

var _active_fetches: Dictionary = {}

func submit(board: String, name: String, score: int) -> void:
	var priv := _TIME_PRIV if board == "time" else _DIST_PRIV
	var url := "https://dreamlo.com/lb/%s/add/%s/%d" % [priv, name.uri_encode(), score]
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
	if http.request(url) != OK:
		http.queue_free()

func fetch_top_text(board: String, count: int, callback: Callable) -> void:
	if _active_fetches.has(board):
		var old: HTTPRequest = _active_fetches[board]
		if is_instance_valid(old):
			old.cancel_request()
			old.queue_free()
		_active_fetches.erase(board)

	var pub := _TIME_PUB if board == "time" else _DIST_PUB
	var order := "pipe-asc" if board == "time" else "pipe"
	var url := "https://dreamlo.com/lb/%s/%s/%d" % [pub, order, count]
	var http := HTTPRequest.new()
	add_child(http)
	_active_fetches[board] = http
	http.request_completed.connect(func(result: int, code: int, _h, body: PackedByteArray):
		_active_fetches.erase(board)
		http.queue_free()
		if not callback.is_valid():
			return
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			callback.call("Leaderboard unavailable")
			return
		callback.call(_format_entries(board, _parse_entries(body.get_string_from_utf8())))
	)
	if http.request(url) != OK:
		_active_fetches.erase(board)
		http.queue_free()
		if callback.is_valid():
			callback.call("Leaderboard unavailable")

func _parse_entries(text: String) -> Array:
	var entries: Array = []
	for line in text.split("\n"):
		var parts := line.split("|")
		if parts.size() >= 2 and parts[0] != "":
			entries.append({"name": parts[0], "score": int(parts[1])})
	return entries

func _format_entries(board: String, entries: Array) -> String:
	if entries.is_empty():
		return "No scores yet"
	var lines: Array = []
	for i in entries.size():
		var e: Dictionary = entries[i]
		var score_text: String = GameSession.format_ms(e["score"]) if board == "time" else "%dm" % e["score"]
		lines.append("%d. %-14s %s" % [i + 1, e["name"], score_text])
	return "\n".join(lines)
