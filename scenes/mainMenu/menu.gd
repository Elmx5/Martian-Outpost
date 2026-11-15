extends Control

const UIStyle = preload("res://scripts/ui_style.gd")

@onready var title: Label = $Title
@onready var box: VBoxContainer = $VBoxContainer
@onready var music: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	theme = UIStyle.make_theme()
	title.add_theme_color_override("font_color", Color("ffd166"))
	title.add_theme_color_override("font_outline_color", Color("1b1030"))
	title.add_theme_constant_override("outline_size", 14)
	music.finished.connect(music.play)
	# Entrada: titulo con fundido y botones uno a uno
	title.modulate.a = 0.0
	create_tween().tween_property(title, "modulate:a", 1.0, 0.8)
	var i := 0
	for b in box.get_children():
		b.modulate.a = 0.0
		UIStyle.juicy(b)
		var bt := create_tween()
		bt.tween_interval(0.4 + 0.2 * i)
		bt.tween_property(b, "modulate:a", 1.0, 0.4)
		i += 1
	# Titulo flotando suavemente
	var f := create_tween().set_loops()
	f.tween_property(title, "offset_top", 58.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	f.tween_property(title, "offset_top", 70.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
