@tool
extends AnimatableBody2D

@export var width := 40.0:
	set(value):
		width = value
		if is_node_ready():
			_apply_width()


@export var distance := 40.0
@export var speed := 1.2

var center_x := 0.0
var t := 0.0

func _ready() -> void:
	_apply_width()
	center_x = position.x
	t = randf() * TAU

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	t += delta * speed
	position.x = center_x + sin(t) * distance


func _apply_width() -> void:
	$Look.size = Vector2(width, 12)
	$Look.position = Vector2(-width / 2.0, 0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 6)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.postion = Vector2(0, 3)
