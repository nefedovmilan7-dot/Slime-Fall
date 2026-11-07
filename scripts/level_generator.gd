extends Node2D

const PLATFORM := preload("res://scenes/platform.tscn")
const MOVING := preload("res://scenes/moving_platform.tscn")
const CRUMBLE := preload("res://scenes/crumble_platform.tscn")
const SPIKES := preload("res://scenes/spikes.tscn")
const ROCK := preload("res://scenes/rock.tscn")
const SPRING := preload("res://scenes/spring.tscn")

const LEFT := 16.0   
const RIGHT := 164.0  
const PIXELS_PER_METER := 16.0
const MOVING_FROM := 60.0  
const CRUMBLE_FROM := 130.0
const SPIKES_FROM := 200.0
const ROCKS_FROM := 220.0
const FULL_DIFFICULTY_AT := 400.0

@export var camera: GameCamera
@export var start_y := 300.0

var slimes: Array = [] 
var next_y := 0.0
var last_x := 90.0
var rock_timer := 4.0
var rng := RandomNumberGenerator.new()


## A new tower for a new round, from a seed.
func build(seed_value: int) -> void:
	for c in get_children():
		c.queue_free()
	rng.seed = seed_value
	seed(seed_value) 
	next_y = start_y
	last_x = 90.0
	rock_timer = 4.0
	for i in 12:
		_spawn_row()


func _process(delta: float) -> void:
	if slimes.is_empty():
		return
	var highest := INF
	for s in slimes:
		highest = minf(highest, s.position.y)
	while next_y > highest - 360.0: 
		_spawn_row()
	var lowest := -INF
	for s in slimes:
		if not s.dead:
			lowest = maxf(lowest, s.position.y)
	for c in get_children():   # tidy up far below everyone
		if c.position.y > lowest + 400.0 and lowest > -INF:
			c.queue_free()
	if meters_at(camera.position.y) > ROCKS_FROM:
		rock_timer -= delta
		if rock_timer <= 0.0:
			rock_timer = rng.randf_range(lerpf(3.5, 1.8, difficulty_at(camera.position.y)), 4.0)
			var r := ROCK.instantiate()
			r.camera = camera
			r.position = Vector2(rng.randf_range(LEFT + 8.0, RIGHT - 8.0), camera.top_edge())
			add_child(r)


func meters_at(y: float) -> float:
	return (start_y - y) / PIXELS_PER_METER


func difficulty_at(y: float) -> float:
	return clampf(meters_at(y) / FULL_DIFFICULTY_AT, 0.0, 1.0)


func _spawn_row() -> void:
	var d := difficulty_at(next_y)
	var m := meters_at(next_y)
	next_y -= rng.randf_range(lerpf(28.0, 38.0, d), lerpf(40.0, 52.0, d))
	var width := snappedf(rng.randf_range(lerpf(56.0, 32.0, d), lerpf(80.0, 48.0, d)), 8.0)
	var step := lerpf(55.0, 75.0, d)
	var x := clampf(last_x + rng.randf_range(-step, step), LEFT + width / 2.0 + 2.0, RIGHT - width / 2.0 - 2.0)
	last_x = x
	# 4. which kind
	var roll := rng.randf()
	var moving_chance := lerpf(0.12, 0.35, d) if m > MOVING_FROM else 0.0
	var crumble_chance := lerpf(0.08, 0.25, d) if m > CRUMBLE_FROM else 0.0
	var p: Node2D
	if roll < moving_chance:
		p = MOVING.instantiate()
		p.width = width
		p.position = Vector2(90.0, next_y)
		p.distance = minf(lerpf(26.0, 46.0, d), (RIGHT - LEFT - width) / 2.0 - 4.0)
		p.speed = lerpf(0.9, 2.0, d)
	elif roll < moving_chance + crumble_chance:
		p = CRUMBLE.instantiate()
		p.width = width
		p.position = Vector2(x, next_y)
	else:
		p = PLATFORM.instantiate()
		p.width = width
		p.position = Vector2(x, next_y)
		var spikes_side := 0.0
		if m > SPIKES_FROM and width >= 40.0 and rng.randf() < lerpf(0.15, 0.35, d):
			var spikes := SPIKES.instantiate()
			spikes_side = 1.0 if rng.randf() < 0.5 else -1.0
			spikes.position = Vector2(spikes_side * (width / 2.0 - 8.0), 0)
			p.add_child(spikes)
		if m > 30.0 and rng.randf() < 0.07:
			var spring := SPRING.instantiate()
			var side := -spikes_side if spikes_side != 0.0 else (1.0 if rng.randf() < 0.5 else -1.0)
			spring.position = Vector2(side * (width / 2.0 - 8.0), 0)
			p.add_child(spring)
	add_child(p)
