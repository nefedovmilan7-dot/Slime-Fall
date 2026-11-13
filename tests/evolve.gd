extends Node
## EVOLUTION: trains the neural AI without leaving Godot.
## Open tests/evolve.tscn and press F6 (Run Current Scene). Close it whenever
## you like: the best brain so far is already saved in res://ai/neural.json,
## and the game uses it. (Your old brain is backed up to ai/neural_backup.json.)
##
## A brain is only saved if it passes the EXAM better than any brain before:
## it climbs the same 3 exam towers alone. So training can never make your AI worse.
##
## Every generation, `population` slimes with slightly different brains climb
## the same tower at the same time. The best few survive unchanged; everyone
## else is replaced by copies of the best ones with small random changes
## ("mutations"). Repeat: the brains slowly get better.

@export var population := 500          # slimes per generation
@export var speed := 20.0              # how many times faster than normal (your computer limits it)
@export var think_every := 2           # brains decide every Nth frame (2 = the same as Impossible in the game)
@export var exam_towers := 3           # the fixed towers every champion is tested on
@export var generation_seconds := 90.0 # game time before a generation is stopped
@export var elite_share := 0.1         # the best 10% go on unchanged
@export var parent_share := 0.2        # the children come from the best 20%
@export var mutation_rate := 0.05      # chance that each number in a brain changes
@export var mutation_size := 0.08      # how much it changes (small: fine-tuning a trained brain)

const SLIME := preload("res://scenes/slime.tscn")

var generation := 0
var best_ever := 0
var best_exam := -1.0   # the exam score of the brain in neural.json
var brains: Array[NeuralNet] = []
var game: Node2D
var slimes: Array[Slime] = []
var bots: Array[NeuralBot] = []
var view: NeuralView
var info: Label
var _real_start := 0
var _game_time := 0.0
var _last_speed := 0.0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():   # optional, from a terminal: -- population=100 speed=40
		var kv := arg.split("=")
		if kv.size() == 2 and kv[0] in ["population", "speed", "think_every"]:
			set(kv[0], int(kv[1]) if kv[0] != "speed" else float(kv[1]))
	Global.set_meta("no_save", true)   # training never touches your save file
	Global.sound_on = false
	Global.music.stop()
	_backup_brain()
	_first_brains()
	_build_screen()
	_run.call_deferred()


func _exit_tree() -> void:
	_set_speed(1.0)


## Fast-forward without breaking the physics: more physics steps per second,
## each still exactly 1/60 s long. (time_scale alone would make every step
## longer, and slimes would skip straight through platforms.)
func _set_speed(x: float) -> void:
	Engine.time_scale = x
	Engine.physics_ticks_per_second = int(60.0 * x)
	Engine.max_physics_steps_per_frame = maxi(8, int(x) * 2 + 4)


func _backup_brain() -> void:
	if FileAccess.file_exists(NeuralBot.BRAIN_PATH) and not FileAccess.file_exists("res://ai/neural_backup.json"):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(NeuralBot.BRAIN_PATH), ProjectSettings.globalize_path("res://ai/neural_backup.json"))


## Generation 1: the saved brain plus mutated copies of it (or random brains).
func _first_brains() -> void:
	var start := NeuralNet.load_file(NeuralBot.BRAIN_PATH)
	for i in population:
		if start == null:
			brains.append(NeuralNet.new(NeuralBot.LAYERS))
		else:
			var b := start.copy()
			if i > 0:
				b.mutate(mutation_rate, mutation_size)
			brains.append(b)


func _run() -> void:
	best_exam = await _exam(brains[0])   # how good the saved brain is now
	print("[evolve] the saved brain scores %.1f m on the exam" % best_exam)
	while true:
		generation += 1
		var heights := await _play_generation()
		await _next_generation(heights)   # wait for the exam too: one tower at a time


## All the brains climb one tower together. Returns each one's height.
func _play_generation() -> Array:
	seed(randi())
	Global.difficulty = "impossible"
	_set_speed(1.0)
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	while game.state != game.State.RACING:   # let the game set up its tower
		await get_tree().process_frame
	game.set_process(false)          # no rounds or winners: we're in charge now
	game.hud.visible = false
	game.hud.set_process(false)
	_park(game.player)   # not deleted: the game still checks on them
	_park(game.ai)
	game.bot.queue_free()
	slimes.clear()
	bots.clear()
	for i in population:
		var s: Slime = SLIME.instantiate()
		s.is_ai = true
		s.collision_layer = 4                 # the AI layer: they never bump into each other
		s.position = Vector2(randf_range(40.0, 140.0), game.START_Y)
		game.add_child(s)
		s.dress("none", "green")
		for c in s.get_children():           # no lights or particles: much faster
			if c is PointLight2D or c is CPUParticles2D:
				c.visible = false
		var bot := NeuralBot.new()
		game.add_child(bot)
		bot.setup(s, game.level, game.lava, "impossible", brains[i])
		bot.think_every = think_every
		slimes.append(s)
		bots.append(bot)
	game.level.slimes = slimes
	_set_speed(speed)
	_real_start = Time.get_ticks_msec()
	_game_time = 0.0
	var best_now := 0
	var last_progress := 0.0
	while _game_time < generation_seconds:
		await get_tree().physics_frame
		_game_time += 1.0 / 60.0
		var leader := _leader()
		if leader == null:
			break                             # everyone melted
		game.camera.target = slimes[leader]
		view.net = bots[leader].net
		var h: int = game.meters(slimes[leader])
		if h > best_now:
			best_now = h
			last_progress = _game_time
		if _game_time - last_progress > 15.0:
			break                             # nobody has climbed for 15 seconds
		_update_info(h)
	_last_speed = _game_time / maxf((Time.get_ticks_msec() - _real_start) / 1000.0, 0.001)
	var heights := []
	for s in slimes:
		heights.append(game.meters(s))
	_set_speed(1.0)
	game.queue_free()
	await get_tree().process_frame
	return heights


## Takes a slime out of play without deleting it: frozen, invisible, untouchable.
func _park(s: Slime) -> void:
	s.set_physics_process(false)
	s.visible = false
	s.collision_layer = 0
	s.collision_mask = 0


func _leader() -> int:
	var best := -1
	for i in slimes.size():
		if not slimes[i].dead and (best == -1 or slimes[i].best_y < slimes[best].best_y):
			best = i
	return best


## Keep the best, fill up with mutated copies of the good ones, save the champion.
func _next_generation(heights: Array) -> void:
	var order := range(population)
	order.sort_custom(func(a, b): return heights[a] > heights[b])
	var champion: int = order[0]
	best_ever = maxi(best_ever, heights[champion])
	print("[evolve] generation %d: best %d m, average %d m, speed x%.1f" % [generation, heights[champion], _average(heights), _last_speed])
	var elites := maxi(1, int(population * elite_share))
	var parents := maxi(elites, int(population * parent_share))
	var next: Array[NeuralNet] = []
	for k in elites:
		next.append(brains[order[k]])        # the best go on unchanged
	while next.size() < population:
		var child: NeuralNet = brains[order[randi() % parents]].copy()
		child.mutate(mutation_rate, mutation_size)
		next.append(child)
	brains = next
	await _check_champion(brains[0])


## The exam: the champion climbs the exam towers alone. Saved only if it beats the record.
func _check_champion(brain: NeuralNet) -> void:
	var score := await _exam(brain)
	if score > best_exam:
		best_exam = score
		brain.save(NeuralBot.BRAIN_PATH)   # the game uses this brain from now on
		print("[evolve]   exam %.1f m: NEW BEST, saved to %s" % [score, NeuralBot.BRAIN_PATH])
	else:
		print("[evolve]   exam %.1f m (best %.1f m): not saved" % [score, best_exam])


func _exam(brain: NeuralNet) -> float:
	var total := 0.0
	for i in exam_towers:
		seed(7000 + i)   # always the same exam towers
		_set_speed(1.0)
		var g: Node2D = load("res://scenes/game.tscn").instantiate()
		add_child(g)
		while g.state != g.State.RACING:
			await get_tree().process_frame
		g.set_process(false)
		g.hud.visible = false
		g.hud.set_process(false)
		_park(g.player)
		g.level.slimes = [g.ai]
		g.camera.target = g.ai
		g.bot.net = brain
		view.net = brain
		_set_speed(speed)
		var t := 0.0
		while not g.ai.dead and t < generation_seconds:
			await get_tree().physics_frame
			t += 1.0 / 60.0
		total += g.meters(g.ai)
		_set_speed(1.0)
		g.queue_free()
		await get_tree().process_frame
	return total / exam_towers


func _average(heights: Array) -> int:
	var total := 0
	for h in heights:
		total += h
	return total / maxi(heights.size(), 1)


# ------------------------------------------------------------------ the screen
func _build_screen() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.theme = UI.theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	info = UI.label("", "Small")
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.position = Vector2(4, 4)
	root.add_child(info)
	view = NeuralView.new()
	view.position = Vector2(180 - 76, 236)
	root.add_child(view)


func _update_info(leader_height: int) -> void:
	var alive := 0
	for s in slimes:
		if not s.dead:
			alive += 1
	var real := (Time.get_ticks_msec() - _real_start) / 1000.0
	info.text = "GEN %d   ALIVE %d/%d\nLEADER %dM   BEST EVER %dM\nSPEED X%.1f" % [generation, alive, population, leader_height, best_ever, _game_time / maxf(real, 0.001)]
