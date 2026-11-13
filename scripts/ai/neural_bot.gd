class_name NeuralBot
extends Node

const BRAIN_PATH := "res://ai/neural.json"
const LAYERS := [Sensors.SIZE, 16, 10, 2]

const SKILLS := {
	"easy": {"hesitate": Vector2(1.0, 1.8), "think": 4, "wrong": 0.2},
	"medium": {"hesitate": Vector2(0.3, 0.6), "think": 3, "wrong": 0.1},
	"hard": {"hesitate": Vector2(0.08, 0.2), "think": 2, "wrong": 0.04},
	"impossible": {"hesitate": Vector2.ZERO, "think": 2, "wrong": 0.0},
}

var me: Slime
var level: Node2D
var lava: Node2D
var net: NeuralNet
var out := PackedFloat32Array([0.0, 0.0])
var think_every := 1
var wrong := 0.0
var hesitate := Vector2.ZERO
var _hesitation := -1.0
var _still := 0.0
var _nudge := 0.0
var _nudge_dir := 1.0
var _frame := 0
var _holding := false


func setup(slime: Slime, lvl: Node2D, lava_node: Node2D, difficulty := "impossible", brain: NeuralNet = null) -> void:
	me = slime
	level = lvl
	lava = lava_node
	var skill: Dictionary = SKILLS.get(difficulty, SKILLS["impossible"])
	think_every = skill["think"]
	wrong = skill["wrong"]
	hesitate = skill["hesitate"]
	net = brain if brain else NeuralNet.load_file(BRAIN_PATH)
	if net == null:
		net = NeuralNet.new(LAYERS)


func _physics_process(delta: float) -> void:
	if me == null or me.dead:
		return
	_frame += 1
	if _frame % think_every == 0:
		out = net.forward(Sensors.read(me, level, lava))
		if wrong > 0.0 and randf() < wrong:
			out[0] = -out[0]
	me.ai_move = 0.0 if absf(out[0]) < 0.3 else signf(out[0])
	var jump := out[1] > 0.0
	if me.is_on_floor() and absf(me.velocity.x) < 1.0 and not jump and _nudge <= 0.0:
		_still += delta
	else:
		_still = 0.0
	if _still > 0.8:
		_still = 0.0
		_nudge = 0.3
		_nudge_dir = -1.0 if randf() < 0.5 else 1.0
	if _nudge > 0.0:
		_nudge -= delta
		me.ai_move = _nudge_dir
		jump = true
	if jump and _holding and me.is_on_floor() and me.velocity.y >= 0.0:
		jump = false
	if jump and not _holding and me.is_on_floor() and hesitate.y > 0.0:
		if _hesitation < 0.0:
			_hesitation = randf_range(hesitate.x, hesitate.y)
		_hesitation -= delta
		if _hesitation > 0.0:
			jump = false
	if not me.is_on_floor():
		_hesitation = -1.0
	_holding = jump
	me.ai_jump = jump
