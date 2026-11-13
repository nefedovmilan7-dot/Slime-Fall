class_name Sensors
extends RefCounted

const PLATFORMS := 3
const SIZE := 3 + PLATFORMS * 6 + 1 + 3 + 1

static func read(me: Slime, level: Node2D, lava: Node2D) -> PackedFloat32Array:
	var x := PackedFloat32Array()
	var here: Vector2 = me.global_position
	x.append(me.velocity.x / 95.0)
	x.append(clampf(me.velocity.y / 420.0, -1.0, 1.0))
	x.append(1.0 if me.is_on_floor() else 0.0)
	var platforms := []
	var rock: Node2D = null
	for c in level.get_children():
		if c.scene_file_path.ends_with("rock.tscn"):
			if rock == null or c.global_position.distance_to(here) < rock.global_position.distance_to(here):
				rock = c
		elif "width" in c and c.get("triggered") != true:
			var dy: float = here.y - c.global_position.y
			if dy > -6.0 and dy < 110.0:
				platforms.append(c)
	platforms.sort_custom(func(a, b): return a.global_position.y > b.global_position.y)
	for i in PLATFORMS:
		if i < platforms.size():
			var p: Node2D = platforms[i]
			x.append((p.global_position.x - here.x) / 90.0)
			x.append((here.y - p.global_position.y) / 90.0)
			x.append(p.width / 80.0)
			x.append(1.0 if p is AnimatableBody2D else 0.0)
			x.append(1.0 if p.has_method("_on_detector_body_entered") else 0.0)
			var spikes := 0.0
			for s in p.get_children():
				if s.scene_file_path.ends_with("spikes.tscn"):
					spikes = signf(s.position.x)
			x.append(spikes)
		else:
			x.append_array(PackedFloat32Array([0.0, 1.5, 0.0, 0.0, 0.0, 0.0]))
	x.append(clampf((lava.position.y - here.y) / 300.0, 0.0, 1.0))
	if rock:
		x.append(clampf((rock.global_position.x - here.x) / 90.0, -1.0, 1.0))
		x.append(clampf((here.y - rock.global_position.y) / 200.0, -1.0, 1.0))
		x.append(1.0)
	else:
		x.append_array(PackedFloat32Array([0.0, 0.0, 0.0]))
	x.append((here.x - 90.0) / 74.0)
	return x
