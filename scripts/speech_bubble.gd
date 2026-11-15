extends PanelContainer
# Bocadillo de comic: cuerpo redondeado con borde grueso y un rabito que apunta al visitante.
# Los hijos se colocan dentro del cuerpo; el rabito va debajo, a la izquierda.

const TAIL_H := 36.0
const FILL := Color("f3ead2")
const INK := Color("1a2230")
const BW := 4.0

var _box: StyleBoxFlat

func _init() -> void:
	_box = StyleBoxFlat.new()
	_box.bg_color = FILL
	_box.border_color = INK
	_box.set_border_width_all(int(BW))
	_box.set_corner_radius_all(18)
	_box.anti_aliasing = false
	# sombra dura desplazada, estilo pixel
	_box.shadow_color = Color(0, 0, 0, 0.35)
	_box.shadow_size = 1
	_box.shadow_offset = Vector2(5, 5)
	# el panel nativo no dibuja nada: solo reserva el margen (incluido el hueco del rabito)
	var pad := StyleBoxEmpty.new()
	pad.content_margin_left = 18
	pad.content_margin_right = 18
	pad.content_margin_top = 12
	pad.content_margin_bottom = 12 + TAIL_H
	add_theme_stylebox_override("panel", pad)

func _draw() -> void:
	var body := Rect2(Vector2.ZERO, Vector2(size.x, size.y - TAIL_H))
	draw_style_box(_box, body)
	var bx := minf(size.x * 0.14, 60.0)
	var by := body.size.y
	var l := Vector2(bx, by - BW)
	var r := Vector2(bx + 34.0, by - BW)
	var tip := Vector2(bx - 22.0, by + TAIL_H - 2.0)
	# tapa el borde del cuerpo donde nace el rabito, y lo rellena
	draw_rect(Rect2(bx + BW * 0.5, by - BW - 1.0, 34.0 - BW, BW + 2.0), FILL)
	draw_colored_polygon(PackedVector2Array([l, r, tip]), FILL)
	draw_line(l, tip, INK, BW)
	draw_line(r, tip, INK, BW)
