extends Node

signal resource_changed(resource:SpaceResource, new_value:int)

enum SpaceResource {ENERGY, FOOD, WATER, RADIATION}

var spaceResources: Dictionary = {
	SpaceResource.ENERGY: 100,
	SpaceResource.FOOD: 100,
	SpaceResource.WATER: 100,
	SpaceResource.RADIATION: 0
}

func modify(resource:SpaceResource, quantity:int) -> void:
	spaceResources[resource] = max(0, spaceResources[resource] + quantity)
	resource_changed.emit(resource, spaceResources[resource])

func getResource(resource:SpaceResource) -> int:
	return spaceResources[resource]
