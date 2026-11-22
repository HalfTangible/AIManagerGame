class_name Aspect
extends Resource

@export var id: StringName
@export var display_name: String
@export_range(-1.0, 1.0, 0.01) var value: float = 0.0
@export var weight: float = 1.0
@export var maximum_weight: float = 100.0
@export var tags: Array[StringName] = []


func duplicate_aspect() -> Aspect:
	var copy := duplicate(true) as Aspect
	return copy
