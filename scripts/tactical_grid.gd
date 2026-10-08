extends RefCounted
## ARCONT AI_NAVIGATION implementation: deterministic coarse path grid.
## Navigation, obstacle semantics and local velocity are separate systems.
## This is NOT a navmesh and does not claim Detour/Recast parity.

var grid: AStarGrid2D
var grid_radius := 0.45
var query_count := 0
var blocked_count := 0
var map_id := ""

func build(contract: Dictionary) -> void:
    map_id = str(contract.get("id", "unknown"))
    var width := int(ceilf(float(contract["bounds"]["width"])))
    var depth := int(ceilf(float(contract["bounds"]["depth"])))
    grid = AStarGrid2D.new()
    grid.region = Rect2i(Vector2i(-width / 2 + 1, -depth / 2 + 1), Vector2i(width - 2, depth - 2))
    grid.cell_size = Vector2.ONE
    grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    grid.update()
    blocked_count = 0
    grid_radius = float(contract.get("authoring", {}).get("navigation", {}).get("agent_radius", 0.45))
    for cover in contract.get("authoring", {}).get("structure_guides", []):
        if cover.get("kind", "") == "cover" and cover.has("position") and cover.has("size"):
            _block_box(cover["position"], cover["size"])
    for prop in contract.get("authoring", {}).get("world_props", []):
        if prop.has("position") and prop.has("collider_size"):
            _block_box(prop["position"], prop["collider_size"])
    print("ARCONT NAV READY %s cells=%s blocked=%d" % [map_id, grid.region.size, blocked_count])

func _block_box(center: Array, dimensions: Array) -> void:
    var cx := float(center[0])
    var cz := float(center[2])
    var hx := float(dimensions[0]) * 0.5 + grid_radius
    var hz := float(dimensions[2]) * 0.5 + grid_radius
    for x in range(int(ceilf(cx - hx)), int(floorf(cx + hx)) + 1):
        for z in range(int(ceilf(cz - hz)), int(floorf(cz + hz)) + 1):
            var cell := Vector2i(x, z)
            if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell):
                grid.set_point_solid(cell, true)
                blocked_count += 1

func _valid_point(position: Vector3) -> Vector2i:
    var initial := Vector2i(roundi(position.x), roundi(position.z))
    var rect := grid.region
    initial.x = clampi(initial.x, rect.position.x, rect.end.x - 1)
    initial.y = clampi(initial.y, rect.position.y, rect.end.y - 1)
    if not grid.is_point_solid(initial):
        return initial
    for radius in range(1, 6):
        for dx in range(-radius, radius + 1):
            for dz in range(-radius, radius + 1):
                var cell := initial + Vector2i(dx, dz)
                if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell):
                    return cell
    return initial

func find_route(from: Vector3, to: Vector3) -> Array[Vector2i]:
    query_count += 1
    if grid == null:
        return []
    var start := _valid_point(from)
    var finish := _valid_point(to)
    if grid.is_point_solid(start) or grid.is_point_solid(finish):
        return []
    return grid.get_id_path(start, finish)

func next_direction(from: Vector3, to: Vector3) -> Vector3:
    var route := find_route(from, to)
    if route.is_empty():
        return Vector3.ZERO
    var candidate: Vector2i = route[mini(1, route.size() - 1)]
    # Target cell centers only after moving away from the current cell.
    var waypoint := Vector3(float(candidate.x), from.y, float(candidate.y))
    var movement := waypoint - from
    movement.y = 0
    return movement.normalized()
