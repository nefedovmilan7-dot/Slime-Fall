extends Area2D

const POWER := 560.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D or not body.has_method("bounce"):
		return
	if body.velocity.y < 0.0:
		return
	body.bounce(POWER)
	$Sprite2D.texture = preload("res://art/ui/spring_down.png")
	await get_tree().create_timer(0.15).timeout
	$Sprite2D.texture = preload("res://art/ui/spring.png")
