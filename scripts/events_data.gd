extends Node

# events: decisiones (llegan visitantes por la puerta). day_events: modificadores del dia (alertas al empezar el dia).
var events: Dictionary = {}
var day_events: Dictionary = {}

var Astronaut: PackedScene = load("res://scenes/characters/astronaut/astronaut.tscn")
var Farmer: PackedScene = load("res://scenes/characters/farmer/farmer.tscn")
var Radio: PackedScene = load("res://scenes/characters/radio/radio.tscn")
var Scientist: PackedScene = load("res://scenes/characters/scientist/scientist.tscn")

var ImgFlare: Texture2D = load("res://assets/sprites/event_images/solar_flare_cabron.png")
var ImgDust: Texture2D = load("res://assets/sprites/event_images/dust_devil.jpg")
var ImgMeteor: Texture2D = load("res://assets/sprites/event_images/mars_meteorite.png")
var ImgReactor: Texture2D = load("res://assets/sprites/event_images/Nuclear_reactor.jpg")

const CH := Event.Type.CHARACTER
const CO := Event.Type.COMMS

# Indices de recurso (igual que Resources.SpaceResource): 0 energia, 1 comida, 2 agua, 3 radiacion
const R_ENERGY := 0
const R_FOOD := 1
const R_WATER := 2
const R_RAD := 3

# Palabras clave -> explicacion corta (tooltip). Claves en minuscula.
var glossary: Dictionary = {
	"solar flare": "A giant burst of light and energy from the Sun. The NASA DONKI database keeps track of them!",
	"radiation dose": "How much radiation a body soaks up, measured in millisieverts (mSv). On the surface of Mars, the NASA Curiosity rover measured about 0.67 mSv per day, around 100 times more than on Earth!",
	"radiation": "Invisible energy that can hurt our bodies. Mars has thin air and no magnetic shield, so it gets lots of it.",
	"meteor": "A space rock that glows as it falls. Mars has very thin air, so more rocks reach the ground than on Earth!",
	"dust devil": "A small whirlwind of dust. NASA rovers have photographed many on Mars!",
	"reactor": "A machine that makes lots of energy from tiny atoms.",
	"antenna": "It sends radio messages to Earth. Messages take 4 to 24 minutes to arrive!",
	"solar panels": "They turn sunlight into electricity.",
	"oxygen": "The gas we breathe. Mars air is mostly carbon dioxide, so astronauts must make their own oxygen!",
	"toxins": "Poisons that can make you sick.",
	"ice": "Frozen water! NASA has found lots of ice under the surface of Mars.",
	"greenhouse": "A protected house where plants can grow safely.",
	"shield": "A wall that blocks radiation so the crew stays safe.",
	"rover": "A robot car that explores Mars. Curiosity and Perseverance, from NASA, are rovers!",
	"nasa": "The space agency of the USA. It sends rockets, rovers and astronauts to explore space and Mars!",
	"donki": "The Space Weather Database Of Notifications, Knowledge, Information from NASA.",
}

# --- Datos reales de la NASA ---
# data/nasa_facts.json: hechos con fuente + lista de llamaradas reales.
# Si existe data/donki_flares.json (lo genera tools/fetch_donki.py) sus llamaradas sustituyen a las de nasa_facts.json.
var nasa: Dictionary = {}
var flares: Array = []
var nasa_images: Dictionary = {}  # id de evento -> {credit, title, nasa_id, page} (lo genera tools/fetch_nasa_images.py)

const NASA_IMG_DIR := "res://assets/sprites/event_images/nasa/"

# Foto real de la NASA de un evento (assets/sprites/event_images/nasa/<id>.jpg). null si no se ha descargado.
func nasa_photo(id: String) -> Texture2D:
	var path := NASA_IMG_DIR + id + ".jpg"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func photo_credit(id: String) -> String:
	if not nasa_images.has(id):
		return ""
	return str((nasa_images[id] as Dictionary).get("credit", ""))

func _load_nasa() -> void:
	nasa = _load_json("res://data/nasa_facts.json")
	nasa_images = _load_json("res://data/nasa_images.json")
	flares = nasa.get("flares", [])
	var real := _load_json("res://data/donki_flares.json")
	if real.has("flares") and (real["flares"] as Array).size() > 0:
		flares = real["flares"]

# Los .json se importan como recurso JSON, asi tambien van incluidos en la exportacion web.
func _load_json(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return {}
	var res: Resource = load(path)
	if res is JSON and (res as JSON).data is Dictionary:
		return (res as JSON).data
	return {}

func _make_fact(text: String, source_id: String) -> Dictionary:
	var s: Dictionary = nasa.get("sources", {}).get(source_id, {})
	return {"text": text, "source": s.get("title", "NASA"), "url": s.get("url", "")}

# Hecho real de la NASA asociado a un evento (id de evento o de evento del dia). {} si no hay.
func fact_for(id: String) -> Dictionary:
	var fid: String = nasa.get("events", {}).get(id, "")
	var f: Dictionary = nasa.get("facts", {}).get(fid, {})
	if f.is_empty():
		return {}
	return _make_fact(f["text"], f["source"])

# Una llamarada solar real al azar (DONKI / lista de 2024).
func flare_fact() -> Dictionary:
	if flares.is_empty():
		return {}
	var f: Dictionary = flares.pick_random()
	var cls: String = f.get("class", "?")
	var text := "On %s NASA recorded a real %s solar flare." % [f.get("date", "?"), cls]
	if cls.begins_with("X"):
		text += " X-class is the strongest kind!"
	var fact := _make_fact(text, f.get("source", "donki"))
	fact["date"] = f.get("date", "?")
	return fact

# Copia del evento del dia con su dato real. La llamarada solar usa una llamarada real de la base de datos.
func day_event_today(id: String) -> Dictionary:
	var d: Dictionary = day_events[id].duplicate()
	var fact := fact_for(id)
	if id == "solar_flare":
		var ff := flare_fact()
		if not ff.is_empty():
			fact = ff
			d["text"] = "A solar flare! NASA saw a real one on %s. There will be more radiation tonight." % ff["date"]
	if not fact.is_empty():
		d["fact"] = fact
	# si el evento no trae foto propia, usa la de la NASA (si esta descargada)
	if d.get("photo") == null:
		var ph := nasa_photo(id)
		if ph != null:
			d["photo"] = ph
			d["credit"] = photo_credit(id)
	return d

func _ready() -> void:
	_load_nasa()
	# --- Decisiones ---
	_r("farm1", "🧑‍🌾😢🔧", "My rake broke! Can you help me?", CH,
		_b(-10), "Fix it", _b(0, -10), "No", Farmer)
	_r("send_report", "📻🌍📝", "Earth wants a report. Use the antenna?", CO,
		_b(-10), "Short", _b(-20), "Long", Radio)
	_r("expedition1", "👨‍🚀🕳️💎", "I found a cave with resources!", CH,
		_b(0, 0, 10, 10), "Go!", _b(), "Stay", Astronaut, 80.0)
	_r("expedition2", "👨‍🚀🧊❓", "There is ice far away. Look for water?", CH,
		_b(0, 0, 20, 20), "Go!", _b(), "Stay", Astronaut, 60.0)
	_r("expedition3", "👨‍🚀🧊⚡", "Ice and energy very far! Risky trip.", CH,
		_b(20, 0, 30, 20), "Go!", _b(), "Stay", Astronaut, 40.0)
	_r("expedition4", "👨‍🚀🏚️🔎", "Let me search an old abandoned base!", CH,
		_b(15, 0, 0, 10), "Go!", _b(), "Stay", Astronaut, 80.0)
	_r("farm2", "🧑‍🌾🥬🌱", "Can I plant extra lettuce?", CH,
		_b(-5, 10), "Plant", _b(0, -20), "No", Farmer, 70.0)
	_r("farm3", "🧑‍🌾💧🛡️", "Water to protect my plants?", CH,
		_b(0, 0, -15), "Yes", _b(0, -15), "No", Farmer)
	_r("farm4", "🧑‍🌾⛏️🏠", "Can we build an underground greenhouse?", CH,
		_b(-15, 15, -5), "Build", _b(0, -15), "No", Farmer, 70.0)
	_r("seeds", "🧑‍🌾🌰🌱", "New seeds! They need some water.", CH,
		_b(0, 0, -10), "Plant", _b(), "No", Farmer)
	_r("for_science", "🧑‍🔬🥬🔬", "Can I borrow some food for science?", CH,
		_b(0, -20), "Yes", _b(), "No", Scientist, 65.0)
	_r("science2", "🧑‍🔬☢️🌿", "Which plants resist radiation best?", CH,
		_b(-10, 5), "Research", _b(0, -5), "No", Scientist, 50.0)
	_r("water_production", "🧑‍🔬♻️💧", "I can recycle water! It needs energy.", CH,
		_b(-15, 0, 10), "Yes", _b(), "No", Scientist)
	_r("shield", "🧑‍🔬🛡️☢️", "I can make our shield stronger against radiation!", CH,
		_b(-12, 0, 0, -20), "Build", _b(), "No", Scientist)
	_r("suit", "👨‍🚀🧵🔧", "My suit has a hole! Can you help fix it?", CH,
		_b(-8), "Fix it", _b(0, 0, 0, 15), "No", Astronaut)
	_r("panels", "👨‍🚀🧽☀️", "Let me clean the solar panels!", CH,
		_b(0, 0, -5), "Clean", _b(), "No", Astronaut)
	_r("rover", "📻🤖🔬", "NASA wants rock samples from the rover!", CO,
		_b(-10, 0, 10), "Send", _b(), "No", Radio)
	_r("lack_of_oxygen", "📻💨🆘", "We need more oxygen!", CO,
		_b(-15), "Some", _b(-25), "Lots", Radio)
	_mods()
	# --- Eventos del dia: salen al empezar el dia y cambian lo que ganas por la noche ---
	# _d(id, emojis, texto, etiqueta, efecto de esta noche, produccion bloqueada, foto)
	_d("dust_devil", "🌪️🧹😮", "A dust devil! The solar panels make no energy today.",
		"Dust devil", _b(), [R_ENERGY], ImgDust)
	_d("solar_flare", "☀️💥😰", "A solar flare! There will be more radiation tonight.",
		"Solar flare", _b(0, 0, 0, 20), [], ImgFlare)
	_d("meteor_rain", "☄️☄️😱", "A meteor shower! Some water and power are lost.",
		"Meteors", _b(-5, 0, -8), [], ImgMeteor)
	_d("bright_sun", "☀️🔋✨", "Bright Sun! The solar panels make extra energy.",
		"Bright Sun", _b(8), [], null)
	_d("reactor", "☢️⚠️🔧", "The reactor is in trouble! Less energy, more radiation.",
		"Reactor trouble", _b(-6, 0, 0, 10), [], ImgReactor)
	_d("bad_harvest", "🥬🥀😟", "A bad harvest! The farm makes no food today.",
		"Bad harvest", _b(), [R_FOOD], null)
	_d("toxins", "💧☠️😷", "Toxins in the water! Some water is lost.",
		"Toxic water", _b(0, 0, -8), [], null)
	_d("oxygen_leak", "💨😰🔧", "An oxygen leak! The crew fixes it with power and water.",
		"Oxygen leak", _b(-6, 0, -4), [], null)
	_d("hard_ground", "⛏️🏜️😓", "The ground is too hard! The pump makes no water today.",
		"Hard ground", _b(), [R_WATER], null)
	_d("quiet_sun", "☀️😌🛡️", "A quiet Sun. There is less radiation today!",
		"Quiet Sun", _b(), [R_RAD], null)

# Efectos que duran varios dias (opt 1 o 2): se ven en el tooltip de las barras
func _mods() -> void:
	_mod("farm4", 1, "🏠 Greenhouse", _b(0, 3), 5)
	_mod("water_production", 1, "♻️ Recycler", _b(0, 0, 3), 4)
	_mod("shield", 1, "🛡️ Strong shield", _b(0, 0, 0, -4), 4)
	_mod("panels", 1, "✨ Clean panels", _b(3), 3)
	_mod("seeds", 1, "🌿 New crops", _b(0, 3), 4)

func _mod(id: String, opt: int, label: String, ben: Event.Benefits, days: int) -> void:
	var m := {"label": label, "ben": ben, "days": days}
	if opt == 1:
		events[id].mod1 = m
	else:
		events[id].mod2 = m

func _b(e := 0, f := 0, w := 0, r := 0) -> Event.Benefits:
	return Event.Benefits.new(e, f, w, r)

func _r(id: String, emojis: String, short: String, type: Event.Type,
		op1: Event.Benefits, l1: String, op2: Event.Benefits, l2: String,
		character: PackedScene = null, win := 100.0, photo: Texture2D = null) -> void:
	var ev := Event.new(id, short, type, op1, op2, 0, photo, character, win)
	ev.emojis = emojis
	ev.label1 = l1
	ev.label2 = l2
	events[id] = ev

func _d(id: String, emojis: String, text: String, label: String, ben: Event.Benefits,
		block: Array, photo: Texture2D) -> void:
	day_events[id] = {"id": id, "emojis": emojis, "text": text, "label": label,
		"ben": ben, "block": block, "photo": photo}

# Convierte palabras clave del texto en [hint] de RichTextLabel (tooltip al pasar el raton).
func hinted(text: String) -> String:
	var keys: Array = glossary.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	var rx := RegEx.new()
	rx.compile("(?i)\\b(" + "|".join(PackedStringArray(keys)) + ")\\b")
	var out := ""
	var last := 0
	for m in rx.search_all(text):
		out += text.substr(last, m.get_start() - last)
		var word := m.get_string()
		# Red de seguridad: un apostrofe o un corchete en el valor del hint rompe el parseo de BBCode en Godot
		var tip: String = glossary[word.to_lower()]
		tip = tip.replace("'", "\u2019").replace("[", "(").replace("]", ")")
		out += "[hint=%s][color=#7dd3fc]%s[/color][/hint]" % [tip, word]
		last = m.get_end()
	return out + text.substr(last)
