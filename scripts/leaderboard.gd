extends Node

const API_KEY := "jmavZbgwXnaMbfm64519o7krv3FqsZvY37yOxdtG"
const GAME_ID := "solaticegamejam2026"
const REQUEST_TIMEOUT := 10.0
# Backend ranks highest score first; times are stored inverted so the
# fastest run ranks on top. Ceiling = 10 hours in ms.
const TIME_CEILING := 36000000

var _jobs: Array = []
var _working: bool = false

func _ready() -> void:
	SilentWolf.configure({
		"api_key": API_KEY,
		"game_id": GAME_ID,
		"log_level": 0,
	})

func submit(board: String, player_name: String, score: int) -> void:
	var stored: int = TIME_CEILING - score if board == "time" else score
	_enqueue(func() -> void:
		SilentWolf.Scores.save_score(player_name, stored, board)
		await _await_result(SilentWolf.Scores.sw_save_score_complete)
	)

func fetch_top_text(board: String, count: int, callback: Callable) -> void:
	_enqueue(func() -> void:
		SilentWolf.Scores.get_scores(count, board)
		var res = await _await_result(SilentWolf.Scores.sw_get_scores_complete)
		if not callback.is_valid():
			return
		if res == null or not res.get("success", false):
			callback.call("Leaderboard unavailable")
			return
		callback.call(_format_entries(board, res.get("scores", [])))
	)

# The addon reuses one HTTPRequest slot per call type and never emits its
# completion signal on connection failure, so calls are serialized and
# awaited with a timeout.
func _enqueue(job: Callable) -> void:
	_jobs.append(job)
	_run_jobs()

func _run_jobs() -> void:
	if _working:
		return
	_working = true
	while not _jobs.is_empty():
		var job: Callable = _jobs.pop_front()
		await job.call()
	_working = false

func _await_result(sig: Signal) -> Variant:
	var state := {"done": false, "result": null}
	var on_done := func(sw_result) -> void:
		state["done"] = true
		state["result"] = sw_result
	sig.connect(on_done, CONNECT_ONE_SHOT)
	var elapsed := 0.0
	while not state["done"] and elapsed < REQUEST_TIMEOUT:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	if not state["done"] and sig.is_connected(on_done):
		sig.disconnect(on_done)
	return state["result"]

func _format_entries(board: String, entries: Array) -> String:
	if entries.is_empty():
		return "No scores yet"
	var lines: Array = []
	for i in entries.size():
		var e: Dictionary = entries[i]
		var raw: int = int(e["score"])
		var score_text: String
		if board == "time":
			score_text = GameSession.format_ms(TIME_CEILING - raw)
		else:
			score_text = "%dm" % raw
		lines.append("%d. %-14s %s" % [i + 1, e["player_name"], score_text])
	return "\n".join(lines)
