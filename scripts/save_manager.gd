extends RefCounted
class_name AshenSaveManager

const SAVE_PATH := "user://ashenforge_save.json"
const SETTINGS_PATH := "user://ashenforge_settings.json"

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

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

static func save_settings(autosave_enabled: bool) -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"autosave": autosave_enabled}))

static func load_autosave_setting() -> bool:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return true
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return true
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return bool(parsed.get("autosave", true))
	return true
