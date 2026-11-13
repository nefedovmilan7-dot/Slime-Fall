class_name NeuralView
extends Control

const W := 74.0
const H := 70.0

var net: NeuralNet


func _ready() -> void:
	custom_minimum_size = Vector2(W, H + 12.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _node_pos(layer: int, i: int) -> Vector2:
	var count: int = net.sizes[layer]
	var x := 6.0 + layer * (W - 12.0) / (net.sizes.size() - 1)
	var y := 4.0 + (i + 0.5) * (H - 8.0) / count
	return Vector2(x, y)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.04, 0.12, 0.82))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.42, 0.36, 0.62), false, 1.0)
	if net == null or net.acts.size() != net.sizes.size():
		return
	# connections
	for l in net.weights.size():
		var w: PackedFloat32Array = net.weights[l]
		var a_in: PackedFloat32Array = net.acts[l]
		var n_in: int = net.sizes[l]
		for j in net.sizes[l + 1]:
			for i in n_in:
				var flow: float = w[j * n_in + i] * a_in[i]
				if absf(flow) < 0.3:
					continue
				var c := Color(0.45, 1.0, 0.45) if flow > 0.0 else Color(1.0, 0.4, 0.35)
				c.a = clampf(absf(flow) * 0.5, 0.05, 0.6)
				draw_line(_node_pos(l, i), _node_pos(l + 1, j), c, 1.0)
	# neurons
	for l in net.acts.size():
		var a: PackedFloat32Array = net.acts[l]
		for i in a.size():
			var v := clampf(a[i], -1.0, 1.0)
			var c := Color(0.45, 1.0, 0.45) if v >= 0.0 else Color(1.0, 0.4, 0.35)
			c = Color(0.25, 0.22, 0.35).lerp(c, absf(v))
			draw_circle(_node_pos(l, i), 1.6 if l == 0 else 2.2, c)
	var font: Font = load("res://art/ui/pixel_font.fnt")
	var o: PackedFloat32Array = net.acts[net.acts.size() - 1]
	var move := "<" if o[0] < -0.3 else (">" if o[0] > 0.3 else "-")
	draw_string(font, Vector2(4, H + 9.0), "NN " + move + (" JUMP" if o[1] > 0.0 else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("ffd23f"))
