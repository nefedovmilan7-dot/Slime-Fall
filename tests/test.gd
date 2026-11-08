extends Node

var fails := 0

func _check(ok: bool, what: String) -> void:
	print(("[ok]   " if ok else "[FAIL] ") + what)
	if not ok:
		fails += 1

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _ready() -> void:
	Global.set_meta("no_save", true)
	Global.sound_on = false
	Global.coins = 100
	Global.owned = ["hat:none", "color:green"]
	Global.equipped = {"hat": "none", "color": "green"}
	_run.call_deferred()

func _run() -> void:
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	await _wait(0.3)
	var buttons := menu.find_children("*", "Button", true, false).map(func(b): return b.text)
	_check("PLAY" in buttons and "SHOP" in buttons, "home: PLAY and SHOP")
	_check(not buttons.any(func(t): return t in ["QUESTS", "MISSIONS", "RANKS"]), "home: no quests or other modes")
	menu._open_modes()
	await _wait(0.2)
	var grid: GridContainer = menu.find_children("*", "GridContainer", true, false)[0]
	var cards := grid.get_children()
	_check(grid.columns == 2 and cards.size() == 4, "PLAY opens AI MODE: 4 rival cards in a 2 x 2 grid")
	_check(cards.all(func(c): return absf(c.size.x - c.size.y) < 1.0), "...and every card is square")
	_check(Global.buy("hat", "party_hat") and Global.coins == 60 and Global.equipped["hat"] == "party_hat", "shop: bought and wearing a party hat")
	_check(not Global.buy("hat", "crown"), "shop: can't buy what you can't afford")
	Global.equip("hat", "none")
	menu.queue_free()
	Global.difficulty = "impossible"
	var game: Node2D = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child(game)
	await _wait(0.2)
	_check(game.state == game.State.COUNTDOWN and game.player and game.ai and game.ai.is_ai, "round 1: you and the AI on the start line")
	_check(game.ai.modulate.a < 0.6 and game.ai.collision_layer == 4, "the AI is see-through and on its own layer")
	while game.state != game.State.RACING:
		await get_tree().process_frame
	await _wait(10.0)
	_check(game.meters(game.ai) > 15, "the AI climbs by itself (%d m in 10 s)" % game.meters(game.ai))
	_check(game.player.position.distance_to(game.ai.position) > 0.0 and not game.player.dead, "you and the AI don't bump into each other")
	game.player.die()
	await _wait(0.6)
	_check(game.camera.target == game.ai, "you died: the camera follows the AI")
	await _wait(0.5)
	_check(game.ai.modulate.a > 0.95, "...and the AI is solid now")
	await _wait(0.5)
	_check(game.state == game.State.ROUND_OVER and game.wins["ai"] == 1, "the AI is higher, so it wins the round straight away")
	while game.state != game.State.RACING:
		await get_tree().process_frame
	_check(game.round_no == 2 and game.meters(game.player) == 0, "round 2: a new tower")
	game.ai.die()
	game.player.position.y -= 40.0
	game.player.best_y = game.player.position.y
	await _wait(0.5)
	_check(game.wins["you"] == 1, "the AI melted and you're higher: your round")
	while game.state != game.State.RACING:
		await get_tree().process_frame
	var coins_before := Global.coins
	game.ai.die()
	game.player.position.y -= 40.0
	game.player.best_y = game.player.position.y
	await _wait(3.2)
	_check(game.state == game.State.MATCH_OVER and Global.coins == coins_before + 200, "you won the match 2-1: +200 coins (impossible)")
	game.queue_free()
	await _wait(0.2)
	print("[done] %d problems" % fails)
	get_tree().quit()
