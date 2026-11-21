# AIManagerGame

A minimal Godot 4 foundation for a future AI manager simulation. This initial scope
contains only the data structures and manager API needed for later decision logic.

## Recommended structure

```text
scenes/
  main.tscn              Minimal root scene
scripts/
  aspect.gd              Typed aspect data Resource
  directive.gd           Typed directive data Resource
  decision_manager.gd    Decision orchestration skeleton
```

The `GameRoot` scene owns a `DecisionManager` child node. Keep domain data as
`Aspect` and `Directive` Resources, attach the manager to the scene graph, and add
future systems beneath `GameRoot` rather than coupling gameplay logic into the
data Resources.

## Proposed DecisionManager API

- `evaluate(context: Dictionary) -> Array[Directive]`
  - Public entry point for producing candidate directives.
  - Emits `decision_requested` before evaluation.
- `choose(context: Dictionary) -> Directive`
  - Public entry point for selecting one directive.
  - Emits `decision_ready` with the candidate list.
- Signals:
  - `decision_requested(context)`
  - `decision_ready(directives)`
- Exported collections:
  - `aspects: Array[Aspect]`
  - `directives: Array[Directive]`

The skeleton intentionally does not score aspects, rank directives, or add
tutorial, scenario, UI, or gameplay behavior.
