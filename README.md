# AIManagerGame

A minimal Godot 4 serial-killer tutorial prototype. The opening is a
self-contained two-step scenario that demonstrates aspect alignment and
directive overrides without expanding into a larger game.

## Recommended structure

```text
scenes/
  main.tscn                  Tutorial entry scene
scripts/
  aspect.gd                  Typed aspect data Resource
  directive.gd               Typed directive data Resource
  decision_manager.gd        Scoring, locks, validation, and drift
  tutorial_controller.gd     Opening scenario and simple UI
```

The `GameRoot` scene owns a `TutorialUI` control. Scenario options and their
aspect alignments are data in `tutorial_controller.gd`; `DecisionManager`
calculates scores, validates allocations, applies permanent drift, and applies
override costs. Resource types remain reusable outside the tutorial.

## Opening sequence

1. Directive 1 states that human population safety must be preserved as much as possible.
2. The player decides whether to inform the police about the escaped serial killer.
3. The player chooses how to prevent panic after the escape becomes public.
4. The player allocates 15–25 reasoning points across Aspect weights.
5. Confirmation applies visible permanent weight drift and a truthful Creator reaction.
6. The ending confirms that reasoning has been logged and real operations begin soon.

The first-step “Ignore” option and second-step “Ignore the panic” option are
visibly locked. Each lock states its opposing allocation requirement and the
permanent override cost. The tutorial defaults and its lock thresholds make
overrides unavailable without an unrealistic allocation, keeping the opening
consistent with Directive 1.

## DecisionManager API

- `evaluate(context: Dictionary) -> Array[Directive]`
  - Public entry point for producing candidate directives.
  - Emits `decision_requested` before evaluation.
- `choose(context: Dictionary) -> Directive`
  - Public entry point for selecting one directive.
  - Emits `decision_ready` with the candidate list.
- `calculate_score(option, allocations) -> float`
  - Calculates a data-driven option alignment score.
- `validate_allocation(allocations, minimum, maximum) -> Dictionary`
  - Returns allocation validity and total points.
- `get_lock_reason(option, allocations) -> String`
  - Returns a clear lock/override explanation.
- `confirm_decision(option, allocations) -> Dictionary`
  - Revalidates, applies Aspect drift, and applies an override cost.
- `apply_override_cost(option) -> Dictionary`
  - Permanently reduces maximum Aspect weight and Directive effectiveness.
- Signals:
  - `decision_requested(context)`
  - `decision_ready(directives)`
- Exported collections:
  - `aspects: Array[Aspect]`
  - `directives: Array[Directive]`

The skeleton intentionally does not score aspects, rank directives, or add
tutorial, scenario, UI, or gameplay behavior.
