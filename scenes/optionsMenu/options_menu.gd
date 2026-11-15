extends Control

const UIStyle = preload("res://scripts/ui_style.gd")
const MAIN_SCENE := "res://scenes/mainScene/main_scene.tscn"

func _ready() -> void:
	theme = UIStyle.make_theme()
	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/menus/backgroundMenu.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(520, 0)
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Options"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color("ffd166"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var vol_label := Label.new()
	vol_label.text = "Volume"
	box.add_child(vol_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size.y = 28
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	slider.value_changed.connect(func(v: float) -> void:
		AudioServer.set_bus_volume_db(0, linear_to_db(v)))
	box.add_child(slider)

	var fs := CheckButton.new()
	fs.text = "Fullscreen"
	fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.toggled.connect(func(on: bool) -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
	box.add_child(fs)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(0, 80)
	back.pressed.connect(func() -> void:
		Transition.click()
		Transition.go(MAIN_SCENE))
	UIStyle.juicy(back)
	box.add_child(back)

	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.4)
