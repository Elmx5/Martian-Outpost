extends Control

const UIStyle = preload("res://scripts/ui_style.gd")
const MUSIC := preload("res://assets/audio/music/Musica_Menu(Nocturnal Breathing - Rand Aldo).mp3")

@onready var title: Label = $Title
@onready var box: VBoxContainer = $VBoxContainer

func _ready() -> void:
	theme = UIStyle.make_theme()
	Transition.music(MUSIC)
	title.add_theme_color_override("font_color", Color("ffd166"))
	title.add_theme_color_override("font_outline_color", Color("1b1030"))
	title.add_theme_constant_override("outline_size", 14)
	# Titulo con fundido y flotando suavemente
	title.modulate.a = 0.0
	create_tween().tween_property(title, "modulate:a", 1.0, 0.8)
	var f := create_tween().set_loops()
	f.tween_property(title, "offset_top", 58.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	f.tween_property(title, "offset_top", 70.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Botones: crecen desde el centro uno tras otro
	await get_tree().process_frame
	var i := 0
	for b in box.get_children():
		var btn := b as Control
		btn.pivot_offset = btn.size / 2.0
		btn.scale = Vector2.ZERO
		UIStyle.juicy(btn)
		var t := create_tween()
		t.tween_interval(0.3 + 0.2 * i)
		t.tween_property(btn, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1
