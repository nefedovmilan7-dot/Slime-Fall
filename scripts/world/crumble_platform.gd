@tool
extends StaticBody2D

@export var width := 40.0:
	set(value):
		width = value
		if is_node_ready():
			_apply_width()

const RESPAWN_TIME := 1.5

var triggered := false
var _home_y := 0.0


func _ready() -> void:
	_apply_width()
	_home_y = position.y
	if not Engine.is_editor_hint():
		$Detector.body_entered.connect(_on_detector_body_entered)


func _on_detector_body_entered(body: Node2D) -> void:
	if triggered or not body is CharacterBody2D:
		return
	if body.velocity.y < 0.0:
		return
	
	triggered = true
	Global.play_sfx("crumble")
	
	var tween := create_tween()
	for i in 6:
		tween.tween_property($Look, "position:x", -width / 2.0 + (1 if i % 2 == 0 else -1), 0.06)
	
	tween.tween_callback(_fall)


func _apply_width() -> void:
	$Look.size = Vector2(width, 12)
	$Look.position = Vector2(-width / 2.0, 0)
	
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 6)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = Vector2(0, 3)
	
	var sensor := RectangleShape2D.new()
	sensor.size = Vector2(width - 4, 4)
	$Detector/CollisionShape2D.shape = sensor
	$Detector/CollisionShape2D.position = Vector2(0, -2)


func _fall() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", _home_y + 60.0, 0.6).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	
	tween.set_parallel(false)
	tween.tween_interval(RESPAWN_TIME)
	tween.tween_callback(_come_back)


func _come_back() -> void:
	position.y = _home_y
	$Look.position.x = -width / 2.0
	
	$CollisionShape2D.set_deferred("disabled", false)
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_callback(func(): triggered = false)
