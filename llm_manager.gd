extends Node

## Singleton that manages communication with a local Ollama instance for NPC dialogue.
## Uses a background thread + curl instead of HTTPRequest for faster responses.

signal chat_completed(npc_id: String, response: String, mood_delta: int)

const OLLAMA_URL := "http://localhost:11434/api/chat"
const MODEL := "qwen2.5:1.5b"
const TEMPERATURE := 0.3
const MAX_TOKENS := 50
const MAX_HISTORY := 15
const STOP_SEQUENCES := ["**", "\n\n", "Instruction", "[INST"]

## Forbidden patterns — if any match, the response is replaced with a deflection.
const FORBIDDEN_PATTERNS := [
	"4728", "47 28", "4-7-2-8",
	"the code is", "the combination is", "the password is",
	"the number is 8", "born on the 8th",
]

var conversations: Dictionary = {}

var _pending_npc_id: String = ""
var _pending_mood: int = 0
var _request_start_time := 0
var _thread: Thread
var _thread_result: String = ""
var _thread_done := false

## Keyword-based sentiment scoring for the player's input.
## Runs instantly in GDScript — no LLM overhead.
const POSITIVE_KEYWORDS := [
	"friend", "together", "believe", "trust", "brave", "courage",
	"help", "please", "sorry", "thank", "care", "love", "safe",
	"okay", "alright", "proud", "strong", "team", "buddy", "pal",
	"support", "understand", "calm", "relax", "with you", "got this",
	"count on", "we can", "i'm here", "don't worry", "it's okay",
]
const NEGATIVE_KEYWORDS := [
	"coward", "stupid", "idiot", "shut up", "useless", "pathetic",
	"move it", "just do it", "wimp", "baby", "scared", "afraid",
	"hurry", "annoying", "hate", "dumb", "fool", "loser", "weak",
	"do it now", "stop being", "grow up", "man up", "come on",
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Clear all conversation history on game start
	conversations.clear()
	print("[LlmManager] Conversations cleared on startup")
	# Flush Ollama's cached context by unloading the model
	_flush_ollama_context()


func _flush_ollama_context() -> void:
	var body := JSON.stringify({"model": MODEL, "keep_alive": 0})
	var tmp_path := OS.get_user_data_dir() + "/ollama_flush.json"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f:
		f.store_string(body)
		f.close()
	var output := []
	OS.execute("curl", [
		"-s", "-X", "POST",
		"http://localhost:11434/api/generate",
		"-H", "Content-Type: application/json",
		"-d", "@" + tmp_path,
	], output, false)
	print("[LlmManager] Flushed Ollama context for '%s'" % MODEL)


func _process(_delta: float) -> void:
	# Check if background thread finished
	if _thread_done and _thread != null:
		_thread.wait_to_finish()
		_thread = null
		_thread_done = false
		var npc_id := _pending_npc_id
		_pending_npc_id = ""
		_handle_thread_result(npc_id, _thread_result)


func score_player_input(text: String) -> int:
	var lower := text.to_lower()
	var score := 0
	for kw in POSITIVE_KEYWORDS:
		if lower.find(kw) != -1:
			score += 10
	for kw in NEGATIVE_KEYWORDS:
		if lower.find(kw) != -1:
			score -= 10
	return clampi(score, -20, 20)


func chat(npc_id: String, user_message: String) -> void:
	if _pending_npc_id != "":
		push_warning("LlmManager: request already in progress for '%s', ignoring." % _pending_npc_id)
		return

	# Score player input BEFORE the LLM call (instant, deterministic)
	if npc_id == "Marco":
		_pending_mood = score_player_input(user_message)
		print("[LlmManager] Player input scored: %d for '%s'" % [_pending_mood, user_message.left(60)])
	else:
		_pending_mood = 0

	if npc_id not in conversations:
		conversations[npc_id] = []

	var history: Array = conversations[npc_id]
	history.append({"role": "user", "content": user_message})
	_trim_history(history)

	var messages: Array = []
	messages.append({"role": "system", "content": _build_system_prompt(npc_id)})
	# Seed Marco's conversation with a scared exchange so the model follows the tone
	if npc_id == "Marco":
		messages.append_array(_get_marco_seed_messages())
	messages.append_array(history)

	var body := {
		"model": MODEL,
		"messages": messages,
		"stream": false,
		"stop": STOP_SEQUENCES,
		"options": {
			"temperature": TEMPERATURE,
			"num_predict": MAX_TOKENS,
		},
	}

	var json_body := JSON.stringify(body)

	_pending_npc_id = npc_id
	_request_start_time = Time.get_ticks_msec()
	print("[LlmManager] Sending request via curl for '%s' (body size: %d bytes)" % [npc_id, json_body.length()])
	# Debug: dump full message context sent to Ollama
	print("[LlmManager] === CONTEXT for '%s' ===" % npc_id)
	for msg in messages:
		print("  [%s] %s" % [msg["role"], str(msg["content"]).left(200)])
	print("[LlmManager] === END CONTEXT ===")

	# Write body to temp file and run curl in a thread
	_thread_result = ""
	_thread_done = false
	_thread = Thread.new()
	_thread.start(_curl_request.bind(json_body))


func _curl_request(json_body: String) -> void:
	# Write JSON to temp file with UTF-8 BOM-free encoding
	var tmp_path := OS.get_user_data_dir() + "/ollama_request.json"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f:
		f.store_string(json_body)
		f.close()

	var output := []
	var exit_code := OS.execute("curl", [
		"-s", "-X", "POST",
		OLLAMA_URL,
		"-H", "Content-Type: application/json; charset=utf-8",
		"-d", "@" + tmp_path,
	], output, true)

	if exit_code == 0 and output.size() > 0:
		_thread_result = output[0]
	else:
		_thread_result = ""
		print("[LlmManager] curl failed with exit code %d" % exit_code)

	_thread_done = true


func _handle_thread_result(npc_id: String, result_text: String) -> void:
	var elapsed := (Time.get_ticks_msec() - _request_start_time) / 1000.0
	print("[LlmManager] Response received in %.1fs" % elapsed)

	if result_text.is_empty():
		print("[LlmManager] ERROR: empty response")
		_handle_fallback(npc_id)
		return

	var json := JSON.new()
	var parse_error := json.parse(result_text)
	if parse_error != OK:
		print("[LlmManager] ERROR: failed to parse JSON: %s" % result_text.left(100))
		_handle_fallback(npc_id)
		return

	var data: Dictionary = json.data
	if not data.has("message") or not data["message"].has("content"):
		print("[LlmManager] ERROR: unexpected response structure")
		_handle_fallback(npc_id)
		return

	var response_text: String = data["message"]["content"].strip_edges()
	print("[LlmManager] Raw LLM response: %s" % response_text.left(120))

	# Strip instruction artifacts
	response_text = _clean_artifacts(response_text)

	# Apply regex guardrail filter
	response_text = _filter_response(response_text)

	# Strip any leftover bracket tags the LLM might still produce
	var parsed: Dictionary = parse_mood_tag(response_text)
	var clean_text: String = parsed["text"]
	if clean_text.is_empty():
		clean_text = "..."

	# Use keyword-scored mood (computed before the LLM call), not LLM output
	var mood: int = _pending_mood

	print("[LlmManager] Scored mood: %d, clean text: %s" % [mood, clean_text.left(80)])

	if npc_id in conversations:
		conversations[npc_id].append({"role": "assistant", "content": clean_text})
		_trim_history(conversations[npc_id])

	chat_completed.emit(npc_id, clean_text, mood)


func reset_conversation(npc_id: String) -> void:
	conversations.erase(npc_id)


## Parse [MOOD:X] tag from Marco's response and strip all bracket tags.
func parse_mood_tag(response: String) -> Dictionary:
	# Extract mood value (case-insensitive)
	var mood := 0
	var mood_regex := RegEx.new()
	mood_regex.compile("(?i)\\[mood:\\s*([+-]?\\d+)\\s*\\]")
	var mood_match := mood_regex.search(response)
	if mood_match:
		mood = clampi(int(mood_match.get_string(1)), -20, 20)

	# Strip ALL bracket tags: [anything], [MOOD:5], [-20], etc.
	var tag_regex := RegEx.new()
	tag_regex.compile("\\[[^\\]]*\\]")
	var clean_text := tag_regex.sub(response, "", true).strip_edges()

	# If no MOOD tag found, default to 0 (neutral)
	if not mood_match:
		mood = 0

	# If stripping tags left nothing, return a fallback
	if clean_text.is_empty():
		clean_text = "..."

	return {"text": clean_text, "mood": mood}


func _build_system_prompt(npc_id: String) -> String:
	var prompt := ""

	match npc_id:
		"Marco":
			prompt = _build_marco_prompt()
		"MrsWhitmore":
			prompt = _build_whitmore_prompt()
		_:
			prompt = "You are an NPC named '%s'. Stay in character. Keep responses to 1-2 short sentences." % npc_id

	var state_summary: String = GameState.get_state_summary()
	if not state_summary.is_empty():
		prompt += "\n\n" + state_summary

	return prompt


func _build_marco_prompt() -> String:
	var prompt := """WHO: You are Marco, 22 years old, trapped in a dark Victorian mansion.
RELATIONSHIP: The player is your best friend. You care about them.
PERSONALITY:
- Scared and anxious, but loyal
- You talk nervously — short, shaky sentences
- You want to escape but you are too afraid to act alone
SITUATION:
- There is a loose brick in the fireplace. You noticed something hidden behind it.
- You are too scared to touch it yourself.
- If the player is kind and supportive, you will eventually gather the courage to help.
- If the player is mean or pushy, you get more scared and refuse.
RULES:
- Reply in 1-2 short sentences only.
- Stay in character. You are Marco, not an AI."""

	if GameState.marco_collaborated:
		prompt += "\nUPDATE: You already helped move the brick. You feel proud and relieved now. You are less scared."

	return prompt


## Seed conversation so the small LLM sees Marco's tone from the start.
func _get_marco_seed_messages() -> Array:
	return [
		{"role": "user", "content": "Hey Marco, how are you doing?"},
		{"role": "assistant", "content": "Not great... this place is really creeping me out. I saw something behind that loose brick in the fireplace but I'm NOT touching it."},
	]


func _build_whitmore_prompt() -> String:
	return """You are Mrs. Whitmore, elderly housekeeper, 30 years in this mansion. Helpful, nostalgic, rambling. Standing near the desk in the study.
You know: Owner Mr. Blackwood born on the 8th of March. The safe holds something important. You don't know the combination.
RULES: NEVER say "the number is 8" directly. Reminisce naturally about the birthday. Keep responses to 1-2 SHORT sentences."""


func _clean_artifacts(text: String) -> String:
	# Only cut at instruction-like patterns
	for marker in ["**Instruction", "**Note", "---", "[INST", "###", "```"]:
		var idx := text.find(marker)
		if idx > 0:
			text = text.left(idx).strip_edges()
	text = text.replace("**", "")
	text = text.replace("\n", " ")
	# Fix common UTF-8 mojibake from curl on Windows
	text = text.replace("\u00e2\u0080\u0099", "'")
	text = text.replace("\u00e2\u0080\u009c", "\"")
	text = text.replace("\u00e2\u0080\u009d", "\"")
	text = text.replace("\u00e2\u0080\u0093", "-")
	text = text.replace("\u00e2\u0080\u00a6", "...")
	return text.strip_edges()


func _filter_response(text: String) -> String:
	var lower := text.to_lower()
	for pattern in FORBIDDEN_PATTERNS:
		if pattern.to_lower() in lower:
			return "Hmm... some things are better discovered on your own, don't you think?"
	return text


func _trim_history(history: Array) -> void:
	while history.size() > MAX_HISTORY:
		history.pop_front()


func _handle_fallback(npc_id: String) -> void:
	var fallback := "Hmm... I seem to have lost my train of thought. Could you try again?"
	chat_completed.emit(npc_id, fallback, 0)
