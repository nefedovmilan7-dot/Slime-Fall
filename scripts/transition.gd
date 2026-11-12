extends CanvasLayer

var _fade: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100 
	process_mode = Node.PROCESS_MODE_ALWAYS 
	_fade = ColorRect.new()
	_fade.color = Color(0.05, 0.03, 0.1, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func go(path: String) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, 0.22)
	await out.finished
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(path)
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, 0.28)
	await back.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
