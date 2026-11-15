class_name Event # Makes the new class type
extends RefCounted # So it auto frees from memory when not longer used

class Benefits:
	var energy: int
	var food: int
	var water: int
	var radiation: int
	
	func _init(_energy := 0, _food := 0, _water := 0, _radiation := 0)->void:
		energy = _energy
		food = _food
		water = _water
		radiation = _radiation

enum Type {CHARACTER, COMMS, EVENT}

var id: String
var desc: String
var type: Type
var benOp1: Benefits
var benOp2: Benefits
var duration: int
var character: PackedScene
var photo: Texture2D
var winChance: float # percentage 0-100 (applies to option 1)
# Problema que sigue saliendo cada dia hasta que lo arreglas (la opcion 1 lo arregla); si no, se queda abierto
var problem := false
# Expedicion: el astronauta no vuelve a aparecer hasta que termina
var expedition := false

# Kid-friendly presentation
var emojis: String = "❓"
var label1: String = "Yes"
var label2: String = "No"
# Efecto que dura varios dias si se elige esa opcion: {label, ben: Benefits (por dia), days}
var mod1: Dictionary = {}
var mod2: Dictionary = {}
# Efecto que llega DESPUES de N dias si eliges esa opcion: {label, ben: Benefits, days}
var later1: Dictionary = {}
var later2: Dictionary = {}
# Edificio que se construye al elegir esa opcion ("farm", "panels", "water")
var build1 := ""
var build2 := ""
# Edificio que debe estar construido para que este evento pueda salir
var requires := ""
# Evento de tutorial: sale seguro el dia 1; si eliges la opcion 2 vuelve al dia siguiente
var tutorial := false
# Efecto si la opcion 1 FALLA (null = solo pagas los costes de la opcion)
var fail1: Benefits = null
# Aviso de la NASA: id del evento del dia que ocurrira MANANA. Si eliges la opcion 1 te preparas y no pierdes recursos
var warns := ""

func _init(_id:String, _desc: String, _type: Type, _op1: Benefits, _op2: Benefits,
		 _duration: int, _photo: Texture2D = null, _character: PackedScene = null, _winChance: float = 100.0) -> void:
	id = _id
	desc = _desc
	type = _type
	
	benOp1 = _op1
	benOp2 = _op2
	
	duration = _duration
	photo = _photo
	character = _character
	winChance = _winChance
