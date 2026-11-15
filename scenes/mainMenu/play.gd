extends Button

@export var game_scene: PackedScene
@export var disclaimer_texture: Texture2D

func _ready() -> void:
	pressed.connect(_on_play_press)

func _on_play_press() -> void:
	Transition.click()
	# Fundido a negro -> disclaimer -> juego (todo gestionado por el autoload Transition)
	Transition.go(game_scene.resource_path, disclaimer_texture)
