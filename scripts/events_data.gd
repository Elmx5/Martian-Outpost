extends Node

# events: decisiones (llegan visitantes por la puerta o saltan avisos de la base).
# day_events: alertas que salen al empezar el dia y cambian lo que pasa por la noche (no hay que decidir nada).
# Catalogo basado en "Tabla eventos de decision.xlsx". Documentacion: docs/eventos_y_datos.md
var events: Dictionary = {}
var day_events: Dictionary = {}
var tutorial_ids: Array = []  # tutoriales que salen el dia 1, en este orden

var Astronaut: PackedScene = load("res://scenes/characters/astronaut/astronaut.tscn")
var Farmer: PackedScene = load("res://scenes/characters/farmer/farmer.tscn")
var Radio: PackedScene = load("res://scenes/characters/radio/radio.tscn")
var Scientist: PackedScene = load("res://scenes/characters/scientist/scientist.tscn")

var ImgFlare: Texture2D = load("res://assets/sprites/event_images/solar_flare_cabron.png")
var ImgReactor: Texture2D = load("res://assets/sprites/event_images/Nuclear_reactor.jpg")
var ImgMeteor: Texture2D = load("res://assets/sprites/event_images/mars_meteorite.png")

const CH := Event.Type.CHARACTER
const CO := Event.Type.COMMS
const EV := Event.Type.EVENT

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
	"dust storm": "A giant cloud of dust. On Mars it can cover the whole planet and block the sunlight that solar panels need!",
	"dust devil": "A small whirlwind of dust. NASA rovers have photographed many on Mars!",
	"reactor": "A machine that makes lots of energy from tiny atoms.",
	"fission surface power": "A small nuclear power plant for the Moon and Mars. NASA tested a small version called Kilopower!",
	"water treatment plant": "A machine that cleans dirty water so we can drink it again. The space station recycles about 98% of its water!",
	"antenna": "It sends radio messages to Earth. Messages take 4 to 24 minutes to arrive!",
	"pre-recorded": "Recorded earlier. You cannot answer it, because nobody is talking live. NASA can only talk live after you build the antenna!",
	"satellite": "A machine that circles a planet and watches it from above. NASA satellites around Mars map ice, dust and weather!",
	"orbiter": "A spacecraft that travels around a planet to study it from above.",
	"lava tunnel": "A long underground cave made by flowing lava a very long time ago.",
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
func day_event_today(id: String, ready := false) -> Dictionary:
	var d: Dictionary = day_events[id].duplicate()
	var fact := fact_for(id)
	if id == "solar_flare":
		var ff := flare_fact()
		if not ff.is_empty():
			fact = ff
			d["text"] = "A solar flare just started! NASA saw a real one on %s. Radiation doubles for 2 days." % ff["date"]
	if ready:
		# NASA te aviso ayer y te preparaste: hoy el desastre llega pero no pierdes nada
		if d["ready"] != "":
			d["text"] = d["ready"]
		d["ben"] = Event.Benefits.new()
		d["block"] = []
		d["mult"] = {}
		d["days"] = 1
		d["label"] = String(d["label"]) + " (prepared)"
		d["prepared"] = true
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
	# ===== TUTORIAL (dia 1): mensajes PREGRABADOS de la NASA. Aun no hay antena, asi que no hablan en directo.
	# Construir CUESTA recursos y solo da mejoras PASIVAS (produccion cada noche), nunca recursos al momento.
	# Si dices que no, el mensaje vuelve al dia siguiente. =====
	_r("build_farm", "📻🌱🏗️", "Build a farm to start producing food", CO,
		_b(-15, 0, -10), "Build", _b(), "Not now", Radio)
	_build("build_farm", 1, "farm")
	_tut("build_farm")
	_r("build_panels", "📻☀️🏗️", "Build some solar panels to start producing electricity", CO,
		_b(0, -10, -15), "Build", _b(), "Not now", Radio)
	_build("build_panels", 1, "panels")
	_tut("build_panels")
	_r("build_water", "📻💧🏗️", "Build a water treatment plant to start cleaning our water", CO,
		_b(-10, -15), "Build", _b(), "Not now", Radio)
	_build("build_water", 1, "water")
	_tut("build_water")
	_r("build_antenna", "📻📡🏗️", "Build an antenna so we can talk to you live. Until then, our messages are pre-recorded", CO,
		_b(-20, -10), "Build", _b(), "Not now", Radio)
	_build("build_antenna", 1, "antenna")
	_tut("build_antenna")

	# ===== EXPEDICIONES (Anthony Clark): el premio llega unos dias DESPUES; si falla, no llega nada =====
	_r("cave", "👨‍🚀🕳️💎", "I found an interesting cave with useful resources", CH,
		_b(), "Go!", _b(), "Stay", Astronaut, 80.0)
	_later("cave", 1, "🕳️ Cave expedition", _b(0, 0, 10, 5), 1)
	_expedition("cave")
	_r("ice", "👨‍🚀🧊❓", "There is some ice a bit further from the base, but there could be some risk", CH,
		_b(), "Go!", _b(), "Stay", Astronaut, 60.0)
	_later("ice", 1, "🧊 Ice expedition", _b(0, 0, 20, 10), 2)
	_expedition("ice")
	_r("cliff", "👨‍🚀🧗⚠️", "I discovered a dangerous cliff. It is a risky operation, but it could reward us", CH,
		_b(), "Go!", _b(), "Stay", Astronaut, 40.0)
	_later("cliff", 1, "🧗 Cliff expedition", _b(20, 0, 30, 15), 2)
	_expedition("cliff")
	_r("old_base", "👨‍🚀🏚️🔎", "I want to search an old abandoned base", CH,
		_b(0, 0, 0, 10), "Search", _b(), "No", Astronaut, 80.0)
	_mod("old_base", 1, "🏚️ Old base salvage", _b(15), 1)
	_expedition("old_base")

	# ===== GRANJA (John Rake) =====
	_r("new_crops", "🧑‍🌾🌶️🌱", "We are having problems with our farms. I want to try planting other types of food", CH,
		_b(-5), "Try it", _b(), "No", Farmer, 70.0)
	_mod("new_crops", 1, "🌶️ New crops", _b(0, 6), 3)
	_mod("new_crops", 2, "🥀 Failing farms", _b(0, -10), 2)
	_r("greenhouse", "🧑‍🌾⛏️🏠", "I want to build an underground greenhouse to produce more food", CH,
		_b(-20, 0, -10), "Build", _b(), "No", Farmer, 70.0)
	_mod("greenhouse", 1, "🏠 Greenhouse", _b(0, 4), -1)
	_r("rake", "🧑‍🌾🔧💔", "My rake broke while I was harvesting some lettuce. Could I have some resources to repair it?", CH,
		_b(-10), "Repair it", _b(), "No", Farmer)
	_mod("rake", 2, "🔧 Broken rake", _b(0, -10), -1)
	_problem("rake")
	_tut("rake")
	_r("protect_plants", "🧑‍🌾💧🛡️", "I want to use some of our water to make a protection for our plants", CH,
		_b(0, 0, -15), "Use water", _b(0, -15), "No", Farmer)

	# ===== CIENCIA (Sandra Hawkins) =====
	_r("research_veg", "🧑‍🔬🥬🔬", "I need to research our vegetables to make them more resistant to the harsh Martian climate. Could I borrow some?", CH,
		_b(0, -20), "Lend food", _b(), "No", Scientist, 65.0)
	_mod("research_veg", 1, "🧪 Tougher plants", _b(0, 2), -1)
	_r("rad_plants", "🧑‍🔬☢️🌿", "I want to find out which plants resist radiation best", CH,
		_b(-10), "Research", _b(0, -5), "No", Scientist, 50.0)
	_mod("rad_plants", 1, "🌿 Radiation-proof plants", _b(0, 2), -1)
	_r("water_fluids", "🧑‍🔬♻️💧", "I want to use some energy to make water from human fluids", CH,
		_b(-15, 0, 10), "Recycle", _b(0, 0, 0, 10), "No", Scientist)

	# ===== RADIO DE LA NASA =====
	_r("fission_power", "📻⚛️⚡", "We want you to build a Fission Surface Power system to produce more energy", CO,
		_b(-10, 0, -15), "Build", _b(), "No", Radio)
	_mod("fission_power", 1, "⚛️ Fission power", _b(8), -1)

	# ===== NASA EN DIRECTO (solo con la antena construida): descubrimientos de satelites, consejos y avisos =====
	_r("sat_ice", "📻🛰️🧊", "Good news! Our satellite found a big ice deposit near the base. We sent you the coordinates", CO,
		_b(-10), "Go dig", _b(), "Not now", Radio, 90.0)
	_later("sat_ice", 1, "🧊 Satellite ice", _b(0, 0, 25), 2)
	_r("sat_cave", "📻🛰️🕳️", "Our orbiter spotted an old lava tunnel under your base. Thick rock is a great shield against radiation!", CO,
		_b(-15, 0, -5), "Build shelter", _b(), "Not now", Radio, 80.0)
	_mod("sat_cave", 1, "🕳️ Cave shelter", _b(0, 0, 0, -3), -1)
	_r("panel_tip", "📻🧹☀️", "NASA tip: dust is covering your solar panels. If you clean them, they will make more energy for a few days", CO,
		_b(0, 0, -8), "Clean them", _b(), "No", Radio)
	_mod("panel_tip", 1, "🧹 Clean panels", _b(3), 3)
	_needs("panel_tip", "panels")
	# Avisos: NASA predice un desastre para MANANA. Si te preparas (opcion 1) llega, pero no pierdes recursos.
	_r("storm_warning", "📻🛰️🌪️", "Warning! Our satellites predict a dust storm tomorrow. You have time to prepare!", CO,
		_b(-10), "Prepare", _b(), "Ignore", Radio)
	_warns("storm_warning", "dust_storm")
	_r("flare_warning", "📻🛰️☀️", "Warning! We saw a big solar storm leave the Sun. It reaches you tomorrow. Get ready!", CO,
		_b(-10), "Shelter up", _b(), "Ignore", Radio)
	_warns("flare_warning", "solar_flare")
	_r("report", "📻🌍📝", "What is the situation up there on Mars? It is time to send us the periodic report", CO,
		_b(-10), "Send report", _b(), "Later", Radio)
	_later("report", 2, "📝 Late report", _b(-20), 2)
	_needs("report", "antenna")
	_r("more_oxygen", "📻🫁💧", "You need to produce more oxygen", CO,
		_b(0, 0, -15), "Produce it", _b(), "No", Radio)
	_later("more_oxygen", 2, "🫁 Oxygen shortage", _b(0, 0, -25), 2)

	# ===== SUCESOS DE LA BASE (sin personaje: saltan alertas con dos botones) =====
	_r("reactor_risk", "☢️⚠️🔧", "The nuclear reactor is in danger! Do you want to take the risk to repair it before something worse happens?", EV,
		_b(0, -20, 20), "Repair it", _b(-15), "Shut down", null, 100.0, ImgReactor)
	_mod("reactor_risk", 2, "☢️ Reactor damage", _b(-10), -1)
	_problem("reactor_risk")
	_r("toxins", "💧☠️😷", "OH NO! There are toxins in the water! Do you drink it anyway?", EV,
		_b(0, 0, 15), "Drink it", _b(0, 0, -20), "Pour it out", null, 30.0)
	_fail("toxins", _b(0, 0, 0, 20))
	_r("water_dig", "⛏️💧🤔", "The water excavation is getting complicated. Do we continue or search in another place?", EV,
		_b(-10, 0, 20), "Continue", _b(-20, 0, 10), "Move", null, 65.0)
	_r("meteor_rain", "☄️💥⚠️", "Alert! A meteor rain! You have to decide if you protect the generators or the water tank", EV,
		_b(0, 0, -20), "Save generators", _b(-20), "Save water tank", null, 100.0, ImgMeteor)
	_r("oxygen_leak", "🫁💨🔧", "We have a leak in our oxygen tank! We need to repair it!", EV,
		_b(-10, 0, -5), "Repair it", _b(), "Ignore it", null, 90.0)
	_doom("oxygen_leak", 2, 3, "🫁 Oxygen leak", "🫁 The oxygen ran out! The leak was never fixed.")
	_problem("oxygen_leak")

	# ===== ALERTAS DEL DIA: salen al empezar el dia, no hay que decidir =====
	# _d(id, emojis, texto, etiqueta, efecto cada noche, produccion bloqueada, foto, noches que dura, multiplicadores, edificio requerido, texto si NASA te aviso)
	_d("solar_flare", "☀️💥😰", "A solar flare just started! Everybody run to a safe place away from radiation!",
		"Solar flare", _b(), [], ImgFlare, 2, {R_RAD: 2}, "",
		"As NASA warned, a solar flare hit. You were ready, so there is no extra radiation!")
	_d("bright_sun", "☀️🔋✨", "Mars has rotated and the sunbeams make your solar panels produce more energy!",
		"Bright Sun", _b(20), [], null, 1, {}, "panels")
	_d("dust_storm", "🌪️🧹😮", "A Martian storm! There is too much dust!",
		"Dust storm", _b(), [R_ENERGY, R_FOOD], null, 1, {}, "",
		"As NASA predicted, a Martian storm hit. You were ready, so production keeps going!")
	_d("bad_harvest", "🥬🥀😟", "We are having a bad harvest!",
		"Bad harvest", _b(), [R_FOOD], null)

func _b(e := 0, f := 0, w := 0, r := 0) -> Event.Benefits:
	return Event.Benefits.new(e, f, w, r)

# Evento de decision. op1/op2 = efecto INSTANTANEO de cada opcion. win = % de exito de la opcion 1.
func _r(id: String, emojis: String, short: String, type: Event.Type,
		op1: Event.Benefits, l1: String, op2: Event.Benefits, l2: String,
		character: PackedScene = null, win := 100.0, photo: Texture2D = null) -> void:
	var ev := Event.new(id, short, type, op1, op2, 0, photo, character, win)
	ev.emojis = emojis
	ev.label1 = l1
	ev.label2 = l2
	events[id] = ev

# Efecto que se repite cada noche. days = noches que dura; -1 = permanente.
func _mod(id: String, opt: int, label: String, ben: Event.Benefits, days: int) -> void:
	var m := {"label": label, "ben": ben, "days": days}
	if opt == 1:
		events[id].mod1 = m
	else:
		events[id].mod2 = m

# Efecto que llega UNA vez, dentro de N dias ("N days later" / "In N days" del Excel).
func _later(id: String, opt: int, label: String, ben: Event.Benefits, days: int) -> void:
	var m := {"label": label, "ben": ben, "days": days}
	if opt == 1:
		events[id].later1 = m
	else:
		events[id].later2 = m

# Edificio que se construye al elegir la opcion ("farm", "panels", "water").
func _build(id: String, opt: int, building: String) -> void:
	if opt == 1:
		events[id].build1 = building
	else:
		events[id].build2 = building

# Si eliges esa opcion, dentro de N dias se acaba la partida (ej. fuga de oxigeno sin reparar).
func _doom(id: String, opt: int, days: int, label: String, reason: String) -> void:
	var m := {"label": label, "ben": _b(), "days": days, "doom": reason}
	if opt == 1:
		events[id].later1 = m
	else:
		events[id].later2 = m

# Problema abierto: si no lo arreglas (opcion 1 con exito) vuelve a salir cada dia, con sus efectos, hasta que lo arregles.
func _problem(id: String) -> void:
	events[id].problem = true

# Expedicion del astronauta: mientras dura no puede aparecer.
func _expedition(id: String) -> void:
	events[id].expedition = true

# Efecto cuando la opcion 1 FALLA (por defecto solo pagas los costes).
func _fail(id: String, ben: Event.Benefits) -> void:
	events[id].fail1 = ben

# Marca un evento como tutorial (sale el dia 1; si lo rechazas vuelve manana).
func _tut(id: String) -> void:
	events[id].tutorial = true
	tutorial_ids.append(id)

# Evento que requiere un edificio construido (ej. "panels").
func _needs(id: String, building: String) -> void:
	events[id].requires = building

# Aviso de la NASA: el evento del dia indicado ocurrira manana. Con la opcion 1 te preparas y no pierdes recursos.
func _warns(id: String, day_event_id: String) -> void:
	events[id].warns = day_event_id

func _d(id: String, emojis: String, text: String, label: String, ben: Event.Benefits,
		block: Array, photo: Texture2D, days := 1, mult := {}, requires := "", ready := "") -> void:
	day_events[id] = {"id": id, "emojis": emojis, "text": text, "label": label,
		"ben": ben, "block": block, "photo": photo, "days": days, "mult": mult, "requires": requires, "ready": ready}

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
