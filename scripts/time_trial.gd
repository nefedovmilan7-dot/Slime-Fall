extends Node2D

const SLIME := preload("res://scenes/slime.tscn")
const TOWER_SEED := 2026
const FINISH_METERS := 100
const START_Y := 300.0
const PIXELS_PER_METER := 16.0
const FINISH_REWARD := 10
const RECORD_REWARD := 25

enum State { COUNTDOWN, RUNNING, OVER }
 
var state := State.COUNTDOWN
var time := 0.0
var player: Slime
var ghost: Slime
var recording := PackedVector2Array()
var pause_menu: PauseMenu
var ui: Control
var time_label: Label
var height_label: Label
var diff_label: Label
var big: Label
var panel_box: CenterContainer
 
@onready var camera: GameCamera = $GameCamera
@onready var level: Node2D = $LevelGenerator
@onready var lava: Area2D = $Lava

func _ready() -> void:
	Global.play_music("music_game")
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	_build_ui()
	level.build(TOWER_SEED)
	lava.reset(START_Y + 60.0)
	_finish_line()
	player = SLIME.instantiate()
	player.position = Vector2(90, START_Y)
	add_child(player)
	player.dress(Global.equipped["hat"], Global.equipped["color"], Global.equipped.get("trail", "none"))
	player.died.connect(_on_died)
	level.slimes = [player]
	camera.target = player
	if Global.ghost.size() > 1:
		ghost = SLIME.instantiate()
		ghost.is_ai = true
		ghost.collision_layer = 0
		ghost.collision_mask = 0
		ghost.position = Global.ghost[0]
		add_child(ghost)
		ghost.dress(Global.equipped["hat"], "ghost")
		ghost.modulate.a = 0.4
		ghost.set_physics_process(false)
	player.set_physics_process(false)
	lava.set_physics_process(false)
	await _countdown()
	player.set_physics_process(true)
	lava.set_physics_process(true)
	state = State.RUNNING
 
 
func _finish_y() -> float:
	return START_Y - FINISH_METERS * PIXELS_PER_METER
 
 
func meters() -> int:
	return maxi(0, int((START_Y - player.best_y) / PIXELS_PER_METER))
 
 
func _physics_process(delta: float) -> void:
	if state != State.RUNNING:
		return
	time += delta
	recording.append(player.position)
	if ghost:
		var i := mini(recording.size() - 1, Global.ghost.size() - 1)
		var before := ghost.position
		ghost.position = Global.ghost[i]
		_animate_ghost(ghost.position - before)
	if player.position.y <= _finish_y():
		_finish()
 
 
func _animate_ghost(moved: Vector2) -> void:
	var anim := "jump" if moved.y < -0.5 else ("fall" if moved.y > 0.5 else "idle")
	if ghost.sprite.animation != anim:
		ghost.sprite.play(anim)
	if absf(moved.x) > 0.1:
		ghost.sprite.flip_h = moved.x < 0.0
 
 
func _process(_delta: float) -> void:
	if player == null:
		return
	time_label.text = "%.2f" % time
	height_label.text = "%dM / %dM" % [mini(meters(), FINISH_METERS), FINISH_METERS]
	if ghost and state == State.RUNNING:
		var ahead := int((ghost.position.y - player.position.y) / PIXELS_PER_METER)
		diff_label.text = ("+%dM" % ahead) if ahead >= 0 else ("%dM" % ahead)
		diff_label.modulate = Color("6fe36a") if ahead >= 0 else Color("ff7a3d")

# ------------------------------------------------------------------ the end of a run
func _finish() -> void:
	state = State.OVER
	player.set_physics_process(false)
	Global.play_sfx("medal")
	var record := Global.best_time <= 0.0 or time < Global.best_time
	var reward := FINISH_REWARD + (RECORD_REWARD if record else 0)
	if record:
		Global.best_time = time
		Global.ghost = recording   # the new ghost to beat
	Global.record_height(FINISH_METERS)
	Global.add_coins(reward)       # (this also saves)
	_panel([UI.label("NEW RECORD!" if record else "FINISHED!", "Title"), UI.label("%.2f S" % time, "Big"),
		UI.label("BEST %.2f S" % Global.best_time, "Small"), UI.label("+%d COINS" % reward, "Bold")])


func _on_died() -> void:
	if state != State.RUNNING:
		return
	state = State.OVER
	camera.shake(3.0)
	Global.record_height(meters())
	_panel([UI.label("MELTED", "Title"), UI.label("%dM OF %dM" % [meters(), FINISH_METERS], "Big")])


func _panel(items: Array) -> void:
	var p := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	for it in items:
		v.add_child(it)
	v.add_child(UI.button("RETRY", func(): Transition.go("res://scenes/time_trial.tscn")))
	v.add_child(UI.button("MENU", func(): Transition.go("res://scenes/main_menu.tscn"), "Gray"))
	p.add_child(v)
	panel_box.add_child(p)
	p.pivot_offset = Vector2(60, 50)
	p.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(p, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.theme = UI.theme()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	time_label = _label("0.00", "Big", Vector2(60, 4), 60)
	height_label = _label("", "Bold", Vector2(20, 22), 60)
	diff_label = _label("", "Bold", Vector2(110, 22), 50)
	big = _label("", "Title", Vector2(0, 120), 180)
	var pause := UI.button("II", func(): pause_menu.toggle(), "Gray")
	pause.position = Vector2(2, 2)
	pause.custom_minimum_size = Vector2(16, 14)
	ui.add_child(pause)
	panel_box = CenterContainer.new()
	panel_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(panel_box)
	UI.touch_buttons(layer)


func _label(text: String, variation: String, pos: Vector2, width: float) -> Label:
	var l := UI.label(text, variation)
	l.position = pos
	l.custom_minimum_size.x = width
	ui.add_child(l)
	return l


func _finish_line() -> void:
	for i in 19:
		var square := ColorRect.new()
		square.size = Vector2(8, 4)
		square.position = Vector2(16 + i * 8, _finish_y() - 4.0 + (4.0 if i % 2 == 0 else 0.0))
		square.color = Color.WHITE if i % 2 == 0 else Color(0.1, 0.1, 0.1)
		add_child(square)
	var label := UI.label("FINISH", "Bold")
	label.theme = UI.theme()
	label.position = Vector2(60, _finish_y() - 20.0)
	label.custom_minimum_size.x = 60
	add_child(label)


func _countdown() -> void:
	big.text = "TIME TRIAL"
	await get_tree().create_timer(1.0).timeout
	for n in ["3", "2", "1"]:
		big.text = n
		Global.play_sfx("click", 0.8)
		await get_tree().create_timer(0.6).timeout
	big.text = "GO!"
	Global.play_sfx("pop")
	get_tree().create_timer(0.6).timeout.connect(func(): big.text = "")
 
