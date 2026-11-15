extends RefCounted
# Estilos y animaciones de UI compartidos (look pixel-art metalico, a juego con el escritorio).
# Uso: const UIStyle = preload("res://scripts/ui_style.gd")

const FONT := preload("res://assets/fonts/GeistPixel-Regular-VariableFont_ELSH.ttf")
const ACCENT := Color("d9822b")       # naranja del escritorio
const TEAL := Color("3f8fa0")         # azul-verdoso de la oficina
const STEEL := Color("5c626b")        # gris metal del escritorio
const DARK_STEEL := Color("2f3a4a")   # metal oscuro (burbujas, menus)
const BORDER := Color("8fb8c8")
const SCREEN_BG := Color("0a1410")   # fondo del monitor CRT
const SCREEN_FG := Color("8dffb0")   # texto verde fosforo
const AMBER := Color("ffb84d")       # etiquetas ambar

# Placa plana oscura de pixel-art (monitores, marcos de medidores). radius opcional (monitor CRT).
static func plate(bg: Color, border: Color, border_w := 4, margin := 10, radius := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.anti_aliasing = false
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border_w)
	s.border_color = border
	s.set_content_margin_all(margin)
	return s

# Caja plana pixel (sin suavizado, esquinas rectas). radius se ignora, se deja por compatibilidad.
static func flat(color: Color, _radius := 0, margin := 12, border := BORDER, border_w := 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.anti_aliasing = false
	s.set_corner_radius_all(0)
	s.set_border_width_all(0 if border_w <= 0 else 4)
	s.border_color = border
	s.set_content_margin_all(margin)
	return s

# Placa de metal en pixel-art (nine-patch generado por codigo): contorno oscuro, bisel claro arriba-izquierda,
# bisel oscuro abajo-derecha, esquinas cortadas y tornillos. pressed = bisel invertido (boton hundido).
static func metal(base: Color, pressed := false, n := 24, margin := 8, screws := true) -> StyleBoxTexture:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var outline := base.darkened(0.7)
	var hi := base.lightened(0.32)
	var lo := base.darkened(0.35)
	var fill := base
	if pressed:
		var t := hi
		hi = lo
		lo = t
		fill = base.darkened(0.12)
	img.fill(fill)
	for i in n:
		for k in 2:
			img.set_pixel(i, 1 + k, hi)
			img.set_pixel(1 + k, i, hi)
			img.set_pixel(i, n - 2 - k, lo)
			img.set_pixel(n - 2 - k, i, lo)
	for i in n:
		img.set_pixel(i, 0, outline)
		img.set_pixel(i, n - 1, outline)
		img.set_pixel(0, i, outline)
		img.set_pixel(n - 1, i, outline)
	for p in [Vector2i(0, 0), Vector2i(n - 1, 0), Vector2i(0, n - 1), Vector2i(n - 1, n - 1)]:
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	if screws:
		var shine := fill.lightened(0.5)
		var m := margin - 4
		for p in [Vector2i(m, m), Vector2i(n - m - 2, m), Vector2i(m, n - m - 2), Vector2i(n - m - 2, n - m - 2)]:
			img.set_pixel(p.x, p.y, shine)
			img.set_pixel(p.x + 1, p.y, shine)
			img.set_pixel(p.x, p.y + 1, outline)
			img.set_pixel(p.x + 1, p.y + 1, outline)
	var s := StyleBoxTexture.new()
	s.texture = ImageTexture.create_from_image(img)
	s.set_texture_margin_all(margin)
	s.set_content_margin_all(margin + 4)
	return s

# Boton mecanico de panel: se ilumina al pasar el raton y se hunde al pulsar
static func btn_box(color: Color, kind := "normal") -> StyleBoxTexture:
	var s: StyleBoxTexture
	if kind == "hover":
		s = metal(color.lightened(0.12))
	elif kind == "pressed":
		s = metal(color, true)
		s.content_margin_top = 16
		s.content_margin_bottom = 9
	else:
		s = metal(color)
	if kind != "pressed":
		s.content_margin_top = 12
		s.content_margin_bottom = 13
	return s

static func color_button(b: Button, color: Color) -> void:
	b.add_theme_stylebox_override("normal", btn_box(color, "normal"))
	b.add_theme_stylebox_override("hover", btn_box(color, "hover"))
	b.add_theme_stylebox_override("pressed", btn_box(color, "pressed"))

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = FONT
	t.default_font_size = 26
	t.set_stylebox("normal", "Button", btn_box(ACCENT, "normal"))
	t.set_stylebox("hover", "Button", btn_box(ACCENT, "hover"))
	t.set_stylebox("pressed", "Button", btn_box(ACCENT, "pressed"))
	t.set_stylebox("disabled", "Button", metal(Color("4a5568"), true))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		t.set_color(c, "Button", Color.WHITE)
	t.set_color("font_outline_color", "Button", Color("2b1808"))
	t.set_constant("outline_size", "Button", 6)
	t.set_font_size("font_size", "Button", 40)
	t.set_stylebox("panel", "PanelContainer", metal(DARK_STEEL, false, 24, 8, true))
	t.set_stylebox("panel", "TooltipPanel", flat(Color("0e1621"), 0, 12, BORDER, 4))
	t.set_font_size("font_size", "TooltipLabel", 22)
	t.set_color("font_color", "TooltipLabel", Color.WHITE)
	var clear := Color(0, 0, 0, 0)
	t.set_stylebox("slider", "HSlider", flat(Color(0, 0, 0, 0.5), 0, 5, BORDER, 0))
	t.set_stylebox("grabber_area", "HSlider", flat(ACCENT, 0, 5, clear, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", flat(ACCENT.lightened(0.2), 0, 5, clear, 0))
	return t

# Boton "gomoso": crece al pasar el raton.
static func juicy(b: Control) -> void:
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	b.mouse_entered.connect(func() -> void: _scale_to(b, 1.08))
	b.mouse_exited.connect(func() -> void: _scale_to(b, 1.0))

static func _scale_to(b: Control, s: float) -> void:
	var t := b.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(b, "scale", Vector2(s, s), 0.15)
