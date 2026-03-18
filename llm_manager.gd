extends Node

## Singleton that manages communication with a local Ollama instance for NPC dialogue.

signal chat_completed(npc_id: String, response: String)

const OLLAMA_URL := "http://localhost:11434/api/chat"
const MODEL := "phi3:mini"
const TEMPERATURE := 0.3
const MAX_TOKENS := 150
const MAX_HISTORY := 15
const REQUEST_TIMEOUT := 120.0

var conversations: Dictionary = {}
var game_state: Dictionary = {"items": [], "rooms_visited": []}

var _http_request: HTTPRequest
var _pending_npc_id: String = ""


func _ready() -> void:
	_http_request = HTTPRequest.new()
	_http_request.use_threads = true
	_http_request.timeout = REQUEST_TIMEOUT
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)


func chat(npc_id: String, user_message: String) -> void:
	if _pending_npc_id != "":
		push_warning("LlmManager: request already in progress for '%s', ignoring." % _pending_npc_id)
		return

	if npc_id not in conversations:
		conversations[npc_id] = []

	var history: Array = conversations[npc_id]
	history.append({"role": "user", "content": user_message})
	_trim_history(history)

	var messages: Array = []
	messages.append({"role": "system", "content": _build_system_prompt(npc_id)})
	messages.append_array(history)

	var body := {
		"model": MODEL,
		"messages": messages,
		"stream": false,
		"options": {
			"temperature": TEMPERATURE,
			"num_predict": MAX_TOKENS,
		},
	}

	var json_body := JSON.stringify(body)
	var headers := ["Content-Type: application/json"]

	_pending_npc_id = npc_id
	var error := _http_request.request(OLLAMA_URL, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		_pending_npc_id = ""
		push_error("LlmManager: HTTPRequest failed to start (error %d)" % error)
		_handle_fallback(npc_id)


func update_game_state(items: Array, rooms_visited: Array) -> void:
	game_state["items"] = items
	game_state["rooms_visited"] = rooms_visited


func reset_conversation(npc_id: String) -> void:
	conversations.erase(npc_id)


func _build_system_prompt(npc_id: String) -> String:
	var prompt := "You are an NPC named '%s' in a point-and-click escape room game. " % npc_id
	prompt += "Stay in character. Give short, helpful responses (1-3 sentences). "
	prompt += "You may give hints but never reveal solutions directly.\n\n"

	var items: Array = game_state.get("items", [])
	var rooms: Array = game_state.get("rooms_visited", [])
	if items.size() > 0 or rooms.size() > 0:
		prompt += "Current game state:\n"
		if items.size() > 0:
			prompt += "- Player inventory: %s\n" % ", ".join(items)
		if rooms.size() > 0:
			prompt += "- Rooms visited: %s\n" % ", ".join(rooms)

	return prompt


func _trim_history(history: Array) -> void:
	while history.size() > MAX_HISTORY:
		history.pop_front()


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var npc_id := _pending_npc_id
	_pending_npc_id = ""

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("LlmManager: request failed (result=%d, code=%d)" % [result, response_code])
		_handle_fallback(npc_id)
		return

	var json := JSON.new()
	var parse_error := json.parse(body.get_string_from_utf8())
	if parse_error != OK:
		push_warning("LlmManager: failed to parse response JSON")
		_handle_fallback(npc_id)
		return

	var data: Dictionary = json.data
	if not data.has("message") or not data["message"].has("content"):
		push_warning("LlmManager: unexpected response structure")
		_handle_fallback(npc_id)
		return

	var response_text: String = data["message"]["content"].strip_edges()

	if npc_id in conversations:
		conversations[npc_id].append({"role": "assistant", "content": response_text})
		_trim_history(conversations[npc_id])

	chat_completed.emit(npc_id, response_text)


func _handle_fallback(npc_id: String) -> void:
	var fallback := "!ERROR Hmm... I seem to have lost my train of thought. Could you try again?"
	chat_completed.emit(npc_id, fallback)
