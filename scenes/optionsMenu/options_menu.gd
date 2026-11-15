extends Control

const UIStyle = preload("res://scripts/ui_style.gd")
const MAIN_SCENE := "res://scenes/mainScene/main_scene.tscn"
const MUSIC := preload("res://assets/audio/music/Musica_Menu(Nocturnal Breathing - Rand Aldo).mp3")

var _fs: CheckButton
var _fs_lock := 0.0  # tras pulsar, el navegador tarda un instante en entrar en pantalla completa

func _ready() -> void:
	theme = UIStyle.make_theme()
	Transition.music(MUSIC)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/menus/backgroundMenu.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.plate(Color("0d1116"), Color("3a4656"), 4, 28))
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(560, 0)
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Options"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color("ffd166"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	box.add_child(_volume_row("Music", Settings.music_volume, Settings.set_music, false))
	box.add_child(_volume_row("Sound effects", Settings.sfx_volume, Settings.set_sfx, true))

	_fs = CheckButton.new()
	_fs.text = "Fullscreen"
	_fs.button_pressed = Settings.is_fullscreen()
	_fs.toggled.connect(func(on: bool) -> void:
		_fs_lock = 0.8
		Settings.set_fullscreen(on))
	box.add_child(_fs)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(0, 80)
	back.pressed.connect(func() -> void:
		Settings.save()
		Transition.click()
		Transition.go(MAIN_SCENE))
	UIStyle.juicy(back)
	box.add_child(back)

	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.4)

# Si el jugador sale de pantalla completa con Esc (o el navegador la rechaza), la casilla se actualiza sola
func _process(delta: float) -> void:
	if _fs_lock > 0.0:
		_fs_lock -= delta
		return
	var on := Settings.is_fullscreen()
	if _fs.button_pressed != on:
		_fs.set_pressed_no_signal(on)

# Una fila "nombre ... 80%" con su slider. preview_click: suena un clic al soltar para oir el nivel.
func _volume_row(label: String, start: float, setter: Callable, preview_click: bool) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var head := HBoxContainer.new()
	row.add_child(head)
	var name_label := Label.new()
	name_label.text = label
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	var pct := Label.new()
	pct.text = "%d%%" % roundi(start * 100.0)
	pct.add_theme_color_override("font_color", UIStyle.AMBER)
	head.add_child(pct)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size.y = 28
	slider.value = start
	slider.value_changed.connect(func(v: float) -> void:
		setter.call(v)
		pct.text = "%d%%" % roundi(v * 100.0))
	slider.drag_ended.connect(func(_changed: bool) -> void:
		Settings.save()
		if preview_click:
			Transition.click())
	row.add_child(slider)
	return row
