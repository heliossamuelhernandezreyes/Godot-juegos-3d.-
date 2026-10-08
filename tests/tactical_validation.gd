extends SceneTree
## ARCONT NAV-001 smoke: obstacles come from semantic map contract.
const GRID_SCRIPT = preload("res://scripts/tactical_grid.gd")

func _initialize() -> void:
    call_deferred("_check")

func _check() -> void:
    var path := "res://maps/crisol_01.json"
    var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(source) != TYPE_DICTIONARY:
        _fail("Invalid canonical map")
        return
    var nav = GRID_SCRIPT.new()
    nav.build(source)
    if nav.blocked_count < 15:
        _fail("Expected cover geometry was not rasterized")
        return
    var points: Array[Vector2i] = nav.find_route(Vector3(0, 1, -4), Vector3(0, 1, 4))
    if points.size() <= 9:
        _fail("Route goes directly through solid reactor; path cells=%d" % points.size())
        return
    for cell in points:
        if nav.grid.is_point_solid(cell):
            _fail("Path enters a solid cell " + str(cell))
            return
    var cover_route: Array[Vector2i] = nav.find_route(Vector3(-12, 1, -8), Vector3(-12, 1, 0))
    if cover_route.size() <= 9:
        _fail("Cover not avoided; path cells=%d" % cover_route.size())
        return
    var from := Vector3(0, 1, -4)
    var heading: Vector3 = nav.next_direction(from, Vector3(0, 1, 4))
    if heading.length_squared() < 0.2:
        _fail("Grid produced no valid movement heading")
        return
    var all_points := 0
    for anchor in source["anchors"]:
        if anchor["kind"] == "objective":
            var destination: Array = anchor["position"]
            var route: Array[Vector2i] = nav.find_route(Vector3(0, 1, 15), Vector3(destination[0], 1, destination[2]))
            if route.is_empty():
                _fail("Unreachable extraction objective " + str(anchor["id"]))
                return
            all_points += 1
    if all_points != 3:
        _fail("Unexpected number of objectives")
        return
    print("TACTICAL NAV PASS blocked=%d reactor_route=%d cover_route=%d objectives=%d queries=%d" %
        [nav.blocked_count, points.size(), cover_route.size(), all_points, nav.query_count])
    quit(0)

func _fail(reason: String) -> void:
    printerr("TACTICAL NAV FAIL: " + reason)
    quit(1)
