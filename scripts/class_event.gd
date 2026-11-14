class_name Event # Makes the new class type
extends RefCounted # So it auto frees from memory when not longer used

class benefits:
	var energy: int
	var food: int
	var water: int
	var radiation: int

enum Type {CHARACTER, COMMS, EVENT}

var id: String
var desc: String
var type: Type
var benOp1: benefits
var benOp2: benefits
var duration: int
var character: PackedScene
var winChance: float 

func _init(_id:String, _desc: String, _type: Type, _benEnergy1: int, _benFood1: int, _benWater1: int, 
	_benRadiation1: int, _benEnergy2: int, _benFood2: int, _benWater2: int, 
	_benRadiation2: int, _duration: int, _character: PackedScene, _winChance: float) -> void:
	id = _id
	desc = _desc
	type = _type
	benOp1.energy = _benEnergy1
	benOp1.benFood = _benFood1
	benOp1.benWater = _benWater1
	benOp1.benRadiation = _benRadiation1
	benOp2.energy = _benEnergy2
	benOp2.benFood = _benFood2
	benOp2.benWater = _benWater2
	benOp2.benRadiation = _benRadiation2
	duration = _duration
	character = _character
	winChance = _winChance
