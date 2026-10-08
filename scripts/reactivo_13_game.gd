extends Node3D
## FISURA 0.7 REACTIVO-13: separate playable mission using game-owned runtime.
## ARCONT validates design/map contracts. Godot remains the runtime authority.
const MAP_PATH := "res://maps/reactivo_13.json"
const MISSION_PATH := "res://missions/reactivo_13.slice.json"
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const GRID_SCRIPT = preload("res://scripts/tactical_grid.gd")
const QUAD_SCRIPT = preload("res://scripts/animated_reaver.gd")
const BULWARK_SCRIPT = preload("res://scripts/reactivo_bulwark.gd")
const TELEGRAPH_DRONE_SCRIPT = preload("res://scripts/reactivo_eyedrone.gd")
const DIRECTOR_SCRIPT = preload("res://scripts/reactivo_mission_director.gd")
const ART_SCRIPT = preload("res://scripts/art_stage.gd")
const CINEMATIC_SCRIPT = preload("res://scripts/reactivo_cinematic_stage.gd")
const AUDIO_SCRIPT = preload("res://scripts/audio_fx.gd")
const EFFECT_SCRIPT = preload("res://scripts/reactivo_combat_fx.gd")

var contract: Dictionary = {}
var map_data: Dictionary = {}
var positions: Dictionary = {}
var director
var tactical_nav
var player
var camera: Camera3D
var stage: Node3D
var cinematic_stage: Node3D
var audio_fx: Node
var combat_fx: Node3D
var mission_label: Label
var health_label: Label
var prompt_label: Label
var result_label: Label
var progress_bar: ColorRect
var control_note: Label
var tactical_reticle: Label
var cover_label: Label
var consoles: Dictionary = {}
var objective_names: Dictionary = {}
var gate_body: StaticBody3D
var gate_shape: CollisionShape3D
var gate_visual: MeshInstance3D
var interact_held := false
var touch_move_id := -1
var touch_look_id := -1
var touch_move_origin := Vector2.ZERO
var touch_look_origin := Vector2.ZERO
var look_touch_axis := Vector2.ZERO
var interaction_progress := 0.0
var interaction_target := ""
var phase_time := 0.0
var encounter_spawned: Dictionary = {}
var elapsed := 0.0
var fire_timer := 0.0
var kills := 0
var failed := false
var won := false
var testing_disable_spawns := false

func _ready() -> void:
    var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(MISSION_PATH))
    var world: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
    if typeof(source) != TYPE_DICTIONARY or typeof(world) != TYPE_DICTIONARY:
        push_error("REACTIVO-13: missing mission/map JSON")
        return
    contract = source
    map_data = world
    for anchor in map_data["anchors"]:
        var position: Array = anchor["position"]
        positions[str(anchor["id"])] = Vector3(float(position[0]), float(position[1]), float(position[2]))
    director = DIRECTOR_SCRIPT.new()
    director.phase_changed.connect(_phase_changed)
    director.mission_finished.connect(_mission_finished)
    _build_world()
    tactical_nav = GRID_SCRIPT.new()
    tactical_nav.build(map_data)
    _make_player()
    _make_camera()
    _make_interactables()
    _make_hud()
    audio_fx = Node.new()
    audio_fx.set_script(AUDIO_SCRIPT)
    add_child(audio_fx)
    combat_fx = Node3D.new()
    combat_fx.set_script(EFFECT_SCRIPT)
    add_child(combat_fx)
    player.dash_started.connect(func() -> void: audio_fx.trigger("dash"))
    director.initialize(contract)
    _refresh_hud()

func _box(label: String, place: Vector3, size: Vector3, color: Color, solid: bool = true) -> Node3D:
    var root: Node3D
    if solid:
        var body := StaticBody3D.new()
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
        root = body
    else:
        root = Node3D.new()
    root.name = label
    root.position = place
    add_child(root)
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = 0.52
    material.roughness = 0.50
    visual.material_override = material
    root.add_child(visual)
    return root

func _build_world() -> void:
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#0a1422")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#8197ac")
    environment.ambient_light_energy = 0.46
    var world_env := WorldEnvironment.new()
    world_env.environment = environment
    add_child(world_env)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-60.0, -25.0, 0.0)
    key.light_color = Color("#b5d8f0")
    key.light_energy = 1.20
    key.shadow_enabled = true
    add_child(key)
    var bounds: Dictionary = map_data["bounds"]
    var width: float = float(bounds["width"])
    var depth: float = float(bounds["depth"])
    _box("Reactivo | solid base", Vector3(0, -0.55, 0), Vector3(width, 1.0, depth), Color("#263644"))
    _box("Reactivo | north wall", Vector3(0, 2.2, -depth / 2.0 - 0.6), Vector3(width+1.2, 4.4, 1.2), Color("#455362"))
    _box("Reactivo | south wall", Vector3(0, 2.2, depth / 2.0 + 0.6), Vector3(width+1.2, 4.4, 1.2), Color("#455362"))
    _box("Reactivo | east wall", Vector3(width / 2.0 + 0.6, 2.2, 0), Vector3(1.2, 4.4, depth+1.2), Color("#455362"))
    _box("Reactivo | west wall", Vector3(-width / 2.0 - 0.6, 2.2, 0), Vector3(1.2, 4.4, depth+1.2), Color("#455362"))
    for guide in map_data.get("authoring", {}).get("structure_guides", []):
        if guide.get("kind", "") != "cover":
            continue
        _box(str(guide["id"]), _vec(guide["position"]), _vec(guide["size"]), Color("#586c78"))
    stage = Node3D.new()
    stage.set_script(ART_SCRIPT)
    add_child(stage)
    stage.build(map_data, positions)
    cinematic_stage = Node3D.new()
    cinematic_stage.set_script(CINEMATIC_SCRIPT)
    add_child(cinematic_stage)
    # Distinct colored lanes anchor each combat/mission region.
    _box("Node A lit wayfinding", Vector3(-28, 0.07, 10), Vector3(10, 0.06, 0.14), Color("#438ca7"), false)
    _box("Node B lit wayfinding", Vector3(28, 0.07, 10), Vector3(10, 0.06, 0.14), Color("#b58b50"), false)
    _box("Reactor perimeter", Vector3(0, 0.09, -20), Vector3(25, 0.06, 0.16), Color("#df694e"), false)

func _vec(a: Array) -> Vector3:
    return Vector3(float(a[0]), float(a[1]), float(a[2]))

func _make_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(PLAYER_SCRIPT)
    player.position = positions["vanguard_start"] + Vector3(0, 1, 0)
    add_child(player)
    player.configure_cover_zones(map_data.get("authoring", {}).get("structure_guides", []))

func _make_camera() -> void:
    camera = Camera3D.new()
    camera.fov = 56.0
    camera.position = _camera_position()
    add_child(camera)
    camera.current = true
    camera.look_at(player.global_position + Vector3(-0.1, 0.80, -0.85), Vector3.UP)

func _camera_position() -> Vector3:
    var desired: Vector3 = player.global_position + Vector3(1.8, 2.75, 3.10)
    var half_w := float(map_data["bounds"]["width"]) / 2.0
    var half_d := float(map_data["bounds"]["depth"]) / 2.0
    desired.x = clampf(desired.x, -half_w + 2.0, half_w - 2.0)
    desired.z = clampf(desired.z, -half_d + 2.0, half_d - 2.0)
    if player.is_inside_tree():
        var from: Vector3 = player.global_position + Vector3(0, 0.7, 0)
        var query := PhysicsRayQueryParameters3D.create(from, desired)
        query.exclude = [player.get_rid()]
        var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
        if not hit.is_empty():
            desired = hit["position"] - (desired-from).normalized() * 0.25
    return desired

func _make_interactables() -> void:
    for object_id in ["node_a_console", "node_b_console", "reactor_altar", "stabilizer", "extraction_pad"]:
        var mesh := MeshInstance3D.new()
        mesh.name = "INTERACT | " + object_id
        var cylinder := CylinderMesh.new()
        cylinder.height = 0.23
        cylinder.top_radius = 1.30
        cylinder.bottom_radius = 1.30
        mesh.mesh = cylinder
        mesh.position = positions[object_id] + Vector3(0, 0.17, 0)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color("#50c0dc")
        mat.emission_enabled = true
        mat.emission = Color("#28a9d5")
        mat.emission_energy_multiplier = 1.4
        mesh.material_override = mat
        add_child(mesh)
        consoles[object_id] = mesh
        var marker := Label3D.new()
        marker.name = "REACTIVO objective marker | " + object_id
        marker.text = str({
            "node_a_console": "NODO A  //  ACTIVAR",
            "node_b_console": "NODO B  //  ACTIVAR",
            "reactor_altar": "REACTIVO-13  //  RECUPERAR",
            "stabilizer": "ESTABILIZADOR  //  DEFENDER",
            "extraction_pad": "SALIDA  //  EXTRAER"
        }.get(object_id, "OBJETIVO"))
        marker.font_size = 54
        marker.pixel_size = 0.0037
        marker.modulate = Color("#71f0ed")
        marker.outline_modulate = Color("#071421")
        marker.outline_size = 10
        marker.position = positions[object_id] + Vector3(0, 3.5, 0)
        add_child(marker)
        objective_names[object_id] = marker
    gate_body = StaticBody3D.new()
    gate_body.name = "Access Gate | A+B interlock"
    gate_body.position = Vector3(0, 1.6, 8.0)
    gate_shape = CollisionShape3D.new()
    var blocker := BoxShape3D.new()
    blocker.size = Vector3(8.0, 3.2, 0.75)
    gate_shape.shape = blocker
    gate_body.add_child(gate_shape)
    gate_visual = MeshInstance3D.new()
    gate_visual.name = "reactor access lock"
    var gate_mesh := BoxMesh.new()
    gate_mesh.size = Vector3(8.0, 3.2, 0.75)
    gate_visual.mesh = gate_mesh
    var gate_mat := StandardMaterial3D.new()
    gate_mat.albedo_color = Color("#788692")
    gate_mat.albedo_texture = load("res://assets/vendor/polyhaven_materials/green_metal_rust/diff.jpg") as Texture2D
    gate_mat.normal_enabled = true
    gate_mat.normal_texture = load("res://assets/vendor/polyhaven_materials/green_metal_rust/nor_gl.jpg") as Texture2D
    gate_mat.metallic = 0.77
    gate_mat.roughness = 0.39
    gate_visual.material_override = gate_mat
    gate_body.add_child(gate_visual)
    var blast_face := StandardMaterial3D.new()
    blast_face.albedo_color = Color("#566875")
    blast_face.metallic = 0.80
    blast_face.roughness = 0.42
    var inset := StandardMaterial3D.new()
    inset.albedo_color = Color("#283945")
    inset.metallic = 0.63
    inset.roughness = 0.40
    for panel_index in range(4):
        var rib := MeshInstance3D.new()
        rib.name = "Blast shield | recessed segmented plate %d" % panel_index
        var rib_shape := BoxMesh.new()
        rib_shape.size = Vector3(7.42, 0.57, 0.12)
        rib.mesh = rib_shape
        rib.position = Vector3(0, -1.11 + float(panel_index) * 0.72, 0.47)
        rib.material_override = blast_face if panel_index % 2 == 0 else inset
        gate_visual.add_child(rib)
    var brass := StandardMaterial3D.new()
    brass.albedo_color = Color("#fac475")
    brass.metallic = 0.7
    brass.roughness = 0.3
    for offset in [-3.0, 3.0]:
        var stripe := MeshInstance3D.new()
        var bar := BoxMesh.new()
        bar.size = Vector3(0.18, 2.7, 0.08)
        stripe.mesh = bar
        stripe.position = Vector3(offset, 0, 0.45)
        stripe.material_override = brass
        gate_visual.add_child(stripe)
    var safety_rail := StandardMaterial3D.new()
    safety_rail.albedo_color = Color("#6bcbd7")
    safety_rail.emission_enabled = true
    safety_rail.emission = Color("#27c2d8")
    safety_rail.emission_energy_multiplier = 1.0
    for stripe_y in [-1.36, 1.32]:
        var outline := MeshInstance3D.new()
        var outline_mesh := BoxMesh.new()
        outline_mesh.size = Vector3(7.4, 0.075, 0.075)
        outline.mesh = outline_mesh
        outline.name = "Access lock | readable teal edge"
        outline.position = Vector3(0, stripe_y, 0.50)
        outline.material_override = safety_rail
        gate_visual.add_child(outline)
    var lock_text := Label3D.new()
    lock_text.name = "Access gate | warning signage"
    lock_text.text = "REACTIVO-13   //   NODOS A + B"
    lock_text.font_size = 52
    lock_text.pixel_size = 0.0034
    lock_text.modulate = Color("#ffcf85")
    lock_text.position = Vector3(0, 0.45, 0.47)
    gate_visual.add_child(lock_text)
    add_child(gate_body)

func _make_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    var hud_panel := ColorRect.new()
    hud_panel.position = Vector2(10, 8)
    hud_panel.size = Vector2(596, 116)
    hud_panel.color = Color(0.015, 0.035, 0.055, 0.72)
    hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(hud_panel)
    health_label = _label(root, Vector2(20, 15), 21)
    mission_label = _label(root, Vector2(20, 44), 17)
    prompt_label = _label(root, Vector2(20, 73), 15)
    control_note = _label(root, Vector2(20, 122), 12)
    control_note.visible = OS.has_feature("mobile")
    control_note.text = "Mover WASD · Apuntar raton · Disparar clic/Espacio · E interactuar · Shift evasión"
    var bar_bg := ColorRect.new()
    bar_bg.position = Vector2(20, 103)
    bar_bg.size = Vector2(230, 5)
    bar_bg.color = Color("#334251")
    root.add_child(bar_bg)
    progress_bar = ColorRect.new()
    progress_bar.position = bar_bg.position
    progress_bar.size = Vector2(0, 5)
    progress_bar.color = Color("#40e0d0")
    root.add_child(progress_bar)
    # Aim indication matches the actual mouse ray on desktop and the touch aim center on Android.
    tactical_reticle = _label(root, Vector2.ZERO, 24)
    tactical_reticle.name = "Arcont tactical aiming reticle"
    tactical_reticle.text = "+"
    tactical_reticle.add_theme_color_override("font_color", Color("#83edec"))
    tactical_reticle.add_theme_color_override("font_shadow_color", Color(0.0, 0.07, 0.12, 0.9))
    tactical_reticle.add_theme_constant_override("shadow_offset_x", 1)
    tactical_reticle.add_theme_constant_override("shadow_offset_y", 1)
    cover_label = _label(root, Vector2(308, 93), 15)
    cover_label.name = "Contextual cover status"
    cover_label.add_theme_color_override("font_color", Color("#ffcb78"))
    result_label = _label(root, Vector2.ZERO, 39)
    result_label.set_anchors_preset(Control.PRESET_CENTER)
    result_label.offset_left = -350
    result_label.offset_top = -70
    result_label.offset_right = 350
    result_label.offset_bottom = 95
    result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_label.visible = false
    if OS.has_feature("mobile"):
        control_note.text = "Izquierda: movimiento  ·  Derecha: apuntar  ·  COBERTURA/IMPULSO"
        var interact := _mobile_button(root, "INTERACTUAR", -260, -20, -85, -20)
        interact.button_down.connect(func() -> void: interact_held = true)
        interact.button_up.connect(func() -> void: interact_held = false)
        var shoot := _mobile_button(root, "DISPARAR", -240, -20, -170, -110)
        shoot.button_down.connect(func() -> void: player.mobile_firing = true)
        shoot.button_up.connect(func() -> void: player.mobile_firing = false)
        var cover := _mobile_button(root, "COBERTURA", -445, -270, -170, -110)
        cover.pressed.connect(func() -> void: player.request_cover_toggle())
        var dash := _mobile_button(root, "IMPULSO", -420, -270, -80, -20)
        dash.pressed.connect(func() -> void: player.request_dash())
    var restart := _mobile_button(root, "REINICIAR", -170, -20, -70, -10)
    restart.anchor_top = 0
    restart.anchor_bottom = 0
    restart.offset_top = 14
    restart.offset_bottom = 75
    restart.visible = false
    result_label.visibility_changed.connect(func() -> void: restart.visible = result_label.visible)
    restart.pressed.connect(func() -> void: get_tree().reload_current_scene())

func _label(parent: Control, pos: Vector2, size: int) -> Label:
    var item := Label.new()
    item.position = pos
    item.add_theme_font_size_override("font_size", size)
    item.add_theme_color_override("font_color", Color("#c9eef4"))
    item.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(item)
    return item

func _mobile_button(parent: Control, title: String, x0: int, x1: int, y0: int, y1: int) -> Button:
    var btn := Button.new()
    btn.text = title
    btn.anchor_left = 1
    btn.anchor_right = 1
    btn.anchor_top = 1
    btn.anchor_bottom = 1
    btn.offset_left = x0
    btn.offset_right = x1
    btn.offset_top = y0
    btn.offset_bottom = y1
    parent.add_child(btn)
    return btn

func _input(event: InputEvent) -> void:
    if player == null or director == null or director.terminated:
        return
    if event is InputEventScreenTouch:
        var size := get_viewport().get_visible_rect().size
        if event.pressed:
            if touch_move_id == -1 and event.position.x < size.x * 0.48 and event.position.y > size.y * 0.35:
                touch_move_id = event.index
                touch_move_origin = event.position
            elif touch_look_id == -1 and event.position.x > size.x * 0.52 and event.position.y < size.y * 0.73:
                touch_look_id = event.index
                touch_look_origin = event.position
        else:
            if event.index == touch_move_id:
                touch_move_id = -1
                player.touch_axis = Vector2.ZERO
            if event.index == touch_look_id:
                touch_look_id = -1
                look_touch_axis = Vector2.ZERO
    elif event is InputEventScreenDrag:
        if event.index == touch_move_id:
            player.touch_axis = ((event.position - touch_move_origin) / 78.0).limit_length(1.0)
        elif event.index == touch_look_id:
            look_touch_axis = ((event.position - touch_look_origin) / 88.0).limit_length(1.0)

func _process(delta: float) -> void:
    if player == null or director == null:
        return
    if tactical_reticle != null:
        var pointer := get_viewport().get_visible_rect().size * 0.5 if OS.has_feature("mobile") else get_viewport().get_mouse_position()
        tactical_reticle.position = pointer - Vector2(7, 17)
    camera.position = camera.position.lerp(_camera_position(), minf(1.0, delta * 6.0))
    camera.look_at(player.global_position + Vector3(-0.1, 0.80, -0.85), Vector3.UP)
    camera.fov = lerpf(camera.fov, 49.0 if player.wants_to_fire() else 56.0, minf(1.0, delta * 6.0))
    if director.terminated:
        return
    elapsed += delta
    phase_time += delta
    if player.health <= 0:
        director.fail()
        return
    if director.phase_id == "insertion" and _inside_zone("access", player.global_position):
        director.complete("reach_access")
    if director.phase_id == "defense":
        director.update_defense(delta, get_tree().get_nodes_in_group("enemies").size())
    _update_aim()
    _interact_tick(delta)
    _refresh_hud()

func _inside_zone(id: String, where: Vector3) -> bool:
    for zone in contract["zones"]:
        if str(zone["id"]) == id:
            var rect: Dictionary = zone["rect"]
            return where.x >= float(rect["min_x"]) and where.x <= float(rect["max_x"]) and where.z >= float(rect["min_z"]) and where.z <= float(rect["max_z"])
    return false

func _update_aim() -> void:
    var direction := Vector3.ZERO
    if touch_look_id != -1 and look_touch_axis.length_squared() > 0.03:
        direction = Vector3(look_touch_axis.x, 0, look_touch_axis.y)
    elif player.mobile_firing or Input.is_key_pressed(KEY_SPACE):
        var best := 35.0
        for node in get_tree().get_nodes_in_group("enemies"):
            var offset: Vector3 = node.global_position - player.global_position
            offset.y = 0
            if offset.length() < best:
                best = offset.length()
                direction = offset
    elif not OS.has_feature("mobile"):
        var cursor := get_viewport().get_mouse_position()
        var origin := camera.project_ray_origin(cursor)
        var vector := camera.project_ray_normal(cursor)
        var point: Variant = Plane(Vector3.UP, 1.0).intersects_ray(origin, vector)
        if point != null:
            direction = Vector3(point.x - player.global_position.x, 0, point.z - player.global_position.z)
    if direction.length_squared() > 0.01:
        player.aim_direction = direction.normalized()
    player.aim_pitch = clampf(-look_touch_axis.y * 0.12, -0.12, 0.12)

func _physics_process(delta: float) -> void:
    if director == null or director.terminated:
        return
    fire_timer = maxf(0.0, fire_timer - delta)
    if fire_timer <= 0.0 and player.wants_to_fire():
        fire_timer = 0.2
        _fire()

func _fire() -> void:
    player.on_weapon_fired()
    audio_fx.trigger("fire")
    var origin: Vector3 = player.global_position + Vector3(0, 0.18, 0)
    var destination: Vector3 = origin + player.aim_direction.normalized() * 35.0
    var query := PhysicsRayQueryParameters3D.create(origin, destination)
    query.exclude = [player.get_rid()]
    var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
    if not result.is_empty():
        destination = result["position"]
        var collider: Object = result["collider"]
        if collider != null:
            if collider.has_method("take_hit_from"):
                collider.call("take_hit_from", 23, origin)
            elif collider.has_method("take_hit"):
                collider.call("take_hit", 23)
    if combat_fx != null:
        combat_fx.muzzle(origin, player.aim_direction)
        combat_fx.tracer(origin, destination)
    register_hit_feedback(destination)

func _available_target() -> String:
    var objective_ids: Array = director.phase_objectives()
    for objective_id in objective_ids:
        var id := str(objective_id)
        var obj: Dictionary = director.get_objective(id)
        if str(obj.get("kind", "")) != "interact" or not director.can_complete(id):
            continue
        var at: Vector3 = positions[str(obj["target"])]
        var gap: Vector3 = player.global_position - at
        gap.y = 0
        if gap.length() <= 2.6:
            return id
    return ""

func _interact_tick(delta: float) -> void:
    var selected: String = _available_target()
    if selected != interaction_target:
        interaction_target = selected
        interaction_progress = 0.0
    if selected.is_empty():
        return
    if interact_held or Input.is_key_pressed(KEY_E):
        var objective: Dictionary = director.get_objective(selected)
        interaction_progress += delta
        if interaction_progress >= float(objective["duration_seconds"]):
            director.complete(selected)
            interaction_progress = 0.0
    else:
        interaction_progress = 0.0

func _phase_changed(next_phase: String) -> void:
    phase_time = 0.0
    interaction_progress = 0.0
    interaction_target = ""
    if cinematic_stage != null:
        cinematic_stage.set_reactor_alarm(next_phase == "defense")
    if next_phase == "core_chamber" and gate_shape != null:
        gate_shape.set_deferred("disabled", true)
        gate_visual.visible = false
    if not testing_disable_spawns:
        _spawn_phase_encounters(next_phase)

func _spawn_phase_encounters(phase: String) -> void:
    for encounter in contract.get("encounters", []):
        if str(encounter["phase"]) != phase or encounter_spawned.has(str(encounter["id"])):
            continue
        encounter_spawned[str(encounter["id"])] = true
        var spawn_points: Array = encounter["spawn_anchor_ids"]
        var ordinal := 0
        for unit in encounter["units"]:
            for _i in range(int(unit["count"])):
                if get_tree().get_nodes_in_group("enemies").size() >= int(contract["caps"]["global_hostiles"]):
                    break
                var spawn_id: String = str(spawn_points[ordinal % spawn_points.size()])
                _spawn_role(str(unit["role"]), positions[spawn_id] + Vector3(float(ordinal % 3)*1.4, 1.0, 0))
                ordinal += 1

func _spawn_role(role: String, at: Vector3) -> void:
    var body := CharacterBody3D.new()
    if role == "bulwark":
        body.set_script(BULWARK_SCRIPT)
    elif role == "eyedrone":
        body.set_script(TELEGRAPH_DRONE_SCRIPT)
        body.asset_kind = "eye"
    else:
        body.set_script(QUAD_SCRIPT)
        body.asset_kind = "quad"
    body.target = player
    body.director = self
    body.position = at
    add_child(body)

func _mission_finished(success: bool) -> void:
    won = success
    failed = not success
    player.mobile_firing = false
    player.set_physics_process(false)
    get_tree().call_group("enemies", "set_physics_process", false)
    result_label.visible = true
    if success:
        audio_fx.trigger("victory")
        result_label.text = "REACTIVO-13 RECUPERADO\nEXTRACCIÓN COMPLETA · %d bajas · %d s" % [kills, int(elapsed)]
    else:
        result_label.text = "MISIÓN FALLIDA\nREINICIA PARA REINTENTAR"

func _refresh_hud() -> void:
    if director == null or health_label == null:
        return
    health_label.text = "FISURA // REACTIVO-13   HP %d   BAJAS %d" % [player.health, kills]
    var descriptions := {
        "insertion":"01 / INSERCIÓN · Avanza hasta el taller",
        "penetration":"02 / PENETRACIÓN · Enciende NODOS A y B",
        "core_chamber":"03 / REACTOR · Recupera núcleo central",
        "defense":"04 / DEFENSA · Resiste 75 s y despeja zona",
        "extraction":"05 / EXTRACCIÓN · Escapa hacia plataforma norte"
    }
    mission_label.text = str(descriptions.get(director.phase_id, "REACTIVO-13"))
    if director.phase_id == "penetration":
        mission_label.text += "   A:%s B:%s" % ["OK" if director.is_complete("power_a") else "--", "OK" if director.is_complete("power_b") else "--"]
    elif director.phase_id == "defense":
        mission_label.text += "   %d/75 s · %d enemigos" % [mini(75, int(director.defense_seconds)), get_tree().get_nodes_in_group("enemies").size()]
    var names := {
        "node_a_console":"power_a",
        "node_b_console":"power_b",
        "reactor_altar":"collect_reactor",
        "stabilizer":"defense_hold",
        "extraction_pad":"evacuate"
    }
    for visual_id in objective_names:
        var objective_id: String = names[visual_id]
        var marker: Label3D = objective_names[visual_id]
        marker.visible = director.can_complete(objective_id)
    var target := _available_target()
    prompt_label.text = "Mantén E / INTERACTUAR" if not target.is_empty() else "Sigue el objetivo marcado"
    if cover_label != null:
        cover_label.text = "EN COBERTURA  [Q]" if player.in_cover else ("COBERTURA [Q]" if player.can_take_cover() else "")
    
    progress_bar.size.x = 0.0
    if not target.is_empty():
        var item: Dictionary = director.get_objective(target)
        progress_bar.size.x = 230.0 * clampf(interaction_progress / float(item["duration_seconds"]), 0, 1)

func register_kill() -> void:
    kills += 1

func register_hit_feedback(at: Vector3) -> void:
    if combat_fx != null:
        combat_fx.hit(at)
    var spark := MeshInstance3D.new()
    spark.name = "REACTIVO | projectile impact"
    var ball := SphereMesh.new()
    ball.radius = 0.17
    ball.height = 0.34
    spark.mesh = ball
    var glow := StandardMaterial3D.new()
    glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    glow.albedo_color = Color("#ffad51")
    glow.emission_enabled = true
    glow.emission = Color("#ff5a29")
    spark.material_override = glow
    spark.position = at
    add_child(spark)
    var t := create_tween()
    t.tween_property(spark, "scale", Vector3.ONE * 0.01, 0.14)
    t.finished.connect(spark.queue_free)

func register_damage_feedback() -> void:
    if audio_fx != null:
        audio_fx.trigger("damage")

func register_enemy_telegraph(start: Vector3, target: Vector3, duration: float) -> void:
    if combat_fx != null:
        combat_fx.enemy_charge(start, target, duration)

func register_enemy_laser(start: Vector3, target: Vector3) -> void:
    # One visually bounded emitter. The old beam called Node3D.look_at before entering tree.
    if combat_fx != null:
        combat_fx.hostile_beam(start, target)
