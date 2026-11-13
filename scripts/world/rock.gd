extends Area2D

@export var fall_speed := 190.0
var camera: GameCamera
var warn_time := 0.9
var falling := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Sprite2D.visible = false


func _process(delta: float) -> void:
	if not falling:
		warn_time -= delta
		position.y = camera.top_edge() + 10.0
		$Warning.visible = int(warn_time * 10.0) % 2 == 0
		if warn_time <= 0.0:
			falling = true
			$Warning.visible = false
			$Sprite2D.visible = true
			Global.play_sfx("rock")
	else:
		position.y += fall_speed * delta
		if position.y > camera.bottom_edge() + 40.0:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if falling and body.has_method("die"):
		body.die()
