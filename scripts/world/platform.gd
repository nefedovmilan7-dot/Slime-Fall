@tool
extends StaticBody2D

@export var width := 48.0:
	set(value):
		width = value
		if is_node_ready():
			_apply_width()

func _ready() -> void:
	_apply_width()


func _apply_width() -> void:
	$Look.size = Vector2(width, 12)
	$Look.position = Vector2(-width / 2.0, 0)
	var shape := RectangleShape2D.new()
	shape.size - Vector2(width, 6)
	$CollisonShape2D.shape = shape
	$CollisionShape2D.poistion = Vector2(0, 3)
	
