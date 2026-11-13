extends Node2D

const SLIME := preload("res://scenes/slime.tscn")
const BEST_LINE := preload("res://scripts/world/best_line.gd")
const WINS_NEEDED := 2
const START_Y := 300.0
const PIXELS_PER_METER := 16.0

enum State { COUNTDOWN, RACING, ROUND_OVER, MATCH_OVER }

var state := State.COUNTDOWN
var round_no := 0
var wins := {"you": 0, "ai": 0}
var player: Slime
var ai: Slime
var bot: NeuralBot
var pause_menu: PauseMenu

@onready var camera: GameCamera = $GameCamera
@onready var level: Node2D = $LevelGenerator
@onready var lava: Area2D = $Lava
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	Global.play_music("music_game")
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	hud.setup(self)
	if Global.best_height > 0:
		var line: Node2D = BEST_LINE.new()
		line.meters = Global.best_height
		line.position.y = START_Y - Global.best_height * PIXELS_PER_METER
		add_child(line)
	start_round()

func start_round() -> void:
	round_no += 1
	state = State.COUNTDOWN
	for old in [player, ai, bot]:
		if is_instance_valid(old):
			old.queue_free()
	level.build(randi())
	lava.reset(START_Y + 60.0)
	camera.position.y = START_Y - 40.0
	player = SLIME.instantiate()
	player.position = Vector2(70, START_Y)
	add_child(player)
	player.dress(Global.equipped["hat"], Global.equipped["color"], Global.equipped.get("trail", "none"))
	player.died.connect(_on_player_died)
	ai = SLIME.instantiate()
	ai.is_ai = true
	ai.position = Vector2(110, START_Y)
	ai.collision_layer = 4
	add_child(ai)
	ai.dress(Rivals.hat(Global.difficulty), Rivals.color(Global.difficulty))
	ai.modulate.a = 0.45
	ai.died.connect(_on_ai_died)
	bot = NeuralBot.new()
	add_child(bot)
	bot.setup(ai, level, lava, Global.difficulty)
	hud.show_brain(bot.net)
	level.slimes = [player, ai]
	camera.target = player
	for s in [player, ai]:
		s.set_physics_process(false)
	bot.set_physics_process(false)
	lava.set_physics_process(false)
	await hud.countdown(round_no)
	for s in [player, ai]:
		s.set_physics_process(true)
	bot.set_physics_process(true)
	lava.set_physics_process(true)
	state = State.RACING

func meters(s: Slime) -> int:
	return maxi(0, int((START_Y - s.best_y) / PIXELS_PER_METER))

func _process(_delta: float) -> void:
	if state != State.RACING:
		return
	if player.dead and ai.dead:
		_end_round("you" if meters(player) > meters(ai) else ("ai" if meters(ai) > meters(player) else "draw"))
	elif player.dead and meters(ai) > meters(player):
		_end_round("ai")
	elif ai.dead and meters(player) > meters(ai):
		_end_round("you")

func _on_player_died() -> void:
	camera.shake(3.0)
	_slow_motion()
	if not ai.dead and state == State.RACING:
		camera.target = ai 
		ai.set_ghost(false) 
		hud.show_message("YOU MELTED", "WATCHING THE AI...")

func _on_ai_died() -> void:
	if not player.dead and state == State.RACING:
		hud.show_message("THE AI MELTED!", "CLIMB PAST %d M TO WIN" % meters(ai))

func _slow_motion() -> void:
	Engine.time_scale = 0.35
	await get_tree().create_timer(0.6, true, false, true).timeout
	Engine.time_scale = 1.0

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _end_round(winner: String) -> void:
	state = State.ROUND_OVER
	Global.record_height(meters(player))
	if winner != "draw":
		wins[winner] += 1
	bot.set_physics_process(false)
	Global.play_sfx("best" if winner == "you" else "die", 1.0 if winner == "you" else 0.8)
	await hud.round_result(winner, meters(player), meters(ai))
	if wins["you"] >= WINS_NEEDED or wins["ai"] >= WINS_NEEDED:
		_end_match()
	else:
		start_round()

func _end_match() -> void:
	state = State.MATCH_OVER
	var won: bool = wins["you"] >= WINS_NEEDED
	var reward: int = Rivals.reward(Global.difficulty) if won else 0
	if won:
		Global.matches_won += 1
		Global.add_coins(reward)
		Global.play_sfx("medal")
	hud.match_result(won, reward)

func rematch() -> void:
	wins = {"you": 0, "ai": 0}
	round_no = 0
	start_round()
