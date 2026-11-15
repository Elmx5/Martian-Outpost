extends Button

@export var options_scene: PackedScene

func _ready() -> void:
	pressed.connect(_on_options_press)

func _on_options_press() -> void:
	Transition.click()
	Transition.go(options_scene.resource_path)
