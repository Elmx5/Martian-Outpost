extends Button

@export var game_scene: PackedScene
@export var main_menu: Node
@export var disclaimer: TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_play_press)


func _on_play_press() -> void:
	disclaimer.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(main_menu, "modulate:a", 0.0, 1.0)
	tween.tween_property(disclaimer, "modulate:a", 1.0, 1.0)
	tween.tween_interval(3.0)
	tween.tween_property(disclaimer, "modulate:a", 0.0, 1.0)
	await tween.finished

	get_tree().change_scene_to_packed(game_scene)
