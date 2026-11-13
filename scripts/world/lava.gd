extends Area2D

@export var camera: GameCamera
@export var start_delay := 3.0
@export var start_speed := 8.0
@export var acceleration := 0.3
@export var max_speed := 60.0
@export var catch_up_distance := 100.0
@export var width := 180.0

var speed := 0.0
var time := 0.0

@onready var surface: Sprite2D = $Surface

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Body.region_rect.size.x = width + 16.0
	surface.region_rect.size.x = width + 16.0
	var shape: RectangleShape2D = $CollisionShape2D.shape.duplicate()
	shape.size.x = width
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position.x = width / 2.0
	$Glow.position.x = width / 2.0
	$Embers.position.x = width / 2.0
	$Embers.process_material.emission_box_extents.x = width / 2.0


func reset(y: float) -> void:
	position.y = y
	time = 0.0
	speed = 0.0


func _physics_process(delta: float) -> void:
	time += delta
	var frame := int(time * 6.0) % 4
	surface.region_rect.position = Vector2(fmod(time * 10.0, 32.0), frame * 12)
	$Body.region_rect.position = Vector2(fmod(time * 4.0, 32.0), fmod(time * 12.0, 32.0))
	if time < start_delay:
		return
	for body in get_overlapping_bodies():
		if body.has_method("die") and not body.dead:
			body.die()
	speed = minf(start_speed + acceleration * (time - start_delay), max_speed)
	var current := speed
	if camera and position.y > camera.bottom_edge() + catch_up_distance:
		current = maxf(speed, 160.0)
	position.y -= current * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
