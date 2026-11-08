extends Node

var towers := 12
var rounds := 60
var first_seed := 5000
var sigma := 150.0

const LIMIT := 150.0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		if kv.size() == 2:
			match kv[0]:
				"towers": towers = int(kv[1])
				"rounds": rounds = int(kv[1])
				"seed": first_seed = int(kv[1])
	Global.set_meta("no_save", true)
	Global.sound_on = false
	Global.difficulty = "impossible"
	_train.call_deferred()


func _train() -> void:
	var best: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://ai/brain.json"))
	var best_score := await _score(best)
	print("[train] start: %.1f m" % best_score)
	for r in rounds:
		var child := best.duplicate()
		for k in child: 
			child[k] = child[k] * (1.0 + randfn(0.0, sigma))
		var s := await _score(child)
		if s > best_score:
			best = child
			best_score = s
			sigma = minf(sigma * 1.5, 0.6) 
			var f := FileAccess.open("res://ai/brain.json", FileAccess.WRITE)
			f.store_string(JSON.stringify(best, "\t"))
			f.close()
			print("[train] round %d: NEW BEST %.1f m (saved)" % [r + 1, s])
		else:
			sigma = maxf(sigma * 0.85, 0.03) 
			print("[train] round %d: %.1f m (best %.1f)" % [r + 1, s, best_score])
	print("[train] done. Best: %.1f m" % best_score)
	get_tree().quit()

func _score(brain: Dictionary) -> float:
	var total := 0.0
	for i in towers:
		seed(first_seed + i)
		var game: Node2D = load("res://scenes/game.tscn").instantiate()
		get_tree().root.add_child(game)
		while game.state != game.State.RACING:
			await get_tree().process_frame
		game.set_process(false)
		game.bot.brain = brain.duplicate()
		game.player.die()
		var t := 0.0
		while not game.ai.dead and t < LIMIT:
			await get_tree().physics_frame
			t += 1.0 / 60.0
		print("[train] tower %d height: %.1f m" % [i + 1, game.meters(game.ai)])
		total += game.meters(game.ai) + (25.0 if not game.ai.dead else 0.0)
		game.queue_free()
		await get_tree().process_frame
	return total / towers
