class_name PauseMenu
extends CanvasLayer

var _panel: PanelContainer


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.theme = UI.theme()
	add_child(center)
	_panel = PanelContainer.new()
	center.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	_panel.add_child(v)
	v.add_child(UI.label("PAUSED", "Title"))
	v.add_child(UI.button("RESUME", toggle))
	v.add_child(UI.button("RESTART", func(): Transition.go(get_tree().current_scene.scene_file_path), "Blue"))
	var shake := UI.button(_shake_text(), func(): pass, "Gray")
	shake.pressed.connect(func():
		Global.shake_on = not Global.shake_on
		Global.save_game()
		shake.text = _shake_text())
	v.add_child(shake)
	var sound := UI.button(_sound_text(), func(): pass, "Gray")
	sound.pressed.connect(func():
		Global.set_sound(not Global.sound_on)
		sound.text = _sound_text())
	v.add_child(sound)
	v.add_child(UI.button("MENU", func(): Transition.go("res://scenes/main_menu.tscn"), "Red"))
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		_panel.scale = Vector2(0.7, 0.7)
		_panel.pivot_offset = _panel.size / 2.0
		create_tween().tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _shake_text() -> String:
	return "SHAKE: ON" if Global.shake_on else "SHAKE: OFF"


func _sound_text() -> String:
	return "SOUND: ON" if Global.sound_on else "SOUND: OFF"
