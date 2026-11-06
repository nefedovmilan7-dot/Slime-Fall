class_name UI
extends RefCounted

static  var _theme: Theme

static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = load("res://art/ui/pixel_font.fnt")
	t.default_font_size = 8
	for v in [["Title", "pixel_bold", 16, Color("ffd23f")], ["Big", "pixel_bold", 12, Color.WHITE],
			["Bold", "pixel_bold", 8, Color.WHITE], ["Small", "pixel_font", 8, Color("b9b2d6")]]:
		t.set_type_variation(v[0], "Label")
		t.set_font("font", v[0], load("res://art/ui/%s.fnt" % v[1]))
		t.set_font_size("font_size", v[0], v[2])
		t.set_color("font_color", v[0], v[3])
		t.set_color("font_shadow_color", v[0], Color(0, 0, 0, 0.5))
		t.set_constant("shadow_offset_y", v[0], 1)
	for b in [["Button", "green"], ["Gray", "gray"], ["Red", "red"], ["Blue", "blue"], ["Gold", "gold"], ["Purple", "purple"]]:
		if b[0] != "Button":
			t.set_type_variation(b[0], "Button")
		t.set_stylebox("normal", b[0], _box("btn_%s" % b[1], Vector4(7, 3, 7, 7)))
		t.set_stylebox("hover", b[0], _box("btn_%s" % b[1], Vector4(7, 3, 7, 7)))
		t.set_stylebox("pressed", b[0], _box("btn_%s_pressed" % b[1], Vector4(7, 6, 7, 4)))
		t.set_stylebox("hover_pressed", b[0], _box("btn_%s_pressed" % b[1], Vector4(7, 6, 7, 4)))
		t.set_stylebox("disabled", b[0], _box("btn_gray", Vector4(7, 3, 7, 7)))
		t.set_stylebox("focus", b[0], StyleBoxEmpty.new())
		t.set_font("font", b[0], load("res://art/ui/pixel_bold.fnt"))
		t.set_font_size("font_size", b[0], 8)
	t.set_stylebox("panel", "PanelContainer", _box("panel", Vector4(8, 8, 8, 8)))
	_theme = t
	return t


static func clear() -> void:
	_theme = null


static func _box(picture: String, pad: Vector4) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://art/ui/%s.png" % picture)
	sb.texture_margin_left = 6
	sb.texture_margin_top = 6
	sb.texture_margin_right = 6
	sb.texture_margin_bottom = 8
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	return sb


static func label(text: String, variation := "Small") -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func button(text: String, on_press: Callable, variation := "") -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.pressed.connect(func():
		Global.play_sfx("click")
		on_press.call())
	return b


static func slime_picture(hat: String, color: String, scale := 2) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://art/slime/slime_%s.png" % hat)
	atlas.region = Rect2(0, 0, 32, 32)   # the first idle frame
	var r := TextureRect.new()
	r.texture = atlas
	r.custom_minimum_size = Vector2(32, 32) * scale
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.material = Global.slime_material(color)
	return r
