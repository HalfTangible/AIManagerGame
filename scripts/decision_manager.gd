class_name DecisionManager
extends Node

signal decision_requested(context: Dictionary)
signal decision_ready(directives: Array[Directive])

@export var aspects: Array[Aspect] = []
@export var directives: Array[Directive] = []


func evaluate(context: Dictionary = {}) -> Array[Directive]:
	decision_requested.emit(context)
	return []


func choose(context: Dictionary = {}) -> Directive:
	var candidates := evaluate(context)
	decision_ready.emit(candidates)
	if candidates.is_empty():
		return null
	return candidates[0]
