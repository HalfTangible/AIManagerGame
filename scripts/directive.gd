class_name Directive
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var priority: float = 0.0
@export var tags: Array[StringName] = []
@export var metadata: Dictionary = {}
@export var effectiveness: float = 1.0
@export var alignments: Dictionary = {}


func duplicate_directive() -> Directive:
	var copy := duplicate(true) as Directive
	return copy
