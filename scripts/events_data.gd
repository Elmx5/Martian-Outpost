extends Node

var events: Dictionary = {}

var Astronaut: PackedScene = preload("uid://g3mk3cbd7wlv")

var ImgFlare: Texture2D = preload("uid://bnvm4tjs77ypq")

func _ready() -> void:  
	_register(Event.new("rastrillo", 
						"My rake broke while I was harvesting some lettuce, could I have some resources to repair it?😢😢😢", 
						Event.Type.CHARACTER, 
						Event.Benefits.new(-10),
						Event.Benefits.new(0,-10),
						0, ImgFlare, Astronaut))

func _register(ev: Event) -> void:
	events[ev.desc] = ev
