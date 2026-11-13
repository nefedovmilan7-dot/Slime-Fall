class_name GameCamera
extends Camera2D

@export var target: Node2D
@export var follow_offset := 40.0

var shake_strength := 0.0

func _process(delta: float) -> void:
	if target:
		var wanted := target.position.y + follow_offset
		if wanted < position.y:
			position.y = lerpf(position.y, wanted, 1.0 - exp(-8.0 * delta))
	if shake_strength > 0.0:
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength
		shake_strength = move_toward(shake_strength, 0.0, 20.0 * delta)
	else:
		offset = Vector2.ZERO


func shake(amount: float) -> void:
	if Global.shake_on:
		shake_strength = amount

func top_edge() -> float:
	return position.y - get_viewport_rect().size.y / 2.0

func bottom_edge() -> float:
	return position.y + get_viewport_rect().size.y / 2.0
