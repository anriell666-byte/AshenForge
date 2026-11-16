extends RefCounted
class_name AshenSaveManager

const SAVE_PATH := "user://ashenforge_save.json"

static func save_game(state: AshenGameState) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state.to_dict(), "\t"))

static func load_game(state: AshenGameState) -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		state.from_dict(parsed)
