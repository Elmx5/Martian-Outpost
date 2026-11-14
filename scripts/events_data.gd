extends Node

var events: Dictionary = {}

func _ready() -> void:  
	_register(Event.new("rastrillo", "My rake broke while I was harvesting some lettuce, could I have some resources to repair it?😢😢😢", Event.Type.CHARACTER, -10, 0, 0, 0, 0, -10, 0, 0, 0, , 100))
	
	Resources

func _register(ev: Event) -> void:
	events[ev.desc] = ev
