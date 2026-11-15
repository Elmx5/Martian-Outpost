extends Control

const UIStyle = preload("res://scripts/ui_style.gd")
const SpeechBubbleScript = preload("res://scripts/speech_bubble.gd")
const SegmentBarScript = preload("res://scripts/segment_bar.gd")
const ScanlinesScript = preload("res://scripts/scanlines.gd")
const SFX_KNOCK := preload("res://assets/audio/SFX/SFX Door knock.wav")
const SFX_TALK := preload("res://assets/audio/SFX/SFX character talking.wav")
const MAIN_SCENE := "res://scenes/mainScene/main_scene.tscn"

# ---- Balance (toca estos numeros para ajustar la dificultad) ----
const WIN_DAY := 10          # dias que hay que sobrevivir
const MIN_VISITORS := 2      # situaciones por dia (minimo)
const MAX_VISITORS := 5      # situaciones por dia (maximo)
const NEG_SCALE := 0.6       # los efectos malos de los eventos se multiplican por esto (1.0 = original)
const FAIL_PENALTY := 10     # energia extra que se pierde si una opcion arriesgada (mision) sale mal
const FAIL_EXTRA := 4        # comida y agua extra que se pierden tambien al fallar
const SICK_LEVEL := 60       # con esta radiacion o mas la tripulacion enferma
const SICK_PENALTY := 3      # cada noche enferma: pierdes esto en energia, comida y agua
const DAY_EVENT_CHANCE := 0.75  # probabilidad de que un dia (a partir del 2) empiece con un evento del dia
# Produccion y gasto base de cada NOCHE por recurso (energia, comida, agua, radiacion).
# La produccion solo funciona cuando el edificio esta construido ("bld"). Con todo construido la base pierde un poco cada noche
# (-3 energia, -3 comida, -3 agua, +3 radiacion): hay que mejorarla con eventos (invernadero, fision, refugio...) para aguantar.
# "prod" = produccion: los eventos del dia pueden bloquearla (ej. una tormenta de polvo tapa los paneles solares).
var base_lines: Array = [
	[{"label": "☀️ Solar panels", "v": 8, "prod": true, "bld": "panels"}, {"label": "🏠 Base lights", "v": -11}],
	[{"label": "🌱 Farm", "v": 6, "prod": true, "bld": "farm"}, {"label": "🍽️ Crew meals", "v": -9}],
	[{"label": "💧 Water treatment", "v": 6, "prod": true, "bld": "water"}, {"label": "🚿 Crew water", "v": -9}],
	[{"label": "🌌 Space radiation", "v": 12, "prod": true}, {"label": "🛡️ Base shield", "v": -9}],
]

# Posiciones (fraccion de pantalla): puerta de la oficina y sitio donde se para el visitante
const DOOR := Vector2(0.352, 0.30)
const SPOT := Vector2(0.44, 0.30)

# Tutorial de la radio de la NASA. hl = parte de la pantalla que parpadea
const TUTORIAL := [
	{"emoji": "📻🌍👋", "text": "Hi Commander! This is NASA calling from Earth! This message is pre-recorded.", "hl": ""},
	{"emoji": "📻🚫📡", "text": "We cannot talk to you live until you build an antenna. Today all our radio messages are pre-recorded!", "hl": ""},
	{"emoji": "📡✅🛰️", "text": "With the antenna we can send you live advice, satellite discoveries and warnings before a disaster!", "hl": ""},
	{"emoji": "🚪👨‍🚀🧑‍🌾", "text": "Your crew will knock on the door. Listen to them and decide!", "hl": ""},
	{"emoji": "👆👍👎", "text": "Pick one of the two buttons. Hover over them to preview what changes!", "hl": "buttons"},
	{"emoji": "⚡🥬💧", "text": "These bars are your base. If Energy, Food or Water reaches 0, you lose!", "hl": "bars"},
	{"emoji": "☢️⬇️", "text": "Radiation works backwards: keep it LOW! Above 60 the crew gets sick!", "hl": "bars"},
	{"emoji": "🌙🔎", "text": "Every night your base makes and uses resources. Hover over a bar to see the details!", "hl": "bars"},
	{"emoji": "🏗️⚡🥬", "text": "Buildings cost resources, but then they produce every night. Until you build them, nothing is produced!", "hl": ""},
	{"emoji": "⚠️🌪️", "text": "Some days start with an alert, like a dust devil, that changes what you gain tonight!", "hl": ""},
	{"emoji": "📅🌙", "text": "Every day brings 2 to 5 visitors. Survive {d} days to win!", "hl": ""},
	{"emoji": "🚀🍀", "text": "Good luck, Commander! We are counting on you!", "hl": ""},
]

@onready var music: AudioStreamPlayer = $AudioStreamPlayer

var stats: Array = []
var bars := {}
var tw := {}
var deck: Array = []
var mods: Array = []
var current: Event
var current_char: Node2D
var bob_tw: Tween
var hl_tw: Tween
var unresolved: Array = []  # problemas sin arreglar: vuelven a salir cada dia
var astro_away := 0         # dias que le quedan de expedicion al astronauta
var mods_scroll: ScrollContainer
var extras: Array = []      # problemas abiertos que vuelven hoy: salen aparte, no gastan visitantes
var is_extra := false
var type_tw: Tween          # animacion de escribir el texto (un clic la completa)
var typing := false
var infinite := false       # modo infinito: no hay dia final y la base gasta cada vez mas
var day := 1
var sit_idx := 0
var visitors_today := 3
var tutorial := false
var announcing := false
var today_event: Dictionary = {}
var tut_i := 0
var busy := true
var built := {}            # edificios construidos (farm, panels, water, antenna)
var pending: Array = []    # efectos que llegan dentro de N dias
var queue: Array = []      # eventos que salen seguro hoy (tutoriales)
var retry: Array = []      # tutoriales rechazados: vuelven manana
var today_left := 0        # noches que le quedan al evento del dia
var doom := ""              # motivo de game over diferido (fuga de oxigeno)

var char_layer: Control
var glow: ColorRect
var alert: ColorRect
var night: ColorRect
var night_label: Label
var bubble: PanelContainer
var emoji_label: Label
var photo: TextureRect
var photo_frame: PanelContainer
var credit_label: Label
var screen_header: Label
var rec_label: Label
var scheduled := {}        # desastre que NASA ha predicho para manana: {id, ready}
var text_label: RichTextLabel
var desk_text: PanelContainer
var fact_label: RichTextLabel
var btn_box: VBoxContainer
var bars_panel: PanelContainer
var btn1: Button
var btn2: Button
var day_label: Label
var mods_box: VBoxContainer
var banner: Label
var sfx: AudioStreamPlayer
var talk: AudioStreamPlayer

func _ready() -> void:
	theme = UIStyle.make_theme()
	infinite = Settings.infinite_mode
	Transition.stop_music()
	Resources.reset()
	_init_stats()
	_build_ui()
	_refresh_mods()
	Resources.resource_changed.connect(_on_resource_changed)
	music.finished.connect(music.play)
	await get_tree().create_timer(0.8).timeout
	_start_tutorial()

func _init_stats() -> void:
	stats = [
		{"res": Resources.SpaceResource.ENERGY, "emoji": "⚡", "tag": "PWR", "name": "Energy", "color": Color("fbbf24"), "tip": "Power for the base. At 0 the lights go out!"},
		{"res": Resources.SpaceResource.FOOD, "emoji": "🥬", "tag": "FOOD", "name": "Food", "color": Color("4ade80"), "tip": "Plants and meals. At 0 the crew is hungry!"},
		{"res": Resources.SpaceResource.WATER, "emoji": "💧", "tag": "H2O", "name": "Water", "color": Color("38bdf8"), "tip": "To drink, to grow plants, to produce oxigen and to maintain the sistems cool. At 0 nobody can drink!"},
		{"res": Resources.SpaceResource.RADIATION, "emoji": "☢️", "tag": "RAD", "name": "Radiation", "color": Color("f87171"), "tip": "Keep it LOW! From 60 the crew gets sick, at 100 you lose!"},
	]

# ---------- UI ----------

# Coloca un control con fracciones de pantalla (deterministico: anclas + offsets a 0).
func _place(c: Control, x0: float, y0: float, x1: float, y1: float) -> void:
	c.anchor_left = x0
	c.anchor_top = y0
	c.anchor_right = x1
	c.anchor_bottom = y1
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0

func _tex(path: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(path)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r

func _rect(color: Color, x0: float, y0: float, x1: float, y1: float) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.modulate.a = 0.0
	add_child(r)
	_place(r, x0, y0, x1, y1)
	return r

func _build_ui() -> void:
	sfx = AudioStreamPlayer.new()
	sfx.bus = Settings.SFX_BUS
	add_child(sfx)
	talk = AudioStreamPlayer.new()
	talk.bus = Settings.SFX_BUS
	add_child(talk)
	# Oficina (con la puerta) y luz de la puerta
	_place(_tex("res://assets/sprites/menus/office.png"), 0.0, 0.0, 1.0, 0.72)
	glow = _rect(Color(1.0, 0.92, 0.65), 0.266, 0.04, 0.438, 0.50)
	# Capa de personajes (detras del escritorio)
	char_layer = Control.new()
	char_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(char_layer)
	_place(char_layer, 0.0, 0.0, 1.0, 1.0)
	# Escritorio
	_place(_tex("res://assets/sprites/menus/desktop.png"), 0.0, 0.52, 1.0, 1.0)
	alert = _rect(Color(1, 0.1, 0.1), 0.0, 0.0, 1.0, 1.0)
	# Noche (por debajo de la interfaz para poder ver las barras)
	night = _rect(Color(0.02, 0.03, 0.12, 0.8), 0.0, 0.0, 1.0, 1.0)
	night_label = Label.new()
	night_label.text = ""
	night_label.add_theme_font_size_override("font_size", 64)
	night_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	night_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night_label.modulate.a = 0.0
	add_child(night_label)
	_place(night_label, 0.05, 0.15, 0.75, 0.35)
	_build_bubble()
	_build_buttons()
	_build_bars()
	_build_day_panel()
	banner = Label.new()
	banner.add_theme_font_size_override("font_size", 150)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.modulate.a = 0.0
	add_child(banner)
	_place(banner, 0.44, 0.22, 0.44, 0.22)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH

func _build_bubble() -> void:
	# Bocadillo del visitante: forma de comic con rabito; solo emojis y foto
	bubble = SpeechBubbleScript.new()
	add_child(bubble)
	_place(bubble, 0.56, 0.03, 0.56, 0.03)
	bubble.modulate.a = 0.0
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 260
	v.add_theme_constant_override("separation", 6)
	bubble.add_child(v)
	emoji_label = Label.new()
	emoji_label.add_theme_font_size_override("font_size", 64)
	emoji_label.add_theme_color_override("font_color", Color("1a2230"))
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(emoji_label)
	# Foto enmarcada con su credito (las fotos de la NASA llevan siempre credito)
	photo_frame = PanelContainer.new()
	photo_frame.add_theme_stylebox_override("panel", UIStyle.plate(Color("1a2230"), Color("1a2230"), 3, 3))
	photo_frame.visible = false
	v.add_child(photo_frame)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 2)
	photo_frame.add_child(pv)
	photo = TextureRect.new()
	photo.custom_minimum_size = Vector2(0, 130)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pv.add_child(photo)
	credit_label = Label.new()
	credit_label.add_theme_font_size_override("font_size", 12)
	credit_label.add_theme_color_override("font_color", Color("9fb3c4"))
	credit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pv.add_child(credit_label)
	_build_monitor()

# La "pantalla" del escritorio: un monitor CRT con la explicacion del evento
func _build_monitor() -> void:
	desk_text = PanelContainer.new()
	desk_text.add_theme_stylebox_override("panel", UIStyle.plate(UIStyle.SCREEN_BG, Color("07090c"), 6, 8, 6))
	add_child(desk_text)
	_place(desk_text, 0.235, 0.615, 0.765, 0.905)
	desk_text.modulate.a = 0.0
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 4)
	desk_text.add_child(dv)
	var head := HBoxContainer.new()
	dv.add_child(head)
	screen_header = Label.new()
	screen_header.add_theme_font_size_override("font_size", 16)
	screen_header.add_theme_color_override("font_color", UIStyle.AMBER)
	screen_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(screen_header)
	var rec := Label.new()
	rec_label = rec
	rec.text = "● LIVE"
	rec.add_theme_font_size_override("font_size", 14)
	rec.add_theme_color_override("font_color", UIStyle.SCREEN_FG)
	head.add_child(rec)
	var blink := create_tween().set_loops()
	blink.tween_property(rec, "modulate:a", 0.25, 0.7)
	blink.tween_property(rec, "modulate:a", 1.0, 0.7)
	var line := ColorRect.new()
	line.custom_minimum_size.y = 2
	line.color = UIStyle.SCREEN_FG.darkened(0.55)
	dv.add_child(line)
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.add_theme_font_size_override("normal_font_size", 22)
	text_label.add_theme_color_override("default_color", UIStyle.SCREEN_FG)
	dv.add_child(text_label)
	# Dato real de la NASA (con fuente en el tooltip)
	fact_label = RichTextLabel.new()
	fact_label.bbcode_enabled = true
	fact_label.fit_content = true
	fact_label.scroll_active = false
	fact_label.visible = false
	fact_label.mouse_filter = Control.MOUSE_FILTER_STOP
	fact_label.add_theme_font_size_override("normal_font_size", 16)
	fact_label.add_theme_color_override("default_color", UIStyle.SCREEN_FG.darkened(0.2))
	dv.add_child(fact_label)
	# lineas de barrido por encima de todo
	var scan := Control.new()
	scan.set_script(ScanlinesScript)
	desk_text.add_child(scan)

# Botones de decision sobre la zona marron del escritorio
func _build_buttons() -> void:
	btn_box = VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 14)
	add_child(btn_box)
	_place(btn_box, 0.027, 0.595, 0.212, 0.925)
	btn1 = _make_btn(1)
	btn2 = _make_btn(2)
	UIStyle.color_button(btn2, UIStyle.TEAL)
	btn_box.add_child(btn1)
	btn_box.add_child(btn2)

func _make_btn(opt: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 70)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 24)
	b.clip_text = true
	b.pressed.connect(_choose.bind(opt))
	var preview := func() -> void:
		if not busy and not tutorial:
			_show_deltas(_eff(opt), false)
	b.mouse_entered.connect(preview)
	b.focus_entered.connect(preview)
	b.mouse_exited.connect(func() -> void:
		if not busy:
			_clear_preview())
	UIStyle.juicy(b)
	return b

# Barras verticales en el escritorio (derecha)
func _build_bars() -> void:
	bars_panel = PanelContainer.new()
	bars_panel.add_theme_stylebox_override("panel", UIStyle.metal(UIStyle.STEEL, false, 32, 8))
	add_child(bars_panel)
	_place(bars_panel, 0.79, 0.595, 0.975, 0.925)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 2)
	bars_panel.add_child(hb)
	for info in stats:
		hb.add_child(_make_col(info))

func _make_col(info: Dictionary) -> VBoxContainer:
	var res: int = info["res"]
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_STOP
	col.add_theme_constant_override("separation", 2)
	var delta := Label.new()
	delta.custom_minimum_size.y = 26
	delta.add_theme_font_size_override("font_size", 20)
	delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delta.modulate.a = 0.0
	var val := Label.new()
	val.add_theme_font_size_override("font_size", 28)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.text = str(Resources.getResource(res))
	var bar = Control.new()
	bar.set_script(SegmentBarScript)
	bar.custom_minimum_size = Vector2(24, 80)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.fill_color = info["color"]
	bar.value = float(Resources.getResource(res))
	if res == Resources.SpaceResource.RADIATION:
		bar.warn_from = float(SICK_LEVEL)
	val.add_theme_font_size_override("font_size", 22)
	val.add_theme_color_override("font_color", UIStyle.SCREEN_FG)
	val.add_theme_stylebox_override("normal", UIStyle.plate(UIStyle.SCREEN_BG, Color("1c2a22"), 2, 2))
	var tag := Label.new()
	tag.text = info["tag"]
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", UIStyle.AMBER)
	tag.add_theme_stylebox_override("normal", UIStyle.plate(UIStyle.SCREEN_BG, Color("1c2a22"), 2, 2))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(delta)
	col.add_child(tag)
	col.add_child(bar)
	col.add_child(val)
	bars[res] = {"col": col, "bar": bar, "val": val, "delta": delta, "color": info["color"]}
	return col

func _build_day_panel() -> void:
	var dp := PanelContainer.new()
	dp.add_theme_stylebox_override("panel", UIStyle.plate(Color("0d1116"), Color("3a4656"), 3, 8))
	add_child(dp)
	_place(dp, 0.012, 0.02, 0.012, 0.02)
	var v := VBoxContainer.new()
	dp.add_child(v)
	day_label = Label.new()
	day_label.add_theme_font_size_override("font_size", 22)
	day_label.add_theme_color_override("font_color", UIStyle.AMBER)
	day_label.text = "TUTORIAL"
	v.add_child(day_label)
	mods_scroll = ScrollContainer.new()
	mods_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mods_scroll.custom_minimum_size = Vector2(300, 0)
	v.add_child(mods_scroll)
	mods_box = VBoxContainer.new()
	mods_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mods_scroll.add_child(mods_box)
	var src := Label.new()
	src.text = "◆ REAL NASA DATA"
	src.add_theme_color_override("font_color", UIStyle.SCREEN_FG)
	src.tooltip_text = "Space weather info comes from NASA's DONKI database, and radiation numbers from NASA's Curiosity rover."
	src.mouse_filter = Control.MOUSE_FILTER_STOP
	src.add_theme_font_size_override("font_size", 18)
	src.modulate.a = 0.8
	v.add_child(src)

func _update_day_label() -> void:
	var dl := "DAY %d" % day if infinite else "DAY %d/%d" % [day, WIN_DAY]
	if is_extra:
		day_label.text = dl + "\n⚠️ UNSOLVED"
	else:
		day_label.text = dl + "\nVISITOR %d/%d" % [sit_idx, visitors_today]

# Hace parpadear una parte de la interfaz (para el tutorial)
func _highlight(key: String) -> void:
	if hl_tw:
		hl_tw.kill()
	btn_box.modulate = Color.WHITE
	bars_panel.modulate = Color.WHITE
	var target: Control = null
	if key == "buttons":
		target = btn_box
	elif key == "bars":
		target = bars_panel
	if target:
		hl_tw = create_tween().set_loops()
		hl_tw.tween_property(target, "modulate", Color(1.6, 1.6, 1.2), 0.5)
		hl_tw.tween_property(target, "modulate", Color.WHITE, 0.5)

# ---------- Modificadores (base + efectos activos) ----------

func _daily() -> Event.Benefits:
	var vals := [0, 0, 0, 0]
	for res in 4:
		for l in _lines(res):
			if not l["blocked"]:
				vals[res] += l["v"]
	return Event.Benefits.new(vals[0], vals[1], vals[2], vals[3])

# Lineas de produccion/gasto de un recurso para esta noche: base + evento del dia + efectos activos
func _lines(res: int) -> Array:
	var out: Array = []
	var blocked_here: bool = not today_event.is_empty() and res in today_event["block"]
	var mult := 1
	if not today_event.is_empty():
		mult = int((today_event["mult"] as Dictionary).get(res, 1))
	for l in base_lines[res]:
		var blk: bool = blocked_here and l.get("prod", false)
		var by := "blocked by " + String(today_event["label"]) if blk else ""
		if l.has("bld") and not built.has(l["bld"]):
			blk = true
			by = "not built yet"
		var v: int = l["v"]
		if l.get("prod", false):
			v *= mult
		# Modo infinito: pasado el dia final la base gasta mas cada 2 dias (y entra mas radiacion)
		if infinite and day > WIN_DAY:
			var pr := int((day - WIN_DAY) / 2.0)
			if res == Resources.SpaceResource.RADIATION:
				if l.get("prod", false):
					v += int(pr / 2.0)
			elif v < 0:
				v -= pr
		out.append({"label": l["label"], "v": v, "blocked": blk, "by": by})
	if not today_event.is_empty():
		var tv := _delta_of(today_event["ben"], res)
		if tv != 0:
			out.append({"label": today_event["label"], "v": tv, "blocked": false, "by": ""})
	if res != Resources.SpaceResource.RADIATION and Resources.getResource(Resources.SpaceResource.RADIATION) >= SICK_LEVEL:
		out.append({"label": "🤢 Radiation sickness", "v": -SICK_PENALTY, "blocked": false, "by": ""})
	for m in mods:
		var mv := _delta_of(m["ben"], res)
		if mv != 0:
			out.append({"label": m["label"], "v": mv, "blocked": false, "by": ""})
	return out

func _refresh_mods() -> void:
	for c in mods_box.get_children():
		c.queue_free()
	var rows := 0
	if not today_event.is_empty():
		_mod_row("⚠️ %s (%d night%s)" % [today_event["label"], today_left, "" if today_left == 1 else "s"], Color("fca5a5"))
		rows += 1
	if not scheduled.is_empty():
		var sl: String = EventsData.day_events[scheduled["id"]]["label"]
		_mod_row("🛰️ Tomorrow: %s%s" % [sl, " (ready)" if scheduled["ready"] else " (NOT ready)"], Color("93c5fd") if scheduled["ready"] else Color("fca5a5"))
		rows += 1
	for m in mods:
		_mod_row(m["label"] if m["days"] < 0 else "%s  (%dd)" % [m["label"], m["days"]], Color.WHITE)
		rows += 1
	for p in pending:
		_mod_row("⏳ %s  (in %dd)" % [p["label"], p["days"]], Color("fcd34d"))
		rows += 1
	# La lista no crece sin limite: pasado el maximo sale una barra deslizante
	mods_scroll.custom_minimum_size = Vector2(300, minf(rows * 30.0, 150.0))
	_refresh_tips()

func _mod_row(text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", color)
	l.custom_minimum_size.x = 270
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mods_box.add_child(l)

# Tooltip de cada barra: que suma y que resta cada noche
func _refresh_tips() -> void:
	for info in stats:
		var res: int = info["res"]
		var helps := PackedStringArray()
		var hurts := PackedStringArray()
		var blocked := PackedStringArray()
		var net := 0
		for l in _lines(res):
			if l["blocked"]:
				blocked.append("   %s  (%s)" % [l["label"], l["by"]])
				continue
			var v: int = l["v"]
			net += v
			var good := (v > 0) != (res == Resources.SpaceResource.RADIATION)
			var line := "   %s  %+d" % [l["label"], v]
			if good:
				helps.append(line)
			else:
				hurts.append(line)
		var tip := "%s %s - %s\n➕ Helps:\n%s\n➖ Hurts:\n%s" % [
			info["emoji"], info["name"], info["tip"],
			"\n".join(helps) if helps.size() > 0 else "   nothing",
			"\n".join(hurts) if hurts.size() > 0 else "   nothing"]
		if blocked.size() > 0:
			tip += "\n🚫 Blocked today:\n" + "\n".join(blocked)
		tip += "\n🌙 Tonight: %+d" % net
		(bars[res]["col"] as Control).tooltip_text = tip

# ---------- Tutorial ----------

func _start_tutorial() -> void:
	tutorial = true
	tut_i = 0
	btn2.visible = false
	btn1.text = "Next"
	await _arrive(EventsData.Radio, "📻", false)
	_tut_step()

func _tut_step() -> void:
	busy = true
	var s: Dictionary = TUTORIAL[tut_i]
	_highlight(s["hl"])
	btn1.text = "Let's go!" if tut_i == TUTORIAL.size() - 1 else "Next"
	var line := String(s["text"]).replace("{d}", str(WIN_DAY))
	if infinite:
		line = line.replace("Survive %d days to win!" % WIN_DAY, "Survive as many days as you can!")
	await _say(s["emoji"], line, null, {}, "NASA · PRE-RECORDED", "", false)
	busy = false

func _tutorial_next() -> void:
	tut_i += 1
	if tut_i >= TUTORIAL.size():
		tutorial = false
		_highlight("")
		btn2.visible = true
		btn1.text = ""
		btn2.text = ""
		await _dismiss()
		_begin_day()
	else:
		_tut_step()

# ---------- Flujo del juego ----------

func _begin_day() -> void:
	queue = retry.duplicate()
	retry.clear()
	extras = unresolved.duplicate()
	is_extra = false
	if day == 1:
		queue.append_array(EventsData.tutorial_ids)
	visitors_today = maxi(randi_range(MIN_VISITORS, MAX_VISITORS), queue.size())
	sit_idx = 0
	_update_day_label()
	_pop_banner("☀️")
	await get_tree().create_timer(0.8).timeout
	# Al empezar el dia, a veces hay una alerta que cambia lo que ganas por la noche
	var ids := _day_event_ids()
	if not scheduled.is_empty() and today_event.is_empty():
		# NASA lo predijo ayer: hoy ocurre seguro (sin perdidas si te preparaste)
		today_event = EventsData.day_event_today(scheduled["id"], scheduled["ready"])
		scheduled = {}
		today_left = int(today_event.get("days", 1))
		_refresh_mods()
		_announce(today_event)
	elif day > 1 and today_event.is_empty() and not ids.is_empty() and randf() < DAY_EVENT_CHANCE:
		today_event = EventsData.day_event_today(ids.pick_random())
		today_left = int(today_event.get("days", 1))
		_refresh_mods()
		_announce(today_event)
	else:
		_next_event()

# Alertas del dia disponibles (las que piden un edificio solo salen si ya esta construido)
func _day_event_ids() -> Array:
	var out: Array = []
	for k in EventsData.day_events:
		var rq: String = EventsData.day_events[k]["requires"]
		if rq == "" or built.has(rq):
			out.append(k)
	return out

func _announce(d: Dictionary) -> void:
	announcing = true
	busy = true
	btn2.visible = false
	btn1.text = "OK"
	var a := create_tween()
	for i in 2:
		a.tween_property(alert, "modulate:a", 0.3, 0.2)
		a.tween_property(alert, "modulate:a", 0.0, 0.25)
	await _say(d["emojis"], d["text"], d["photo"], d.get("fact", {}), "AS PREDICTED · YOU WERE READY" if d.get("prepared", false) else "DAILY ALERT", d.get("credit", ""))
	busy = false

func _announce_done() -> void:
	announcing = false
	var t := create_tween().set_parallel(true)
	t.tween_property(bubble, "modulate:a", 0.0, 0.3)
	t.tween_property(desk_text, "modulate:a", 0.0, 0.3)
	await t.finished
	btn2.visible = true
	_next_event()

func _next_event() -> void:
	if not extras.is_empty():
		current = EventsData.events[extras.pop_front()]
		is_extra = true
	elif not queue.is_empty():
		current = EventsData.events[queue.pop_front()]
		is_extra = false
	else:
		current = _pick_event()
		is_extra = false
	_show_event(current)

# Evento al azar: sin tutoriales, sin construir dos veces lo mismo, sin mejoras permanentes ya compradas,
# sin los que piden un edificio que aun no existe y SIN mensajes de la NASA hasta que la antena este construida
func _pick_event() -> Event:
	for i in 80:
		if deck.is_empty():
			for k in EventsData.events:
				if not EventsData.events[k].tutorial:
					deck.append(k)
			deck.shuffle()
		var ev: Event = EventsData.events[deck.pop_back()]
		var done: bool = ev.build1 != "" and built.has(ev.build1)
		var away: bool = astro_away > 0 and ev.character == EventsData.Astronaut
		var no_signal: bool = ev.type == Event.Type.COMMS and not built.has("antenna")
		var double_warning: bool = ev.warns != "" and not scheduled.is_empty()
		var owned := false
		if not ev.mod1.is_empty() and ev.mod1["days"] < 0:
			for m in mods:
				if m.get("src", "") == ev.id:
					owned = true
		if (ev.requires == "" or built.has(ev.requires)) and not done and not away and not no_signal and not double_warning and not owned:
			return ev
	return EventsData.events["water_dig"]

func _show_event(ev: Event) -> void:
	if not is_extra:
		sit_idx += 1
	_update_day_label()
	await _arrive(ev.character, ev.emojis, false)
	btn1.text = ev.label1 + ("  (%d%%)" % int(ev.winChance) if ev.winChance < 100.0 else "")
	btn2.text = ev.label2
	var ph: Texture2D = ev.photo if ev.photo != null else EventsData.nasa_photo(ev.id)
	var hdr := _speaker(ev)
	# Sin antena los mensajes de la NASA son pregrabados (no es una conversacion en directo)
	var live := ev.type != Event.Type.COMMS or built.has("antenna")
	await _say(ev.emojis, ev.desc, ph, EventsData.fact_for(ev.id), hdr, EventsData.photo_credit(ev.id), live)
	busy = false

# Nombre y oficio del personaje, que se muestra encima del texto del monitor
func _speaker(ev: Event) -> String:
	if ev.character == EventsData.Farmer:
		return "JOHN RAKE · FARMER"
	if ev.character == EventsData.Scientist:
		return "SANDRA HAWKINS · SCIENTIST"
	if ev.character == EventsData.Astronaut:
		return "ANTHONY CLARK · ASTRONAUT"
	if ev.character == null:
		return "BASE ALERT"
	return "NASA · LIVE" if built.has("antenna") else "NASA · PRE-RECORDED"

# El visitante llama a la puerta, esta se ilumina y entra caminando
func _arrive(scene: PackedScene, _fallback: String, alert_flash: bool) -> void:
	bubble.modulate.a = 0.0
	desk_text.modulate.a = 0.0
	var door := size * DOOR
	var spot := size * SPOT
	if scene == null:
		# Aviso de la base (sin personaje): parpadea la alarma y no entra nadie, solo salen los emojis en el bocadillo
		current_char = null
		var a0 := create_tween()
		for i in 2:
			a0.tween_property(alert, "modulate:a", 0.3, 0.2)
			a0.tween_property(alert, "modulate:a", 0.0, 0.25)
		await get_tree().create_timer(0.55).timeout
		return
	var who: Node2D = scene.instantiate() as Node2D
	var end_scale := Vector2(2.6, 2.6)
	if alert_flash:
		var a := create_tween()
		for i in 2:
			a.tween_property(alert, "modulate:a", 0.3, 0.2)
			a.tween_property(alert, "modulate:a", 0.0, 0.25)
	_sfx(SFX_KNOCK)
	var g := create_tween()
	g.tween_property(glow, "modulate:a", 0.6, 0.25)
	g.tween_property(glow, "modulate:a", 0.0, 0.7)
	await get_tree().create_timer(0.55).timeout
	char_layer.add_child(who)
	current_char = who
	who.position = door
	who.scale = end_scale * 0.35
	who.modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(who, "position", spot, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(who, "scale", end_scale, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(who, "modulate:a", 1.0, 0.4)
	var spr := who.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr:
		var h := create_tween()
		for i in 3:
			h.tween_property(spr, "position:y", -14.0, 0.15).set_trans(Tween.TRANS_SINE)
			h.tween_property(spr, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
	await t.finished
	bob_tw = who.create_tween().set_loops()
	bob_tw.tween_property(who, "position:y", spot.y - 8.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob_tw.tween_property(who, "position:y", spot.y, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Burbuja con rebote + texto que se escribe poco a poco mientras habla
func _say(emojis: String, text: String, img: Texture2D = null, fact: Dictionary = {}, header := "INCOMING MESSAGE", credit := "", live := true) -> void:
	screen_header.text = "▌" + header
	rec_label.text = "● LIVE" if live else "● REC"
	emoji_label.text = emojis
	text_label.text = EventsData.hinted(text)
	text_label.visible_ratio = 0.0
	fact_label.visible = not fact.is_empty()
	if not fact.is_empty():
		fact_label.text = "[color=#ffb84d]NASA DATA ▸[/color] " + EventsData.hinted(fact["text"])
		fact_label.tooltip_text = "Source: %s\n%s" % [fact["source"], fact["url"]]
	photo.texture = img
	photo_frame.visible = img != null
	credit_label.text = credit
	credit_label.visible = credit != ""
	await get_tree().process_frame
	bubble.pivot_offset = bubble.size / 2.0
	bubble.scale = Vector2(0.6, 0.6)
	bubble.modulate.a = 1.0
	desk_text.modulate.a = 1.0
	create_tween().tween_property(bubble, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var spr: AnimatedSprite2D = null
	if current_char:
		spr = current_char.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr and spr.sprite_frames and spr.sprite_frames.has_animation("talk"):
		spr.play("talk")
	else:
		spr = null
	# El sonido de voz empieza en un punto distinto cada vez y se corta cuando termina de escribirse el texto
	var dur := clampf(text.length() * 0.035, 0.6, 1.8)
	talk.stream = SFX_TALK
	talk.play(randf_range(0.0, maxf(0.0, SFX_TALK.get_length() - dur)))
	typing = true
	type_tw = create_tween()
	type_tw.tween_property(text_label, "visible_ratio", 1.0, dur)
	await type_tw.finished
	typing = false
	text_label.visible_ratio = 1.0
	talk.stop()
	if spr:
		spr.play("idle")

func _sfx(s: AudioStream) -> void:
	sfx.stream = s
	sfx.play()

# Efecto de una opcion ya "suavizado" (los efectos malos pesan menos)
func _eff(opt: int) -> Event.Benefits:
	var b: Event.Benefits = current.benOp1 if opt == 1 else current.benOp2
	return Event.Benefits.new(_soft(b.energy, false), _soft(b.food, false), _soft(b.water, false), b.radiation)

func _soft(v: int, bad_when_positive: bool) -> int:
	if (v > 0) == bad_when_positive and v != 0:
		return roundi(v * NEG_SCALE)
	return v

# Si el texto aun se esta escribiendo, el clic solo lo completa (no elige)
func _skip_typing() -> void:
	if type_tw and type_tw.is_valid():
		type_tw.custom_step(10.0)

func _choose(opt: int) -> void:
	if typing:
		_skip_typing()
		return
	if busy:
		return
	busy = true
	Transition.click()
	if tutorial:
		_tutorial_next()
		return
	if announcing:
		_announce_done()
		return
	_clear_preview()
	var ben := _eff(opt)
	var ok := true
	if opt == 1 and current.winChance < 100.0:
		ok = randf() * 100.0 < current.winChance
	if not ok:
		# Fallo: solo se pierde lo que costaba, mas un susto de energia
		ben = Event.Benefits.new(mini(ben.energy, 0) - FAIL_PENALTY, mini(ben.food, 0) - FAIL_EXTRA, mini(ben.water, 0) - FAIL_EXTRA, 0)
		if current.fail1 != null:
			ben = _sum(ben, current.fail1)
	_show_deltas(ben, true)
	Resources.apply(ben)
	var nm: Dictionary = current.mod1 if opt == 1 else current.mod2
	var lm: Dictionary = current.later1 if opt == 1 else current.later2
	if current.problem and opt == 1 and ok:
		_solve(current.id)
	else:
		if ok and not nm.is_empty():
			_add_effect(mods, current, nm)
		if ok and not lm.is_empty():
			_add_effect(pending, current, lm)
		if current.problem:
			_open_problem(current)
	if ok and opt == 1 and current.expedition:
		astro_away = maxi(astro_away, int(lm.get("days", nm.get("days", 1))))
	elif not ok and current.expedition:
		astro_away = maxi(astro_away, 1)
	var bld: String = current.build1 if opt == 1 else current.build2
	if ok and bld != "":
		built[bld] = true
	if current.warns != "":
		# Aviso de la NASA: el desastre ocurre manana seguro; si te preparaste (opcion 1) no pierdes nada
		scheduled = {"id": current.warns, "ready": opt == 1 and ok}
	if opt == 2 and current.tutorial and current.type == Event.Type.COMMS:
		retry.append(current.id)
	_refresh_mods()
	if not ok:
		_pop_banner("😵")
	if not ok or ben.radiation >= 8 or minf(minf(ben.energy, ben.food), ben.water) <= -12:
		_shake()
	await get_tree().create_timer(1.6).timeout
	await _dismiss()
	if _check_end():
		return
	if sit_idx >= visitors_today:
		await _end_day()
		if _check_end():
			return
		_begin_day()
	else:
		_next_event()

# Apunta un efecto (modificador o efecto diferido) con su origen. Los permanentes y los de problemas no se duplican.
func _add_effect(list: Array, src: Event, e: Dictionary) -> void:
	if e["days"] < 0 or src.problem:
		for x in list:
			if x.get("src", "") == src.id and x["label"] == e["label"]:
				return
	var c := e.duplicate()
	c["src"] = src.id
	c["day"] = day
	list.append(c)

# Problema sin arreglar: vuelve cada dia y, si tiene cuenta atras de game over, esta empieza
func _open_problem(ev: Event) -> void:
	if not unresolved.has(ev.id):
		unresolved.append(ev.id)
	if ev.later2.has("doom"):
		_add_effect(pending, ev, ev.later2)

# Problema arreglado: ya no vuelve y desaparecen sus efectos
func _solve(id: String) -> void:
	unresolved.erase(id)
	mods = mods.filter(func(m: Dictionary) -> bool: return m.get("src", "") != id)
	pending = pending.filter(func(p: Dictionary) -> bool: return p.get("src", "") != id)

# Cae la noche: la base gasta recursos y los efectos activos pasan un dia
func _end_day() -> void:
	create_tween().tween_property(night, "modulate:a", 1.0, 0.6)
	create_tween().tween_property(night_label, "modulate:a", 1.0, 0.6)
	await get_tree().create_timer(0.7).timeout
	# Efectos que llegan unos dias despues (y fugas sin reparar que acaban la partida)
	var arrived := Event.Benefits.new()
	for p in pending:
		p["days"] -= 1
		if p["days"] <= 0:
			arrived = _sum(arrived, p["ben"])
			if p.has("doom") and doom == "":
				doom = p["doom"]
	pending = pending.filter(func(p: Dictionary) -> bool: return p["days"] > 0)
	astro_away = maxi(astro_away - 1, 0)
	var total := _sum(_daily(), arrived)
	_show_deltas(total, true)
	Resources.apply(total)
	if not today_event.is_empty():
		today_left -= 1
		if today_left <= 0:
			today_event = {}
	for m in mods:
		if m["days"] > 0:
			m["days"] -= 1
	mods = mods.filter(func(m: Dictionary) -> bool: return m["days"] != 0)
	_refresh_mods()
	await get_tree().create_timer(1.8).timeout
	day += 1
	_refresh_mods()
	var t := create_tween().set_parallel(true)
	t.tween_property(night, "modulate:a", 0.0, 0.6)
	t.tween_property(night_label, "modulate:a", 0.0, 0.6)
	await t.finished

func _sum(a: Event.Benefits, b: Event.Benefits) -> Event.Benefits:
	return Event.Benefits.new(a.energy + b.energy, a.food + b.food, a.water + b.water, a.radiation + b.radiation)

func _delta_of(b: Event.Benefits, res: int) -> int:
	return [b.energy, b.food, b.water, b.radiation][res]

func _show_deltas(b: Event.Benefits, flash: bool) -> void:
	for info in stats:
		var res: int = info["res"]
		var d := _delta_of(b, res)
		var lbl: Label = bars[res]["delta"]
		var old = tw.get(res)
		if old:
			old.kill()
		if d == 0:
			lbl.modulate.a = 0.0
			continue
		var good := (d > 0) != (res == Resources.SpaceResource.RADIATION)
		lbl.text = "%+d" % d
		lbl.add_theme_color_override("font_color", Color("86efac") if good else Color("fca5a5"))
		lbl.modulate.a = 1.0 if flash else 0.9
		if flash:
			var t := create_tween()
			t.tween_interval(1.4)
			t.tween_property(lbl, "modulate:a", 0.0, 0.4)
			tw[res] = t

func _clear_preview() -> void:
	_show_deltas(Event.Benefits.new(), false)

func _on_resource_changed(res: int, v: int) -> void:
	if not bars.has(res):
		return
	var b: Dictionary = bars[res]
	var bar = b["bar"]
	create_tween().tween_property(bar, "value", float(v), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	(b["val"] as Label).text = str(v)
	var danger := float(v) / 100.0
	if res != Resources.SpaceResource.RADIATION:
		danger = 1.0 - danger
	bar.fill_color = (b["color"] as Color).lerp(Color("ef4444"), clampf((danger - 0.6) / 0.4, 0.0, 1.0))
	_refresh_tips()

func _pop_banner(txt: String) -> void:
	banner.text = txt
	await get_tree().process_frame
	banner.pivot_offset = banner.size / 2.0
	banner.scale = Vector2(0.2, 0.2)
	banner.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(banner, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.5)
	t.tween_property(banner, "modulate:a", 0.0, 0.3)

func _shake() -> void:
	var t := create_tween()
	for i in 6:
		t.tween_property(self, "position", Vector2(randf_range(-8, 8), randf_range(-8, 8)), 0.04)
	t.tween_property(self, "position", Vector2.ZERO, 0.05)

# El visitante vuelve a la puerta y se va
func _dismiss() -> void:
	talk.stop()
	if bob_tw:
		bob_tw.kill()
	var t := create_tween().set_parallel(true)
	t.tween_property(bubble, "modulate:a", 0.0, 0.3)
	t.tween_property(desk_text, "modulate:a", 0.0, 0.3)
	var c := current_char
	current_char = null
	if c:
		t.tween_property(c, "position", size * DOOR, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_property(c, "scale", c.scale * 0.35, 0.7)
		t.tween_property(c, "modulate:a", 0.0, 0.5).set_delay(0.2)
	await t.finished
	if c:
		c.queue_free()

# ---------- Final ----------

func _check_end() -> bool:
	var R := Resources
	var reason := doom
	if reason != "":
		pass
	elif R.getResource(R.SpaceResource.ENERGY) <= 0:
		reason = "⚡ No energy! The base went dark."
	elif R.getResource(R.SpaceResource.FOOD) <= 0:
		reason = "🥬 No food! The crew is hungry."
	elif R.getResource(R.SpaceResource.WATER) <= 0:
		reason = "💧 No water! Nobody can drink."
	elif R.getResource(R.SpaceResource.RADIATION) >= 100:
		reason = "☢️ Too much radiation! It is not safe."
	if reason != "":
		if infinite:
			reason += "\n" + _record_text()
		_show_end(false, reason)
		return true
	if not infinite and day > WIN_DAY:
		_show_end(true, "You kept the crew safe for %d days!" % WIN_DAY)
		return true
	return false

# Modo infinito: dias completados y record guardado
func _record_text() -> String:
	var survived := day - 1
	var best := Settings.best_days
	if survived > best:
		Settings.set_best(survived)
		return "You survived %d days. New record!" % survived
	return "You survived %d days. Record: %d" % [survived, best]

func _show_end(won: bool, reason: String) -> void:
	var dim := _rect(Color(0.02, 0.03, 0.1, 0.88), 0.0, 0.0, 1.0, 1.0)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	dim.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var big := Label.new()
	big.text = "🏆" if won else "💥"
	big.add_theme_font_size_override("font_size", 140)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(big)
	var title := Label.new()
	title.text = "You survived!" if won else "Game over"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color("ffd166"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var why := Label.new()
	why.text = reason
	why.add_theme_font_size_override("font_size", 34)
	why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(why)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 28)
	box.add_child(hb)
	var again := Button.new()
	again.text = "Play again"
	again.add_theme_font_size_override("font_size", 34)
	again.custom_minimum_size = Vector2(300, 90)
	again.pressed.connect(func() -> void:
		Transition.click()
		Transition.go(scene_file_path))
	var menu := Button.new()
	menu.text = "Menu"
	menu.add_theme_font_size_override("font_size", 34)
	menu.custom_minimum_size = Vector2(300, 90)
	menu.pressed.connect(func() -> void:
		Transition.click()
		Transition.go(MAIN_SCENE))
	for b in [again, menu]:
		UIStyle.juicy(b)
		hb.add_child(b)
	create_tween().tween_property(dim, "modulate:a", 1.0, 0.5)
	await get_tree().process_frame
	big.pivot_offset = big.size / 2.0
	big.scale = Vector2(0.2, 0.2)
	create_tween().tween_property(big, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
