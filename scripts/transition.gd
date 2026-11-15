extends CanvasLayer
# Autoload "Transition": fundidos entre escenas, clic de boton y musica que sobrevive al cambio de escena.

const BTN := preload("res://assets/audio/SFX/SFX Button.wav")

var _fade: ColorRect
var _img: TextureRect
var _sfx: AudioStreamPlayer
var _music: AudioStreamPlayer
var _busy := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.modulate.a = 0.0
	_img = TextureRect.new()
	_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_img)
	_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_img.modulate.a = 0.0
	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_music.finished.connect(func() -> void: _music.play())

func click() -> void:
	_sfx.stream = BTN
	_sfx.play()

# Musica de menu: si ya esta sonando ese mismo tema, no se reinicia (menu <-> opciones)
func music(stream: AudioStream) -> void:
	if _music.playing and _music.stream == stream:
		return
	_music.stream = stream
	_music.play()

func stop_music() -> void:
	_music.stop()

func go(path: String, card: Texture2D = null, hold := 2.5) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, 0.5)
	await t.finished
	if card:
		_img.texture = card
		t = create_tween()
		t.tween_property(_img, "modulate:a", 1.0, 0.6)
		t.tween_interval(hold)
		t.tween_property(_img, "modulate:a", 0.0, 0.6)
		await t.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	t = create_tween()
	t.tween_property(_fade, "modulate:a", 0.0, 0.5)
	await t.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
