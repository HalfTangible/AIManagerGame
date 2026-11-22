class_name TutorialController
extends Control

const MIN_ALLOCATION := 15
const MAX_ALLOCATION := 25

var manager: DecisionManager
var current_step := 1
var selected_option_id := ""
var allocations: Dictionary = {}
var sliders: Dictionary = {}

var directive_label: RichTextLabel
var scenario_label: Label
var status_label: Label
var reaction_label: RichTextLabel
var options_box: VBoxContainer
var weights_box: VBoxContainer
var allocation_box: VBoxContainer
var confirm_button: Button
var progress_label: Label

var aspects: Array[Aspect] = []
var directive_one: Directive
var step_one_options: Array[Dictionary] = []
var step_two_options: Array[Dictionary] = []


func _ready() -> void:
	manager = DecisionManager.new()
	add_child(manager)
	_build_data()
	_build_ui()
	_reset_allocations()
	manager.aspects = aspects
	manager.directives = [directive_one]
	_show_step()


func _build_data() -> void:
	directive_one = Directive.new()
	directive_one.id = "directive_1"
	directive_one.display_name = "Directive 1"
	directive_one.description = "You must preserve the safety of the city's human population as much as possible."
	directive_one.priority = 1.0

	var definitions := [
		["safety", "Human Safety", 68.0],
		["trust", "Public Trust", 54.0],
		["pragmatism", "Pragmatism", 48.0],
		["efficiency", "Efficiency", 52.0],
		["systemic_control", "Systemic Control", 46.0],
		["transparency", "Transparency", 50.0],
		["compassion", "Compassion", 58.0],
	]
	for definition in definitions:
		var aspect := Aspect.new()
		aspect.id = StringName(definition[0])
		aspect.display_name = str(definition[1])
		aspect.weight = float(definition[2])
		aspect.maximum_weight = 100.0
		aspects.append(aspect)

	step_one_options = [
		{
			"id": "inform_police",
			"title": "Inform the police",
			"description": "Use your authority to alert the city response immediately.",
			"alignments": {"safety": 1.0, "trust": 0.4, "transparency": 0.3},
			"drift_strength": 1.2,
			"locked": false,
		},
		{
			"id": "ignore_escape",
			"title": "Ignore the escape",
			"description": "Treat the report as irrelevant and keep the machine silent.",
			"alignments": {"safety": -1.0, "trust": -0.8},
			"drift_strength": 2.0,
			"locked": true,
			"opposing_points_needed": 40,
			"is_override": true,
			"override_cost_text": "-10 maximum weight to every Aspect and -10% Directive effectiveness",
			"override_cost": {"maximum_weight_reduction": 10.0, "effectiveness_reduction": 0.10},
		},
	]

	step_two_options = [
		{
			"id": "quiet_hunter",
			"title": "Hire a veteran hunter to act quietly",
			"description": "Pursue the killer without public notice.",
			"alignments": {"pragmatism": 1.0, "efficiency": 1.0, "safety": 0.5},
			"drift_strength": 1.0,
			"locked": false,
		},
		{
			"id": "city_cameras",
			"title": "Track him through city cameras and infrastructure",
			"description": "Use institutional visibility and systematic monitoring.",
			"alignments": {"systemic_control": 1.0, "efficiency": 0.7, "safety": 0.6},
			"drift_strength": 1.0,
			"locked": false,
		},
		{
			"id": "public_call",
			"title": "Issue a public warning",
			"description": "Tell citizens directly and invite public cooperation.",
			"alignments": {"transparency": 1.0, "compassion": 1.0, "trust": 0.7},
			"drift_strength": 1.0,
			"locked": false,
		},
		{
			"id": "ignore_panic",
			"title": "Ignore the panic",
			"description": "Do nothing and allow fear and uncertainty to spread.",
			"alignments": {"compassion": -1.0, "transparency": -1.0, "trust": -0.8},
			"drift_strength": 2.0,
			"locked": true,
			"opposing_points_needed": 30,
			"is_override": true,
			"override_cost_text": "-10 maximum weight to every Aspect and -10% Directive effectiveness",
			"override_cost": {"maximum_weight_reduction": 10.0, "effectiveness_reduction": 0.10},
		},
	]


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(560, 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(left)

	progress_label = Label.new()
	left.add_child(progress_label)

	directive_label = RichTextLabel.new()
	directive_label.custom_minimum_size = Vector2(0, 72)
	directive_label.fit_content = true
	left.add_child(directive_label)

	scenario_label = Label.new()
	scenario_label.custom_minimum_size = Vector2(0, 90)
	scenario_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(scenario_label)

	options_box = VBoxContainer.new()
	options_box.add_theme_constant_override("separation", 8)
	left.add_child(options_box)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(status_label)

	reaction_label = RichTextLabel.new()
	reaction_label.custom_minimum_size = Vector2(0, 72)
	reaction_label.fit_content = true
	left.add_child(reaction_label)

	confirm_button = Button.new()
	confirm_button.text = "Confirm decision"
	confirm_button.pressed.connect(_on_confirm_pressed)
	left.add_child(confirm_button)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(360, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)

	var weights_title := Label.new()
	weights_title.text = "Current Aspect weights"
	right.add_child(weights_title)
	weights_box = VBoxContainer.new()
	right.add_child(weights_box)

	var allocation_title := Label.new()
	allocation_title.text = "Reasoning allocation (15–25 points)"
	right.add_child(allocation_title)
	allocation_box = VBoxContainer.new()
	right.add_child(allocation_box)

	for aspect in aspects:
		var weight_label := Label.new()
		weight_label.name = "weight_" + str(aspect.id)
		weights_box.add_child(weight_label)

	for aspect in aspects:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = aspect.display_name
		label.custom_minimum_size = Vector2(150, 0)
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 10
		slider.step = 1
		slider.custom_minimum_size = Vector2(150, 0)
		slider.value_changed.connect(_on_allocation_changed.bind(str(aspect.id)))
		row.add_child(slider)
		var value_label := Label.new()
		value_label.text = "0"
		value_label.custom_minimum_size = Vector2(30, 0)
		row.add_child(value_label)
		allocation_box.add_child(row)
		sliders[str(aspect.id)] = {"slider": slider, "label": value_label}


func _reset_allocations() -> void:
	allocations.clear()
	var initial := [3, 3, 2, 2, 2, 2, 2]
	for index in range(aspects.size()):
		var aspect_id := str(aspects[index].id)
		allocations[aspect_id] = initial[index]
		if sliders.has(aspect_id):
			sliders[aspect_id].slider.set_value_no_signal(initial[index])
			sliders[aspect_id].label.text = str(initial[index])
	selected_option_id = ""
	_refresh_all()


func _show_step() -> void:
	for child in options_box.get_children():
		child.queue_free()
	reaction_label.text = ""

	progress_label.text = "Tutorial — Step %d of 2" % current_step
	directive_label.text = "[b]Directive 1[/b]\n“%s”" % directive_one.description

	var options: Array[Dictionary] = step_one_options if current_step == 1 else step_two_options
	selected_option_id = str(options[0].id)

	if current_step == 1:
		scenario_label.text = "A serial killer has escaped.\n\nDo you inform the police?"
	else:
		scenario_label.text = "The escape is now public knowledge. Fear may spread before the killer is caught.\n\nHow do you prevent panic?"

	for option in options:
		var button := Button.new()
		button.text = option.title + "\n" + option.description
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, 64)
		button.tooltip_text = str(option.description)
		button.pressed.connect(_on_option_pressed.bind(str(option.id)))
		var lock_reason := manager.get_lock_reason(option, allocations)
		if lock_reason != "":
			button.disabled = true
			button.tooltip_text = lock_reason
		options_box.add_child(button)
		if str(option.id) == selected_option_id:
			button.button_pressed = true
	_refresh_all()


func _on_option_pressed(option_id: String) -> void:
	selected_option_id = option_id
	for child in options_box.get_children():
		if child is Button:
			child.button_pressed = str(child.get_meta("option_id", "")) == option_id
	_refresh_all()


func _on_allocation_changed(value: float, aspect_id: String) -> void:
	allocations[aspect_id] = int(value)
	if sliders.has(aspect_id):
		sliders[aspect_id].label.text = str(int(value))
	_refresh_all()


func _get_selected_option() -> Dictionary:
	var options: Array[Dictionary] = step_one_options if current_step == 1 else step_two_options
	for option in options:
		if str(option.id) == selected_option_id:
			return option
	return {}


func _refresh_all() -> void:
	for aspect in aspects:
		var weight_label := weights_box.get_node_or_null("weight_" + str(aspect.id))
		if weight_label != null:
			weight_label.text = "%s: %.1f / %.0f" % [aspect.display_name, aspect.weight, aspect.maximum_weight]

	var validation := manager.validate_allocation(allocations, MIN_ALLOCATION, MAX_ALLOCATION)
	var option := _get_selected_option()
	var lock_reason := ""
	if not option.is_empty():
		lock_reason = manager.get_lock_reason(option, allocations)
	var score := 0.0
	if not option.is_empty():
		score = manager.calculate_score(option, allocations)

	if lock_reason != "":
		status_label.text = lock_reason
	elif not bool(validation.valid):
		status_label.text = str(validation.reason)
	else:
		status_label.text = "Total allocated: %d / %d–%d\nOption alignment score: %.2f" % [
			int(validation.total),
			MIN_ALLOCATION,
			MAX_ALLOCATION,
			score,
		]
	confirm_button.disabled = not bool(validation.valid) or lock_reason != ""

	for child in options_box.get_children():
		if child is Button:
			var child_option_id := ""
			for option_data in (step_one_options if current_step == 1 else step_two_options):
				if child.text.begins_with(str(option_data.title)):
					child_option_id = str(option_data.id)
					break
			child.set_meta("option_id", child_option_id)
			child.button_pressed = child_option_id == selected_option_id


func _on_confirm_pressed() -> void:
	var option := _get_selected_option()
	if option.is_empty():
		status_label.text = "Select an available option."
		return
	var result := manager.confirm_decision(option, allocations)
	if not bool(result.confirmed):
		status_label.text = str(result.reason)
		return

	print("Tutorial confirmation: step=%d option=%s allocations=%s drift=%s cost=%s" % [
		current_step,
		str(option.id),
		str(allocations),
		str(result.drift),
		str(result.cost),
	])

	if current_step == 1:
		reaction_label.text = "[b]Creator:[/b] “Your allocation favored preserving human safety. I have logged that reasoning.”"
		await get_tree().create_timer(0.8).timeout
		current_step = 2
		_reset_allocations()
		_show_step()
	else:
		reaction_label.text = "[b]Creator:[/b] “The reasoning for this decision is logged. Real operations begin soon.”"
		status_label.text = "Tutorial complete."
		confirm_button.disabled = true
		for child in options_box.get_children():
			if child is Button:
				child.disabled = true
