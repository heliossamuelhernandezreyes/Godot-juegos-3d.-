extends RefCounted
## Mission-owned authority, independent from Godot scene/actors and ARCONT.
## The validated ARCONT JSON defines phase ordering and objective dependencies.
signal phase_changed(phase_id: String)
signal objective_completed(objective_id: String)
signal mission_finished(won: bool)

var contract: Dictionary = {}
var phase_id := ""
var completed: Dictionary = {}
var terminated := false
var defense_seconds := 0.0
var events: Array[String] = []

func initialize(source: Dictionary) -> void:
    contract = source
    phase_id = str(contract["phases"][0]["id"])
    completed.clear()
    terminated = false
    defense_seconds = 0.0
    events.clear()
    events.append("phase:" + phase_id)
    phase_changed.emit(phase_id)

func get_objective(id: String) -> Dictionary:
    for item in contract.get("objectives", []):
        if str(item["id"]) == id:
            return item
    return {}

func phase_objectives() -> Array:
    for phase in contract.get("phases", []):
        if str(phase["id"]) == phase_id:
            return phase.get("objective_ids", [])
    return []

func can_complete(id: String) -> bool:
    if terminated or completed.has(id):
        return false
    var obj := get_objective(id)
    return not obj.is_empty() and str(obj["phase"]) == phase_id and phase_objectives().has(id)

func complete(id: String) -> bool:
    if not can_complete(id):
        return false
    completed[id] = true
    events.append("objective:" + id)
    objective_completed.emit(id)
    var all_done := true
    for required_id in phase_objectives():
        if not completed.has(str(required_id)):
            all_done = false
    if all_done:
        _advance()
    return true

func _advance() -> void:
    for transition in contract.get("transitions", []):
        if str(transition["from"]) != phase_id:
            continue
        var condition: Dictionary = transition.get("condition", {})
        var requirements: Array = condition.get("objective_ids", [])
        var satisfied := true
        for required_id in requirements:
            if not completed.has(str(required_id)):
                satisfied = false
        if not satisfied:
            return
        phase_id = str(transition["to"])
        events.append("phase:" + phase_id)
        if phase_id == "victory":
            terminated = true
            mission_finished.emit(true)
        else:
            phase_changed.emit(phase_id)
        return

func update_defense(delta: float, remaining_enemies: int) -> void:
    if phase_id != "defense" or terminated or delta <= 0.0:
        return
    defense_seconds += delta
    var obj := get_objective("defense_hold")
    if defense_seconds >= float(obj.get("duration_seconds", 75.0)) and remaining_enemies <= 0:
        complete("defense_hold")

func fail() -> void:
    if terminated:
        return
    terminated = true
    phase_id = "failed"
    events.append("phase:failed")
    mission_finished.emit(false)

func is_complete(id: String) -> bool:
    return completed.has(id)
