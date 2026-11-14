extends Node

var events: Dictionary = {}

var Astronaut: PackedScene = preload("uid://g3mk3cbd7wlv")
var Farmer: PackedScene = preload("uid://2y6kidugf2x8")
var Radio: PackedScene = preload("uid://dwunnj58pqs66")
var Scientist: PackedScene = preload("uid://0xeetkk5gje8")

var ImgFlare: Texture2D = preload("uid://bnvm4tjs77ypq")

func _ready() -> void:  
	_register(Event.new("farm1", 
						"My rake broke while I was harvesting some lettuce, could I have some resources to repair it?😢😢😢", 
						Event.Type.CHARACTER, 
						Event.Benefits.new(-10),
						Event.Benefits.new(0,-10),
						0, null, Astronaut))
	_register(Event.new("solar_storm", 
						"A solar flare just started, all run to a safe place away from radiation!!", 
						Event.Type.EVENT, 
						Event.Benefits.new(0,0,0,2),
						Event.Benefits.new(0,0,0,2),
						2, ImgFlare, null))
						
	_register(Event.new("send_report", 
						"What's the situation up there in Mars? It's time for you to send us the periodic report (antenna required)", 
						Event.Type.COMMS, 
						Event.Benefits.new(-10),
						Event.Benefits.new(-20),
						2, null, Radio))
						
	_register(Event.new("expedition1", 
						"I found an interesting cave with usefull resources", 
						Event.Type.CHARACTER, 
						Event.Benefits.new(0,0,10,10),
						Event.Benefits.new(),
						2, null, Astronaut, 80.0))
						
	_register(Event.new("expedition2", 
						"There are some ice a bit further from the base, but there could be some resources", 
						Event.Type.CHARACTER, 
						Event.Benefits.new(0,0,20,20),
						Event.Benefits.new(),
						4, null, Astronaut, 60.0))
						
	_register(Event.new("expedition3", 
						"There are some ice a bit further from the base, but there could be some resources", 
						Event.Type.CHARACTER, 
						Event.Benefits.new(20,0,30,20),
						Event.Benefits.new(),
						3, null, Astronaut, 40.0))
						
	_register(Event.new("farm2", 
						"I found an interesting cave with usefull resources", 
						Event.Type.CHARACTER, 
						Event.Benefits.new(-5,10),
						Event.Benefits.new(0,-20),
						2, null, Farmer, 70.0))
	_register(Event.new("for_science", 
						"I need to do research on our vegetables to make them more resistant to the martian rough climate and characteristics, could I borrow some? ",
						Event.Type.CHARACTER, 
						Event.Benefits.new(0,-20), #Necesito poder añadir comida permanente, plis
						Event.Benefits.new(),
						2, null, Scientist, 65.0))
	_register(Event.new("meteor_rain", 
						"Alert!!! A meteor rain! You have to decide if you protect the generators or the water tank", 
						Event.Type.EVENT, 
						Event.Benefits.new(0,0,-20),
						Event.Benefits.new(-20),
						0, null, null))
						
	_register(Event.new("energy+", 
						"Mars has rotated and the solar beams make your solar panels produce more energy (solar pannels required)", 
						Event.Type.EVENT, 
						Event.Benefits.new(20),
						Event.Benefits.new(20),
						0, null, null))
						
	_register(Event.new("nuclear", 
						"The nuclear reactor is in danger! Do you want to take the risk to repair it before something worse happens?", 
						Event.Type.EVENT, 
						Event.Benefits.new(-10,-20,20),
						Event.Benefits.new(-15), #Falta añadir
						0, null, null))
						
	_register(Event.new("farm3", 
						"I want to use some of our water resources to make a protection for our plants", 
						Event.Type.CHARACTER, 
						Event.Benefits.new(0,0,-15),
						Event.Benefits.new(0,-15), #Falta añadir
						0, null, Farmer))
						
	_register(Event.new("farm4", 
						"I want to build a subterrain greenhouse to produce more food", 
						Event.Type.CHARACTER, 
						Event.Benefits.new(-15,15,-5), #Habría que añadir
						Event.Benefits.new(0,-15), 
						0, null, Farmer, 70))
						
	_register(Event.new("science2", 
						"I want to investigate which plants resist most to radiation", 
						Event.Type.CHARACTER, 
						Event.Benefits.new(-10,5), #Habría que añadir
						Event.Benefits.new(0,-5), 
						0, null, Scientist, 50))
						
	_register(Event.new("expedition4", 
						"I want to search in a old and abandoned base", 
						Event.Type.CHARACTER, 
						Event.Benefits.new(15,0,0,10), 
						Event.Benefits.new(), 
						2, null, Astronaut, 80))
						
	_register(Event.new("dusk", 
						"A martian storm!!! There's too much dusk!!!!", 
						Event.Type.EVENT, 
						Event.Benefits.new(), #Falta añadir que no haya producción
						Event.Benefits.new(), 
						1, null, null))
						
	_register(Event.new("bad_harvest", 
						"We are having a bad harvest!!!", 
						Event.Type.EVENT, 
						Event.Benefits.new(), #Falta añadir que no haya producción
						Event.Benefits.new(), 
						1, null, null))
						
	_register(Event.new("water_production", 
						"I want some energy to make water from human fluids", 
						Event.Type.CHARACTER, 
						Event.Benefits.new(-15,0,10), 
						Event.Benefits.new(), 
						0, null, Scientist))
						
	_register(Event.new("water_toxins", 
						"OH NO!!!!!! There are toxins in the water!!!! Do you drink it anyway?", 
						Event.Type.EVENT, 
						Event.Benefits.new(0,0,15), 
						Event.Benefits.new(0,0,-20), 
						0, null, Scientist, 30))
						
	_register(Event.new("oxygen_leak", 
						"We have a leak in our oxigen tank!! We need to repair it!!!", 
						Event.Type.EVENT, 
						Event.Benefits.new(-10,0,-5), 
						Event.Benefits.new(), #Game over en 3 días
						0, null, Scientist, 90))
						
	_register(Event.new("lack_of_oxygen", 
						"You need to produce more oxygen", 
						Event.Type.COMMS, 
						Event.Benefits.new(-15), 
						Event.Benefits.new(-25), #Habría que revisar
						2, null, Radio))
						
	_register(Event.new("excavation_problem", 
						"The water excavation its getting complicated, do we continue or search in another place?", 
						Event.Type.EVENT, 
						Event.Benefits.new(-10,0,20), 
						Event.Benefits.new(-20,0,10), 
						65, null, null))
						
func _register(ev: Event) -> void:
	events[ev.desc] = ev
