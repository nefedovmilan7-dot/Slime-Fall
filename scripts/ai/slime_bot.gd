class_name SlimeBot
extends Node

const SKILLS := {
	"easy": {"hesitate": Vector2(1.1, 1.9), "mistake": 0.3, "slip": 18.0, "senses": 0.55},
	"medium": {"hesitate": Vector2(0.6, 1.1), "mistake": 0.15, "slip": 10.0, "senses": 0.75},
	"hard": {"hesitate": Vector2(0.3, 0.6), "mistake": 0.06, "slip": 5.0, "senses": 0.85},
	"impossible": {"hesitate": Vector2.ZERO, "mistake": 0.0, "slip": 0.0, "senses": 1.0},
}

const BRAIN_PATH := "res://ai/brain.json"
const SPEED := 95.0
const AIR_ACCEL := 650.0
const GROUND_ACCEL := 900.0
const JUMP_V := 330.0
const GRAVITY := 900.0
const HALF := 7.0

## how much it likes it :/

var brain := {
	"height": 1.0,
	"distance": 0.12,
	"room": 0.35,
	"crumble": 18.0,
	"moving": 8.0,
	"spring": 40.0,
	"margin": 4.0,
	"rock_radius": 15.0,
	"edge": 5.0,
	"dead_end": 30.0,
}

var me: Slime
var gen: Node2D
var skill: Dictionary = SKILLS["impossible"]
var target: Node2D
var target_x := 0.0
var jumps := 0
var _holding := false
var _wait := 0.0
var _slip := 0.0
var _sees_danger := true
var _stuck := 0.0
var _waiting_on_purpose := false
var _avoid: Node2D = null
var _avoid_time := 0.0
var _was_floor := true

func setup(slime: Slime, level: Node2D, difficulty: String) -> void:
	me = slime
	gen = level
	skill = SKILLS[difficulty]
	load_brain()

func load_brain(path := BRAIN_PATH) -> void:
	if FileAccess.file_exists(path):
		var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
		if saved is Dictionary:
			for k in saved:
				brain[k] = float(saved[k])

func _physics_process(delta: float) -> void:
	if me == null or me.dead:
		return
	var on_floor: bool = me.is_on_floor()
	if on_floor and not _was_floor:
		target = null
		_wait = randf_range(skill["hesitate"].x, skill["hesitate"].y)
	_was_floor = on_floor
	if target and not is_instance_valid(target):
		target = null
	if target == null or not _still_reachable():
		_choose_target()
	var move := 0.0
	var jump := false
	_waiting_on_purpose = false
	if target == null:
		
		var here := _platform_under()
		move = _steer(here.global_position.x if here else me.global_position.x)
	elif on_floor:
		var standing := _platform_under()
		if standing and _spring_on(standing) and not _rock_near(_spring_x(standing), 0.0) \
				and not _path_hits_from(Vector2(_spring_x(standing), me.global_position.y), 0.0, _spring_x(standing), -560.0):
			move = _steer(_spring_x(standing)) 
		else:
			var land := _landing_x()
			var crumbling: bool = standing != null and standing.get("triggered") == true
			var ready_to_jump := crumbling or _can_jump_to(land, _top(target), 0.0)
			_wait = 0.0 if crumbling else _wait - delta
			if ready_to_jump and _wait > 0.0:
				move = 0.0
				_waiting_on_purpose = true
			elif ready_to_jump and not _path_hits_rock(land, -JUMP_V):
				jump = true
				move = _steer(land)
			elif ready_to_jump:
				move = _steer(_safe_x(standing, me.global_position.x)) if standing else 0.0
				_waiting_on_purpose = true
			else:
				move = _steer(_takeoff_x(standing, land))
	else:
		move = _steer(_landing_x())
		if _path_hits_rock(_landing_x(), me.velocity.y, true):
			var h := _nearest_hazard()
			if h != Vector2.INF:
				move = 1.0 if me.global_position.x > h.x else -1.0
		jump = _holding and me.velocity.y < 0.0 
	var dodge: Array = _dodge_rocks(move)
	move = dodge[0]
	if dodge[1]:
		jump = true
	_avoid_time = maxf(_avoid_time - delta, 0.0)
	if on_floor and target and not jump and absf(me.velocity.x) < 1.0 and not _waiting_on_purpose:
		_stuck += delta
		if _stuck > 1.0:
			_avoid = target
			_avoid_time = 2.0
			target = null
			_stuck = 0.0
	else:
		_stuck = 0.0
	_press(move, jump)

func _platforms(include_crumbling := false) -> Array:
	var out := []
	for c in gen.get_children():
		if (c is StaticBody2D or c is AnimatableBody2D) and "width" in c:
			if c.get("triggered") == true and not include_crumbling:
				continue 
			out.append(c)
	return out

func _top(p: Node2D) -> float:
	return p.global_position.y

func _choose_target() -> void:
	var best: Node2D = null
	var best_score := -INF
	var feet: float = me.global_position.y
	for p in _platforms():
		var top := _top(p)
		if top > feet - 4.0 or (p == _avoid and _avoid_time > 0.0):
			continue  
		var lx := _landing_x_for(p)
		if not _can_jump_to(lx, top, brain["margin"]) and not _reachable_by_walking(lx, top):
			continue
		var s: float = (feet - top) * brain["height"]
		s -= absf(lx - me.global_position.x) * brain["distance"]
		s += p.width * brain["room"]
		if p.has_method("_on_detector_body_entered"):
			s -= brain["crumble"]
		if p is AnimatableBody2D:
			s -= brain["moving"]
		if _spring_on(p):
			s += brain["spring"]
		if _rock_near(lx, 0.0):
			s -= 60.0
		if not _has_next(p):
			s -= brain["dead_end"] 
		if s > best_score:
			best_score = s
			best = p
	var options: Array = _reachable_now()
	if options.size() > 1 and randf() < skill["mistake"]:
		best = options.pick_random() 
	target = best
	_slip = randf_range(-skill["slip"], skill["slip"])
	_sees_danger = randf() < skill["senses"]
	if target:
		target_x = _landing_x_for(target)

func _reachable_now() -> Array:
	var out := []
	var feet: float = me.global_position.y
	for p in _platforms():
		var top := _top(p)
		if top < feet - 4.0 and (_can_jump_to(_landing_x_for(p), top, brain["margin"]) or _reachable_by_walking(_landing_x_for(p), top)):
			out.append(p)
	return out

func _still_reachable() -> bool:
	if me.is_on_floor():
		return true
	return _can_jump_to(_landing_x(), _top(target), 0.0, true)

func _landing_x_for(p: Node2D) -> float:
	var x: float = p.global_position.x
	if p.has_method("_on_detector_body_entered"):
		var nxt := _next_of(p)
		if nxt: 
			var half_c: float = p.width / 2.0 - HALF * 0.5
			var t_c := _flight_time(me.global_position.y - _top(p), -JUMP_V)
			var reach: float = SPEED * maxf(t_c - 0.06, 0.0) + HALF - brain["margin"] if t_c > 0.0 else 0.0
			var lo: float = maxf(p.global_position.x - half_c, me.global_position.x - reach)
			var hi: float = minf(p.global_position.x + half_c, me.global_position.x + reach)
			if lo <= hi:
				return clampf(nxt.global_position.x, lo, hi)
	var half: float = p.width / 2.0 - brain["edge"] - HALF * 0.5
	for c in p.get_children():
		if c.scene_file_path.ends_with("spikes.tscn"):
			var sx: float = c.global_position.x
			x = p.global_position.x - signf(sx - p.global_position.x) * p.width / 4.0   # the other half
	if p is AnimatableBody2D:   # it moves: where will it be when we land?
		var t := _flight_time(me.global_position.y - _top(p), -JUMP_V)
		x += p.center_x + sin(p.t + p.speed * t) * p.distance - p.global_position.x
		half = maxf(half, 2.0)
		return clampf(x, p.center_x + sin(p.t + p.speed * t) * p.distance - half,
			p.center_x + sin(p.t + p.speed * t) * p.distance + half)
	x = clampf(x, p.global_position.x - maxf(half, 1.0), p.global_position.x + maxf(half, 1.0))
	return _safe_x(p, x) if p.width > 20.0 else x

func _landing_x() -> float:
	return _landing_x_for(target) + _slip if target else me.global_position.x

func _flight_time(dy: float, vy: float) -> float:
	var g: float = GRAVITY * me.gravity_scale
	var up := -vy
	var disc := up * up - 2.0 * g * dy
	if disc < 0.0:
		return -1.0
	return (up + sqrt(disc)) / g

func _can_jump_to(x: float, top: float, margin: float, in_air := false) -> bool:
	var dy: float = me.global_position.y - top
	var vy: float = me.velocity.y if in_air else -JUMP_V
	var t := _flight_time(dy, vy)
	if t < 0.0:
		return false
	var dist: float = absf(x - me.global_position.x)
	var reach: float = SPEED * maxf(t - 0.06, 0.0) + me.wind * t * signf(x - me.global_position.x)
	return dist <= reach + HALF - margin

func _reachable_by_walking(_x: float, top: float) -> bool:
	return me.is_on_floor() and _flight_time(me.global_position.y - top, -JUMP_V) > 0.0

func _takeoff_x(standing: Node2D, land: float) -> float:
	if standing == null:
		return land
	return _safe_x(standing, land)

func _safe_x(p: Node2D, want: float) -> float:
	var c: float = p.global_position.x
	var half: float = p.width / 2.0 - HALF + 1.0
	var best := c
	var best_d := INF
	var x := c - half
	while x <= c + half:
		var ok := not _rock_near(x, 0.0)
		for s in p.get_children():
			if s.scene_file_path.ends_with("spikes.tscn") and absf(s.global_position.x - x) < 15.0:
				ok = false
		if ok and absf(x - want) < best_d:
			best_d = absf(x - want)
			best = x
		x += 2.0
	return best

func _platform_under() -> Node2D:
	var x: float = me.global_position.x
	var y: float = me.global_position.y
	for p in _platforms(true):
		if absf(_top(p) - y) < 3.0 and absf(p.global_position.x - x) <= p.width / 2.0 + HALF:
			return p
	return null

func _next_of(p: Node2D) -> Node2D:
	var best: Node2D = null
	for q in _platforms():
		if q == p or q.has_method("_on_detector_body_entered"):
			continue
		var dy := _top(p) - _top(q)
		if dy > 4.0 and dy < 56.0:
			if best == null or absf(q.global_position.x - p.global_position.x) < absf(best.global_position.x - p.global_position.x):
				best = q
	return best

func _has_next(p: Node2D) -> bool:
	for q in _platforms():
		if q == p or q.has_method("_on_detector_body_entered"):
			continue
		var dy := _top(p) - _top(q)
		if dy > 4.0 and dy < 56.0:
			var gap: float = absf(q.global_position.x - p.global_position.x) - (q.width + p.width) / 2.0
			if gap < 40.0:
				return true
	return _top(p) < me.global_position.y - 150.0

func _steer(x: float) -> float:
	var vx: float = me.velocity.x
	var accel := GROUND_ACCEL if me.is_on_floor() else AIR_ACCEL
	if me.is_on_floor():
		var under := _platform_under()
		if under and under.has_meta("ice"):
			accel = GROUND_ACCEL * 0.18
	var stopping := vx * absf(vx) / (2.0 * accel)
	var dx: float = x - (me.global_position.x + stopping)
	if absf(dx) < 1.5:
		return 0.0
	return signf(dx)

func _press(move: float, jump: bool) -> void:
	me.ai_move = move
	if jump and _holding and me.is_on_floor() and me.velocity.y >= 0.0:
		jump = false
	if jump and not _holding:
		jumps += 1
	_holding = jump
	me.ai_jump = jump

func _rocks() -> Array:
	var out := []
	for c in gen.get_children():
		if c.scene_file_path.ends_with("rock.tscn"):
			out.append(c)
	return out

func _path_hits_rock(x: float, vy: float, in_air := false) -> bool:
	var land_y: float = _top(target) if target and is_instance_valid(target) else INF
	return _path_hits_from(me.global_position, me.velocity.x, x, vy, in_air, land_y)

func _path_hits_from(start: Vector2, start_vx: float, x: float, vy: float, in_air := false, land_y := INF) -> bool:
	if not _sees_danger:
		return false 
	var rocks := _rocks()
	var spikes := _spikes()
	if rocks.is_empty() and spikes.is_empty():
		return false
	var g: float = GRAVITY * me.gravity_scale
	var px: float = start.x
	var py: float = start.y
	var vx: float = start_vx
	var v := vy
	var t := 0.0
	while t < 1.2:
		t += 1.0 / 30.0
		vx = move_toward(vx, signf(x - px) * SPEED if absf(x - px) > 2.0 else 0.0, AIR_ACCEL / 30.0)
		px += vx / 30.0
		v = minf(v + g / 30.0, 420.0)
		py += v / 30.0
		if not in_air and t > 0.05 and v > 0.0 and py > start.y:
			break 
		if v > 0.0 and py >= land_y and absf(px - x) < 20.0:
			break 
		for sp in spikes: 
			if absf(sp.x - px) < 13.0 and absf(sp.y - (py - 7.0)) < 10.0:
				return true
		for r in rocks:
			var ry: float
			if r.falling:
				ry = r.global_position.y + r.fall_speed * t
			elif t > r.warn_time:
				ry = r.global_position.y + r.fall_speed * (t - r.warn_time)
			else:
				ry = r.global_position.y
			if absf(r.global_position.x - px) < 13.0 and absf(ry - (py - 7.0)) < 16.0:
				return true
	return false

func _spikes() -> Array:
	var out := []
	for p in _platforms(true):
		for c in p.get_children():
			if c.scene_file_path.ends_with("spikes.tscn"):
				out.append(c.global_position)
	return out

func _nearest_hazard() -> Vector2:
	var best := Vector2.INF
	var here: Vector2 = me.global_position
	for r in _rocks():
		if r.global_position.distance_to(here) < best.distance_to(here):
			best = r.global_position
	for sp in _spikes():
		if sp.distance_to(here) < best.distance_to(here):
			best = sp
	return best

func _nearest_rock() -> Node2D:
	var best: Node2D = null
	for r in _rocks():
		if best == null or r.global_position.distance_to(me.global_position) < best.global_position.distance_to(me.global_position):
			best = r
	return best

func _rock_near(x: float, _t: float) -> bool:
	for r in _rocks():
		if r.global_position.y < me.global_position.y + 8.0 and absf(r.global_position.x - x) < brain["rock_radius"]:
			return true
	return false

func _dodge_rocks(move: float) -> Array:
	if not _sees_danger or not me.is_on_floor() or not _rock_near(me.global_position.x, 0.0):
		return [move, false]
	var here := _platform_under()
	if here == null:
		return [move, false]
	if here is AnimatableBody2D:
		return [move, true] 
	var safe := _safe_x(here, me.global_position.x)
	if _rock_near(safe, 0.0):
		return [move, true] 
	return [_steer(safe), false]

func _spring_on(p: Node2D) -> bool:
	for c in p.get_children():
		if c.scene_file_path.ends_with("spring.tscn"):
			return true
	return false

func _spring_x(p: Node2D) -> float:
	for c in p.get_children():
		if c.scene_file_path.ends_with("spring.tscn"):
			return c.global_position.x
	return p.global_position.x
