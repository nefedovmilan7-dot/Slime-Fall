class_name Slime
extends CharacterBody2D

signal died

const SPEED := 95.0
const ACCEL_GROUND := 900.0
const ACCEL_AIR := 650.0
const GRAVITY := 900.0
const JUMP_VELOCITY := - 330.0
const MAX_FALL_SPEED := 420.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12

@export var is_ai := false

var ai_move := 0.0
var ai_jump := false
var dead := false
var best_y := 0.0
var gravity_scale := 1.0
var wind = 0.0

var _coyote := 0.0
var _buffer := 0.0
var _jump_was_down := false
var _was_on_floor := true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	best_y = position.y
	sprite.animation_finished.connect(func():
		if sprite.animation == "land":
			sprite.play("idle"))


func dress(hat: String, color: String) -> void:
	sprite.sprite_frames = Global.skin_frames(hat)
	sprite.material = Global.slime_material(color)
	sprite.play("idle")


func set_ghost(on: bool) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.45 if on else 1.0, 0.4)


func _physics_process(delta: float) -> void:
	if dead:
		return
	# 1. read the buttons (the AI's virtual ones, or the real ones)
	var move: float = ai_move if is_ai else Input.get_axis("move_left", "move_right")
	var jump_down: bool = ai_jump if is_ai else Input.is_action_pressed("jump")
	var jump_pressed := jump_down and not _jump_was_down
	var jump_released := _jump_was_down and not jump_down
	_jump_was_down = jump_down
	# 2. gravity, coyote time and the jump buffer
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * gravity_scale * delta, MAX_FALL_SPEED)
	_coyote = COYOTE_TIME if is_on_floor() else _coyote - delta
	_buffer = JUMP_BUFFER if jump_pressed else _buffer - delta
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
		sprite.play("jump")
		if not is_ai:
			Global.play_sfx("jump", randf_range(0.95, 1.05))
	if jump_released and velocity.y < 0.0:
		velocity.y *= 0.45   # let go early = a smaller jump
	# 3. walking, then move
	var accel := ACCEL_GROUND if is_on_floor() else ACCEL_AIR
	velocity.x = move_toward(velocity.x, move * SPEED + wind, accel * delta)
	if move != 0.0:
		sprite.flip_h = move < 0.0
	move_and_slide()
	best_y = minf(best_y, position.y)
	_animate()


func _animate() -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		sprite.play("land")
		if not is_ai:
			Global.play_sfx("land")
	_was_on_floor = on_floor
	if not on_floor and velocity.y > 20.0 and sprite.animation != "fall":
		sprite.play("fall")
	elif on_floor and sprite.animation not in ["land", "idle"]:
		sprite.play("idle")


func bounce(power := 560.0) -> void:
	velocity.y = -power
	_coyote = 0.0
	sprite.play("jump")
	Global.play_sfx("spring")


func die() -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	sprite.play("die")
	Global.play_sfx("die", 1.0 if not is_ai else 1.2)
	died.emit()
