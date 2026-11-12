extends Node2D

var meters := 0

func _draw() -> void:
	var font: Font = load("res://art/ui/pixel_font.fnt")
	for x in range(16, 164, 8):
		draw_line(Vector2(x, 0), Vector2(x + 5, 0), Color("ffd23f"), 1.0)
	draw_string(font, Vector2(18, -3), "BEST %dM" % meters, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("ffd23f"))
