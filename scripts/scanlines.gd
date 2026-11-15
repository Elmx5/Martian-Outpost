extends Control
# Lineas de barrido de un monitor CRT. Puramente decorativo: no captura el raton.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var y := 0.0
	while y < size.y:
		draw_rect(Rect2(0.0, y, size.x, 1.0), Color(0, 0, 0, 0.22))
		y += 3.0
