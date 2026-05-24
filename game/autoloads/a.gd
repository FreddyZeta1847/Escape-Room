@tool
extends "res://addons/popochiu/engine/interfaces/i_audio.gd"

# cues ----
var menu_theme: AudioCueMusic = load("res://game/audio/cues/menu_theme.tres")
var game_theme: AudioCueMusic = load("res://game/audio/cues/game_theme.tres")
var win_theme: AudioCueMusic = load("res://game/audio/cues/win_theme.tres")
# ---- cues


# Workaround for a Popochiu bug: PopochiuAudioManager._fadeout_finished stops the
# stream player but never emits `finished`, so `_active[cue_name]` is never cleared.
# The next `.play()` of the same cue then short-circuits and returns the stopped
# player, leaving the cue silent for the rest of the session. We schedule a
# zero-fade stop after the fade completes; that path DOES emit `finished` and
# clears the leaked entry.
func safe_stop(cue: PopochiuAudioCue, fade_duration := 1.0) -> void:
	cue.stop(fade_duration)
	if fade_duration > 0.0 and is_inside_tree():
		var timer := get_tree().create_timer(fade_duration + 0.05)
		timer.timeout.connect(cue.stop.bind(0.0))

