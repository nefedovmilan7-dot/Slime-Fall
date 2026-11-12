extends CanvasLayer

var game: Node2D
var root: Control
var you_label: Label
var ai_label: Label
var pips: Label
var pointer: Label
var message: VBoxContainer
var big: Label
var small: Label
var panel_box: CenterContainer
var next_milestone := 50


func setup(g: Node2D) -> void:
	game = g
	root = Control.new()
	root.theme = UI.theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	you_label = _corner(UI.label("", "Bold"), Vector2(22, 6))
	ai_label = _corner(UI.label("", "Bold"), Vector2(112, 6))
	ai_label.modulate = Color(1, 1, 1, 0.75)
	pips = _corner(UI.label("", "Small"), Vector2(60, 18))
	pips.custom_minimum_size.x = 60
	var pause := UI.button("II", func(): game.pause_menu.toggle(), "Gray")
	pause.position = Vector2(2, 2)
	pause.custom_minimum_size = Vector2(16, 14)
	root.add_child(pause)
	pointer = UI.label("", "Small") 
	pointer.custom_minimum_size.x = 60
	root.add_child(pointer)
	# messages in the middle
	message = VBoxContainer.new()
	message.position = Vector2(0, 104)
	message.size = Vector2(180, 40)
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big = UI.label("", "Title")
	small = UI.label("", "Small")
	message.add_child(big)
	message.add_child(small)
	root.add_child(message)
	panel_box = CenterContainer.new()
	panel_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel_box)
	UI.touch_buttons(self)


func _corner(l: Label, pos: Vector2) -> Label:
	l.position = pos
	l.custom_minimum_size.x = 46
	root.add_child(l)
	return l


func _process(_delta: float) -> void:
	if game == null or game.player == null or not is_instance_valid(game.player):
		return
	var you: int = game.meters(game.player)
	you_label.text = "YOU %dM" % you
	if you >= next_milestone and not game.player.dead:
		show_message("%d M!" % next_milestone, "NEW BEST!" if next_milestone > Global.best_height else "KEEP CLIMBING")
		Global.play_sfx("pop", 1.2)
		next_milestone += 50
	ai_label.text = "AI %dM" % game.meters(game.ai)
	pips.text = "%d - %d" % [game.wins["you"], game.wins["ai"]]
	var cam: GameCamera = game.camera
	var ai: Slime = game.ai
	pointer.visible = not ai.dead and (ai.position.y < cam.top_edge() or ai.position.y > cam.bottom_edge())
	if pointer.visible:
		var above := ai.position.y < cam.top_edge()
		pointer.text = ("AI ^ " if above else "AI v ") + "%dM" % game.meters(ai)
		pointer.position = Vector2(clampf(ai.position.x - 30.0, 0.0, 120.0), 30.0 if above else 296.0)


func countdown(round_no: int) -> void:
	next_milestone = 50
	_show("ROUND %d" % round_no, "AI: " + Global.difficulty.to_upper())
	await get_tree().create_timer(1.0).timeout
	for n in ["3", "2", "1"]:
		_show(n, "")
		Global.play_sfx("click", 0.8)
		await get_tree().create_timer(0.6).timeout
	_show("GO!", "")
	Global.play_sfx("pop")
	get_tree().create_timer(0.6).timeout.connect(func(): if big.text == "GO!": _show("", ""))


func show_message(title: String, sub: String) -> void:
	_show(title, sub)
	get_tree().create_timer(1.8).timeout.connect(func(): if big.text == title: _show("", ""))


func _show(title: String, sub: String) -> void:
	big.text = title
	small.text = sub
	message.scale = Vector2(1.3, 1.3)
	message.pivot_offset = Vector2(90, 20)
	create_tween().tween_property(message, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)


func round_result(winner: String, you_m: int, ai_m: int) -> void:
	_show("", "")
	var title: String = {"you": "ROUND WON!", "ai": "ROUND LOST", "draw": "DRAW!"}[winner]
	var p := _panel([UI.label(title, "Title"), UI.label("YOU %dM   AI %dM" % [you_m, ai_m], "Bold")])
	await get_tree().create_timer(2.4).timeout
	p.queue_free()


func match_result(won: bool, reward: int) -> void:
	var items: Array = [UI.label("YOU WIN!" if won else "THE AI WINS", "Title"),
		UI.label("%d - %d" % [game.wins["you"], game.wins["ai"]], "Big")]
	if won:
		items.append(UI.label("+%d COINS" % reward, "Bold"))
	var again := UI.button("REMATCH", func():
		panel_box.get_child(0).queue_free()
		game.rematch())
	items.append(again)
	items.append(UI.button("MENU", func(): Transition.go("res://scenes/main_menu.tscn"), "Gray"))
	_panel(items)


func _panel(items: Array) -> PanelContainer:
	var p := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	for it in items:
		v.add_child(it)
	p.add_child(v)
	panel_box.add_child(p)
	p.pivot_offset = Vector2(60, 40)
	p.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(p, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	return p
