extends Node

signal resource_changed(resource:SpaceResource, new_value:int)

enum SpaceResource {ENERGY, FOOD, WATER, RADIATION}

const MAX := 100

var spaceResources: Dictionary = {}

func _ready() -> void:
	reset()

func reset() -> void:
	spaceResources = {
		SpaceResource.ENERGY: 50,
		SpaceResource.FOOD: 50,
		SpaceResource.WATER: 50,
		SpaceResource.RADIATION: 10
	}
	for r in spaceResources:
		resource_changed.emit(r, spaceResources[r])

func modify(resource:SpaceResource, quantity:int) -> void:
	spaceResources[resource] = clampi(spaceResources[resource] + quantity, 0, MAX)
	resource_changed.emit(resource, spaceResources[resource])

func apply(b: Event.Benefits) -> void:
	modify(SpaceResource.ENERGY, b.energy)
	modify(SpaceResource.FOOD, b.food)
	modify(SpaceResource.WATER, b.water)
	modify(SpaceResource.RADIATION, b.radiation)

func getResource(resource:SpaceResource) -> int:
	return spaceResources[resource]
