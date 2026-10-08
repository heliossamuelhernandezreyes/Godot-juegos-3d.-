extends SceneTree
## Same AStarGrid2D used by runtime; proof only for static waypoint connectivity.
const NAV = preload("res://scripts/tactical_grid.gd")
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://maps/reactivo_13.json"))
    if typeof(raw) != TYPE_DICTIONARY:
        _fail("invalid map JSON")
        return
    var nav = NAV.new()
    nav.build(raw)
    if nav.blocked_count < 30:
        _fail("Expected static collision raster missing")
        return
    var locations: Dictionary = {}
    for anchor in raw["anchors"]:
        var p: Array = anchor["position"]
        locations[str(anchor["id"])] = Vector3(float(p[0]), 1.0, float(p[2]))
    var starts := ["vanguard_start", "node_a_console", "node_b_console", "reactor_altar", "stabilizer"]
    var goals := ["node_a_console", "node_b_console", "reactor_altar", "stabilizer", "extraction_pad"]
    var max_length := 0
    for i in range(starts.size()):
        var route: Array[Vector2i] = nav.find_route(locations[starts[i]], locations[goals[i]])
        if route.is_empty():
            _fail("Unreachable gameplay anchor: " + starts[i] + " => " + goals[i])
            return
        for cell in route:
            if nav.grid.is_point_solid(cell):
                _fail("Navigation route crosses solid obstacle: " + str(cell))
                return
        max_length = maxi(max_length, route.size())
    print("REACTIVO NAV PASS routes=%d blocked=%d longest=%d" % [starts.size(), nav.blocked_count, max_length])
    quit(0)

func _fail(reason: String) -> void:
    printerr("REACTIVO NAV FAIL: " + reason)
    quit(1)
