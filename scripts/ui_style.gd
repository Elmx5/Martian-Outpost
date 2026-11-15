extends RefCounted
# Estilos y animaciones de UI compartidos (look pixel-art, a juego con los sprites).
# Uso: const UIStyle = preload("res://scripts/ui_style.gd")

const FONT := preload("res://assets/fonts/GeistPixel-Regular-VariableFont_ELSH.ttf")
const ACCENT := Color("e08a3c")       # naranja/marron del escritorio
const TEAL := Color("3f8fa0")         # azul-verdoso de la oficina
const PANEL := Color(0.09, 0.13, 0.19, 0.95)
const BORDER := Color("8fb8c8")       # gris azulado claro
const AMBER := Color("ffb84d")        # rotulos de la consola
const SCREEN_BG := Color("07130f")    # fondo del monitor
const SCREEN_FG := Color("9be7b8")    # fosforo verde del monitor

# Placa de consola: fondo oscuro y borde del grosor que se pida (flat() fuerza 4 px)
static func plate(color: Color, border: Color, border_w := 3, margin := 8, radius := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.anti_aliasing = false
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border_w)
	s.border_color = border
	s.set_content_margin_all(margin)
	return s

# Caja pixel: esquinas rectas, sin suavizado, borde grueso. (radius se ignora, se deja por compatibilidad)
static func flat(color: Color, _radius := 0, margin := 12, border := BORDER, border_w := 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.anti_aliasing = false
	s.set_corner_radius_all(0)
	s.set_border_width_all(0 if border_w <= 0 else 4)
	s.border_color = border
	s.set_content_margin_all(margin)
	return s

# Boton "chunky" de pixel-art: borde inferior grueso que se hunde al pulsar
static func btn_box(color: Color, kind := "normal") -> StyleBoxFlat:
	var c := color
	var bottom := 8
	var top := 12
	if kind == "hover":
		c = color.lightened(0.15)
	elif kind == "pressed":
		c = color.darkened(0.2)
		bottom = 4
		top = 16
	var s := flat(c, 0, 14, color.darkened(0.65), 4)
	s.border_width_bottom = bottom
	s.content_margin_top = top
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
	t.set_stylebox("disabled", "Button", flat(Color("4a5568"), 0, 14, Color("2d3748"), 4))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		t.set_color(c, "Button", Color.WHITE)
	t.set_color("font_outline_color", "Button", Color("2b1808"))
	t.set_constant("outline_size", "Button", 6)
	t.set_font_size("font_size", "Button", 40)
	t.set_stylebox("panel", "PanelContainer", flat(PANEL, 0, 20, BORDER, 4))
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
