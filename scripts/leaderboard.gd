extends Node

const _TIME_PRIV := "YOUR_TIME_PRIVATE_KEY"
const _TIME_PUB := "YOUR_TIME_PUBLIC_KEY"
const _DIST_PRIV := "YOUR_DIST_PRIVATE_KEY"
const _DIST_PUB := "YOUR_DIST_PUBLIC_KEY"

signal scores_received(board: String, entries: Array)

func submit(board: String, name: String, score: int) -> void:
	var priv := _TIME_PRIV if board == "time" else _DIST_PRIV
	var url := "https://dreamlo.com/lb/%s/add/%s/%d" % [priv, name.uri_encode(), score]
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
	http.request(url)

func fetch(board: String, count: int) -> void:
	var pub := _TIME_PUB if board == "time" else _DIST_PUB
	var order := "pipe-asc" if board == "time" else "pipe"
	var url := "https://dreamlo.com/lb/%s/%s/%d" % [pub, order, count]
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, body):
		var text: String = body.get_string_from_utf8()
		var entries: Array = []
		for line in text.split("\n"):
			var parts := line.split("|")
			if parts.size() >= 2 and parts[0] != "":
				entries.append({"name": parts[0], "score": int(parts[1])})
		scores_received.emit(board, entries)
		http.queue_free()
	)
	http.request(url)
