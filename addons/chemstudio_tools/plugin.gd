@tool
extends EditorPlugin
## ChemoStudio Tools — editor dock plugin.
##
## Loads main.tscn as a right-hand dock, wires its buttons in code (the scene
## stays pure UI, this script holds all editor logic) and keeps a live log.
## Clean up is symmetrical in _exit_tree() so the dock never leaks between
## editor sessions or plugin reloads.

const DOCK_SCENE := preload("res://addons/chemstudio_tools/main.tscn")
const DOCK_SLOT := DockSlot.DOCK_SLOT_RIGHT_UL

var _dock: VBoxContainer = null
var _status: Label = null
var _log: TextEdit = null


func _enter_tree() -> void:
	_dock = DOCK_SCENE.instantiate()
	_dock.name = "ChemoStudioTools"
	add_control_to_dock(DOCK_SLOT, _dock)

	_status = _dock.get_node("Status") as Label
	_log = _dock.get_node("Log") as TextEdit

	(_dock.get_node("Buttons/ScanButton") as Button).pressed.connect(_on_scan_pressed)
	(_dock.get_node("Buttons/ClearButton") as Button).pressed.connect(_on_clear_pressed)

	_append("ChemoStudio Tools v1.0.0 loaded — Godot %s" % Engine.get_version_info().get("string", "?"))
	_append("دوس «بحث المَشاهد» لعرض كل ملفات ‎.tscn في المشروع.")


func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
	_dock = null
	_status = null
	_log = null


# ── actions ──────────────────────────────────────────────────────────────

func _on_scan_pressed() -> void:
	if not is_instance_valid(_log):
		return
	_append("── Scanning res:// for scenes… ──")
	var scenes := PackedStringArray()
	_collect_scenes("res://", scenes)
	if scenes.is_empty():
		_append("No .tscn files found outside addons/.")
	else:
		for scene_path in scenes:
			_append("  • " + scene_path)
	if is_instance_valid(_status):
		_status.text = "%d scene(s) found — تم العثور على %d مشهد" % [scenes.size(), scenes.size()]
	_append("── Scan complete ──")


func _on_clear_pressed() -> void:
	if is_instance_valid(_log):
		_log.text = ""
	if is_instance_valid(_status):
		_status.text = "Ready — جاهز"


# ── helpers ──────────────────────────────────────────────────────────────

## Recurses the project filesystem, skipping hidden folders and addons/ so the
## plugin's own main.tscn never shows up in its scan results.
func _collect_scenes(path: String, found: PackedStringArray) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_begin()
	for entry in dir.get_files():
		if entry.ends_with(".tscn"):
			found.append(path.path_join(entry))
	for sub in dir.get_directories():
		if sub.begins_with(".") or sub == "addons":
			continue
		_collect_scenes(path.path_join(sub), found)


func _append(line: String) -> void:
	if is_instance_valid(_log):
		_log.append_text(line + "\n")
