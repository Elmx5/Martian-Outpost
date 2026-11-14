extends Button

@export var game_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_play_press)


func _on_play_press() -> void:
	get_tree().change_scene_to_packed(game_scene)
