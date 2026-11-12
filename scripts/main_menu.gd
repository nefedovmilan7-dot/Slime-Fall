extends Control

var coins_label: Label
var home: VBoxContainer
var shop_layer: Control
var shop_kind := "hat"

static var notice_shown := false


func _ready() -> void:
	theme = UI.theme()
	Global.play_music("music_menu")
	_background()
	_top_bar()
	_home()
	Global.coins_changed.connect(_update_coins)
	_update_coins()
	if not notice_shown:
		notice_shown = true
		_show_notice()


func _background() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://art/world/background.png")
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(0.6, 0.56, 0.75)
	add_child(bg)


func _top_bar() -> void:
	coins_label = UI.label("", "Small")
	coins_label.position = Vector2(110, 6)
	coins_label.custom_minimum_size.x = 64
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(coins_label)
	var sound := UI.button("SOUND" if Global.sound_on else "MUTED", func(): pass, "Gray")
	sound.pressed.connect(func():
		Global.set_sound(not Global.sound_on)
		sound.text = "SOUND" if Global.sound_on else "MUTED")
	sound.position = Vector2(4, 4)
	add_child(sound)


func _update_coins() -> void:
	coins_label.text = "%d COINS" % Global.coins

func _home() -> void:
	home = VBoxContainer.new()
	home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home.offset_top = 40
	home.offset_left = 10
	home.offset_right = -10
	home.add_theme_constant_override("separation", 8)
	add_child(home)
	home.add_child(UI.label("SLIME FALL", "Title"))
	home.add_child(UI.label("RACE AI (it sucks xd)", "Small"))
	var pic := UI.slime_picture(Global.equipped["hat"], Global.equipped["color"], 3)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	home.add_child(pic)
	var bob := pic.create_tween().set_loops()
	bob.tween_property(pic, "position:y", -3.0, 0.6).as_relative().set_trans(Tween.TRANS_SINE)
	bob.tween_property(pic, "position:y", 3.0, 0.6).as_relative().set_trans(Tween.TRANS_SINE)
	var gap := Control.new()
	gap.custom_minimum_size.y = 10
	home.add_child(gap)
	var play := UI.button("PLAY", _open_modes)
	play.custom_minimum_size = Vector2(120, 28)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	home.add_child(play)
	play.grab_focus()
	var shop := UI.button("SHOP", _open_shop, "Purple")
	shop.custom_minimum_size = Vector2(120, 0)
	shop.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	home.add_child(shop)
	if Global.best_height > 0:   # your records
		home.add_child(UI.label("BEST %dM  -  %d WINS" % [Global.best_height, Global.matches_won], "Small"))


func _open_modes() -> void:
	home.visible = false
	var screen := VBoxContainer.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.offset_top = 30
	screen.offset_left = 8
	screen.offset_right = -8
	screen.add_theme_constant_override("separation", 6)
	add_child(screen)
	screen.add_child(UI.label("Pre-game", "Title"))
	screen.add_child(UI.label("Pick your AI.", "Small"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	screen.add_child(grid)
	for id in Rivals.ALL:
		grid.add_child(_rival_card(id))
	var trial := UI.button("TIME TRIAL", func(): Transition.go("res://scenes/time_trial.tscn"), "Purple")
	trial.custom_minimum_size = Vector2(158, 22)
	trial.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	screen.add_child(trial)
	screen.add_child(UI.label("BEST %.2f S" % Global.best_time if Global.best_time > 0.0 else "RACE YOUR OWN GHOST TO 100 M", "Small"))
	var back := UI.button("BACK", func():
		screen.queue_free()
		home.visible = true, "Gray")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	screen.add_child(back)
	grid.get_child(["easy", "medium", "hard", "impossible"].find(Global.difficulty)).grab_focus()


func _rival_card(id: String) -> Button:
	var r: Array = Rivals.ALL[id]
	var card := UI.button("", func():
		Global.difficulty = id
		Global.save_game()
		Transition.go("res://scenes/game.tscn"), r[4])
	card.custom_minimum_size = Vector2(76, 76)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 1)
	card.add_child(v)
	var pic := UI.slime_picture(r[2], r[3], 1)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(pic)
	var name := UI.label(r[0], "Small")
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name)
	var coins := UI.label("+%d COINS" % r[1], "Small")
	coins.modulate = Color("fff3b0")
	coins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(coins)
	return card

func _open_shop() -> void:
	home.visible = false
	shop_layer = VBoxContainer.new()
	shop_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_layer.offset_top = 24
	shop_layer.offset_left = 6
	shop_layer.offset_right = -6
	shop_layer.offset_bottom = -6
	shop_layer.add_theme_constant_override("separation", 4)
	add_child(shop_layer)
	_fill_shop()


func _fill_shop() -> void:
	for c in shop_layer.get_children():
		c.queue_free()
	shop_layer.add_child(UI.label("SHOP", "Title"))
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	for k in [["hat", "HATS"], ["color", "COLORS"], ["trail", "TRAILS"]]:
		tabs.add_child(UI.button(k[1], func():
			shop_kind = k[0]
			_fill_shop(), "Gold" if shop_kind == k[0] else "Gray"))
	shop_layer.add_child(tabs)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_layer.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	scroll.add_child(grid)
	var list: Dictionary = Items.list(shop_kind)
	for id in list:
		grid.add_child(_card(id))
	var back := UI.button("BACK", func():
		shop_layer.queue_free()
		home.queue_free()
		_home(), "Gray")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	shop_layer.add_child(back)

func _card(id: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(80, 0)
	var v := VBoxContainer.new()
	card.add_child(v)
	var hat: String = id if shop_kind == "hat" else Global.equipped["hat"]
	var color: String = id if shop_kind == "color" else Global.equipped["color"]
	var pic := UI.slime_picture(hat, color, 1)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(pic)
	if shop_kind == "trail":   # a strip in the trail's colour
		var strip := ColorRect.new()
		strip.color = Items.TRAILS[id][1] if id != "none" else Color(1, 1, 1, 0.15)
		strip.custom_minimum_size = Vector2(30, 3)
		strip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(strip)
	var name := UI.label(Items.name_of(shop_kind, id), "Small")
	name.autowrap_mode = TextServer.AUTOWRAP_WORD
	name.custom_minimum_size = Vector2(40, 16)
	v.add_child(name)
	if Global.equipped[shop_kind] == id:
		v.add_child(UI.label("WORN", "Bold"))
	elif Global.owns(shop_kind, id):
		v.add_child(UI.button("WEAR", func():
			Global.equip(shop_kind, id)
			_fill_shop(), "Blue"))
	else:
		var price := Items.price(shop_kind, id)
		var buy := UI.button(str(price), func():
			if Global.buy(shop_kind, id):
				_fill_shop())
		buy.icon = load("res://art/ui/i_coin.png")
		buy.disabled = Global.coins < price
		v.add_child(buy)
	return card

func _show_notice() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(center)
	
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(140, 0)
	center.add_child(p)
	
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	
	var title_lbl := UI.label("Notice", "Title")
	title_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(title_lbl)
	
	var sub_lbl := UI.label("please read the github read.me", "Small")
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	sub_lbl.custom_minimum_size = Vector2(120, 0)
	sub_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(sub_lbl)
	
	var btn_box := VBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 4)
	v.add_child(btn_box)
	
	var btn_github := UI.button("Take me to it", func():
		OS.shell_open("https://github.com/nefedovmilan7-dot/Slime-Fall"), "Blue")
	btn_github.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_box.add_child(btn_github)
	
	var btn_close := UI.button("I've read it", func():
		center.queue_free(), "Gray")
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_box.add_child(btn_close)
