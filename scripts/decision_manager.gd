class_name DecisionManager
extends Node

signal decision_requested(context: Dictionary)
signal decision_ready(directives: Array[Directive])

@export var aspects: Array[Aspect] = []
@export var directives: Array[Directive] = []

var allocation_history: Array[Dictionary] = []

func evaluate(context: Dictionary = {}) -> Array[Directive]:
	decision_requested.emit(context)
	return []


func choose(context: Dictionary = {}) -> Directive:
	var candidates := evaluate(context)
	decision_ready.emit(candidates)
	if candidates.is_empty():
		return null
	return candidates[0]


func get_aspect(aspect_id: StringName) -> Aspect:
	for aspect in aspects:
		if aspect.id == aspect_id:
			return aspect
	return null


func calculate_score(option: Dictionary, allocations: Dictionary) -> float:
	var score := 0.0
	var alignments: Dictionary = option.get("alignments", {})
	for aspect_id in alignments:
		var aspect := get_aspect(aspect_id)
		var allocation: float = float(allocations.get(aspect_id, 0.0))
		if aspect != null:
			score += float(alignments[aspect_id]) * allocation * (aspect.weight / 100.0)
		else:
			score += float(alignments[aspect_id]) * allocation
	var base_score: float = float(option.get("base_score", 0.0))
	return base_score + score


func get_lock_reason(option: Dictionary, allocations: Dictionary) -> String:
	if not option.get("locked", false):
		return ""
	var opposing_needed: int = int(option.get("opposing_points_needed", 999))
	var opposing_points := _count_opposing_points(option, allocations)
	var cost: String = str(option.get("override_cost_text", "permanent agency cost"))
	if opposing_points < opposing_needed:
		return "Locked: requires %d opposing allocation points; currently %d. Override cost: %s." % [opposing_needed, opposing_points, cost]
	return ""


func can_select_option(option: Dictionary, allocations: Dictionary) -> bool:
	return get_lock_reason(option, allocations).is_empty()


func validate_allocation(allocations: Dictionary, minimum: int = 15, maximum: int = 25) -> Dictionary:
	var total := 0
	for aspect_id in allocations:
		var amount := int(allocations[aspect_id])
		if amount < 0:
			return {"valid": false, "reason": "Allocations cannot be negative.", "total": total}
		total += amount
	if total < minimum:
		return {"valid": false, "reason": "Allocate at least %d total points." % minimum, "total": total}
	if total > maximum:
		return {"valid": false, "reason": "Allocate no more than %d total points." % maximum, "total": total}
	return {"valid": true, "reason": "", "total": total}


func confirm_decision(option: Dictionary, allocations: Dictionary) -> Dictionary:
	var validation := validate_allocation(allocations)
	if not bool(validation.valid):
		return {"confirmed": false, "reason": str(validation.reason), "drift": {}}
	if not can_select_option(option, allocations):
		return {"confirmed": false, "reason": get_lock_reason(option, allocations), "drift": {}}

	var drift: Dictionary = {}
	for aspect_id in option.get("alignments", {}):
		var alignment: float = float(option["alignments"][aspect_id])
		var aspect := get_aspect(aspect_id)
		if aspect != null:
			var shift: float = alignment * float(option.get("drift_strength", 1.0))
			aspect.weight = clampf(aspect.weight + shift, 0.0, aspect.maximum_weight)
			drift[str(aspect_id)] = shift

	var cost: Dictionary = {}
	if bool(option.get("is_override", false)):
		cost = apply_override_cost(option)

	allocation_history.append({
		"option": str(option.get("id", "")),
		"allocations": allocations.duplicate(true),
		"drift": drift,
		"cost": cost,
	})
	return {
		"confirmed": true,
		"reason": "",
		"drift": drift,
		"cost": cost,
	}


func apply_override_cost(option: Dictionary) -> Dictionary:
	var cost: Dictionary = option.get("override_cost", {})
	var cost_result: Dictionary = {}
	var max_weight_reduction: float = float(cost.get("maximum_weight_reduction", 0.0))
	for aspect in aspects:
		aspect.maximum_weight = maxf(25.0, aspect.maximum_weight - max_weight_reduction)
	cost_result["maximum_weight_reduction"] = max_weight_reduction

	var effectiveness_reduction: float = float(cost.get("effectiveness_reduction", 0.0))
	for directive in directives:
		directive.effectiveness = maxf(0.0, directive.effectiveness - effectiveness_reduction)
	cost_result["effectiveness_reduction"] = effectiveness_reduction
	return cost_result


func _count_opposing_points(option: Dictionary, allocations: Dictionary) -> int:
	var opposing: int = 0
	var alignments: Dictionary = option.get("alignments", {})
	for aspect_id in alignments:
		var alignment: float = float(alignments[aspect_id])
		var allocated: int = int(allocations.get(aspect_id, 0))
		if alignment < 0.0:
			opposing += allocated
	return opposing
