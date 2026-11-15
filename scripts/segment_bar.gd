extends Control
# Medidor de LEDs por segmentos (en vez de una barra lisa). Se dibuja solo.
# value: 0-100. fill_color: color de los segmentos encendidos.
# warn_from: a partir de este valor los segmentos apagados se tintan de rojo (zona de peligro). -1 = sin zona.

const SEGMENTS := 20
const GAP := 3.0

var value := 0.0:
	set(v):
		value = v
		queue_redraw()
var fill_color := Color.WHITE:
	set(c):
		fill_color = c
		queue_redraw()
var warn_from := -1.0:
	set(w):
		warn_from = w
		queue_redraw()

func _draw() -> void:
	# marco del medidor
	draw_rect(Rect2(Vector2.ZERO, size), Color("05080b"))
	var inner := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	var seg_h := (inner.size.y - GAP * (SEGMENTS - 1)) / SEGMENTS
	var lit := roundi(clampf(value, 0.0, 100.0) / 100.0 * SEGMENTS)
	for i in SEGMENTS:
		var y := inner.end.y - (i + 1) * seg_h - i * GAP
		var r := Rect2(inner.position.x, y, inner.size.x, seg_h)
		var in_warn := warn_from >= 0.0 and (float(i) / SEGMENTS * 100.0) >= warn_from
		if i < lit:
			draw_rect(r, fill_color)
			# brillo en el canto superior del LED
			draw_rect(Rect2(r.position, Vector2(r.size.x, 2.0)), fill_color.lightened(0.4))
		else:
			draw_rect(r, Color("2a1010") if in_warn else Color("111a21"))
