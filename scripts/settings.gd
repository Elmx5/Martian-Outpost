extends Node
# Autoload "Settings": buses de audio (Music / SFX), volumenes guardados y pantalla completa.
# Se cargan antes que el resto de autoloads para que los reproductores ya encuentren sus buses.

const PATH := "user://settings.cfg"  # en la version web se guarda en IndexedDB (persiste entre visitas)
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var music_volume := 1.0
var sfx_volume := 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	_load()
	_apply(MUSIC_BUS, music_volume)
	_apply(SFX_BUS, sfx_volume)

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus_name)
	AudioServer.set_bus_send(i, "Master")

# v va de 0.0 a 1.0. En 0 el bus se silencia del todo.
func _apply(bus_name: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i == -1:
		return
	AudioServer.set_bus_mute(i, v <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))

func set_music(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply(MUSIC_BUS, music_volume)

func set_sfx(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply(SFX_BUS, sfx_volume)

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	music_volume = clampf(float(cfg.get_value("audio", "music", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx", 1.0)), 0.0, 1.0)

# ---- Pantalla completa ----
# En el navegador solo funciona si se pide dentro de un clic del jugador (el boton de opciones lo es).
# Si el juego esta incrustado en un <iframe> (p. ej. itch.io), el iframe necesita allow="fullscreen".

func is_fullscreen() -> bool:
	var m := DisplayServer.window_get_mode()
	return m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func set_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
