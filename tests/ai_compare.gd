extends Node

const LEVELS := 3
const LIMIT := 90.0
var only := OS.get_environment("ONLY")
var levels := int(OS.get_environment("LEVELS")) if OS.get_environment("LEVELS") != "" else LEVELS
var limit := float(OS.get_environment("LIMIT")) if OS.get_environment("LIMIT") != "" else LIMIT

func _ready() -> void:
	Global.set_meta("no_save", true)
	Global.sound_on = false
	_run.call_deferred()

func _run() -> void:
	for d in ["easy", "medium", "hard", "impossible"]:
		if only != "" and d != only:
			continue
		var total := 0
		var heights := []
		for i in levels:
			Global.difficulty = d
			seed(1000 + i)
			var game: Node2D = load("res://scenes/game.tscn").instantiate()
			get_tree().root.add_child(game)
			while game.state != game.State.RACING:
				await get_tree().process_frame
			game.set_process(false)
			game.player.die()
			var t := 0.0
			while not game.ai.dead and t < limit:
				await get_tree().physics_frame
				t += 1.0 / 60.0
			heights.append(game.meters(game.ai))
			if OS.get_environment("WHY") != "":
				var a: Slime = game.ai
				var why := "alive"
				if a.dead:
					why = "lava" if game.lava.position.y < a.position.y + 12.0 else "hazard"
				print("    tower %d: %d m in %.0f s (%.1f m/s), %s, lava speed %.0f" % [i + 1, game.meters(a), t, game.meters(a) / maxf(t, 1.0), why, game.lava.speed])
			total += game.meters(game.ai)
			game.queue_free()
			await get_tree().process_frame
		print("[ai] %-10s average %3d m   %s" % [d.to_upper(), total / levels, str(heights)])
	get_tree().quit()
