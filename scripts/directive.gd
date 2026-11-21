class_name Directive
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var priority: float = 0.0
@export var tags: Array[StringName] = []
@export var metadata: Dictionary = {}


func duplicate_directive() -> Directive:
	var copy := duplicate(true) as Directive
	return copy
