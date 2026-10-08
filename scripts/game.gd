extends Node3D
## FISURA: vertical slice 0.1. El mundo y sus objetivos vienen de un contrato ARCONT.
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")
const ART_STAGE_SCRIPT = preload("res://scripts/art_stage.gd")
const NAV_SCRIPT = preload("res://scripts/tactical_grid.gd")
const AUDIO_SCRIPT = preload("res://scripts/audio_fx.gd")
const MAP_PATH := "res://maps/crisol_01.json"
const CORE_GOAL := 3
const MAX_ENEMIES := 12
const SHOCK_PERIOD := 12.0

var map_data: Dictionary = {}
var anchors: Dictionary = {}
var player
var camera: Camera3D
var stage: Node3D
var tactical_nav
var audio_fx: Node
var hit_overlay: ColorRect
var portal: MeshInstance3D
var portal_material: StandardMaterial3D
var hazard_disk: MeshInstance3D
var cores: Array[Node3D] = []
var enemy_spawn_points: Array[Vector3] = []
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var spawn_timer := 1.0
var fire_timer := 0.0
var shock_clock := 0.0
var hazard_center := Vector3.ZERO
var hazard_radius := 6.0
var last_shock_phase := 0.0
var collected := 0
var kills := 0
var finished := false
var hp_label: Label
var mission_label: Label
var controls_label: Label
var result_label: Label
var health_bar: ColorRect
var move_touch_id := -1
var move_touch_start := Vector2.ZERO

func _ready() -> void:
    rng.randomize()
    if not _read_map():
        return
    _build_environment()
    _build_arena()
    _create_navigation()
    _create_art_stage()
    _create_player()
    _create_camera()
    _create_objectives()
    _create_hud()
    _create_audio()
    _update_hud()

func _read_map() -> bool:
    if not FileAccess.file_exists(MAP_PATH):
        push_error("Mapa no encontrado: " + MAP_PATH)
        return false
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("Contrato JSON invalido")
        return false
    map_data = parsed
    for region in map_data.get("regions", []):
        if region.get("kind", "") == "hazard":
            hazard_center = _vec3(region.get("center", [0, 0, 0]))
            hazard_radius = float(region.get("radius", 6.0))
    for item in map_data.get("anchors", []):
        anchors[item.get("id", "")] = _vec3(item.get("position", [0, 0, 0]))
        if item.get("kind", "") == "spawn" and item.get("team", "") == "enemy":
            enemy_spawn_points.append(_vec3(item.get("position", [0, 0, 0])))
    if not anchors.has("player_start") or not anchors.has("exit_portal"):
        push_error("Faltan anclajes de entrada/salida")
        return false
    if enemy_spawn_points.is_empty():
        push_error("El mapa no define spawns enemigos")
        return false
    return true

func _vec3(value: Array) -> Vector3:
    return Vector3(float(value[0]), float(value[1]), float(value[2]))

func _build_environment() -> void:
    var world_env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#090f1c")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#6d819e")
    environment.ambient_light_energy = 0.94
    world_env.environment = environment
    add_child(world_env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-58.0, -29.0, 0.0)
    sun.light_color = Color("#a6c5dc")
    sun.light_energy = 1.55
    sun.shadow_enabled = true
    add_child(sun)

func _build_arena() -> void:
    var width := float(map_data["bounds"]["width"])
    var depth := float(map_data["bounds"]["depth"])
    _box("Piso del Crisol", Vector3(0, -0.50, 0), Vector3(width, 1, depth), Color("#202b3b"))
    var wall := Color("#3b4158")
    _box("Muralla norte", Vector3(0, 1.4, -22.5), Vector3(45, 2.8, 1), wall)
    _box("Muralla sur", Vector3(0, 1.4, 22.5), Vector3(45, 2.8, 1), wall)
    _box("Muralla oeste", Vector3(-22.5, 1.4, 0), Vector3(1, 2.8, 45), wall)
    _box("Muralla este", Vector3(22.5, 1.4, 0), Vector3(1, 2.8, 45), wall)
    for guide in map_data.get("authoring", {}).get("structure_guides", []):
        _box(str(guide.get("id", "cover")), _vec3(guide["position"]), _vec3(guide["size"]), Color("#566176"))
    _box("Umbral", Vector3(0, 0.05, -17), Vector3(5.0, 0.1, 1.3), Color("#8ccfdd"), false)
    hazard_disk = MeshInstance3D.new()
    hazard_disk.name = "Alerta de pulso"
    var disk := CylinderMesh.new()
    disk.top_radius = hazard_radius
    disk.bottom_radius = hazard_radius
    disk.height = 0.035
    hazard_disk.mesh = disk
    hazard_disk.position = hazard_center + Vector3(0, 0.08, 0)
    var danger := StandardMaterial3D.new()
    danger.albedo_color = Color("#8e372b")
    danger.emission_enabled = true
    danger.emission = Color("#a72b18")
    danger.emission_energy_multiplier = 0.65
    hazard_disk.material_override = danger
    hazard_disk.visible = false
    add_child(hazard_disk)

func _box(label: String, pos: Vector3, size: Vector3, color: Color, solid: bool = true) -> void:
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
    root.position = pos
    add_child(root)
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = 0.42
    material.roughness = 0.62
    if not solid:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 1.4
    visual.material_override = material
    root.add_child(visual)

func _create_navigation() -> void:
    tactical_nav = NAV_SCRIPT.new()
    tactical_nav.build(map_data)

func _create_audio() -> void:
    audio_fx = Node.new()
    audio_fx.set_script(AUDIO_SCRIPT)
    add_child(audio_fx)
    player.dash_started.connect(func() -> void: audio_fx.trigger("dash"))

func _create_art_stage() -> void:
    stage = Node3D.new()
    stage.set_script(ART_STAGE_SCRIPT)
    add_child(stage)
    stage.build(map_data, anchors)

func _create_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(PLAYER_SCRIPT)
    player.position = anchors["player_start"] + Vector3(0, 1, 0)
    add_child(player)

func _create_camera() -> void:
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_PERSPECTIVE
    camera.fov = 51.0
    camera.position = player.global_position + Vector3(0, 15, 13)
    add_child(camera)
    camera.current = true
    camera.look_at(player.global_position + Vector3(0, 0, -4), Vector3.UP)

func _create_objectives() -> void:
    for anchor_id in ["core_alpha", "core_beta", "core_gamma"]:
        if not anchors.has(anchor_id):
            push_error("Falta objetivo " + anchor_id)
            continue
        var core := Node3D.new()
        core.name = anchor_id
        core.position = anchors[anchor_id] + Vector3(0, 1.1, 0)
        add_child(core)
        var orb := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = 0.66
        sphere.height = 1.32
        orb.mesh = sphere
        var glow := StandardMaterial3D.new()
        glow.albedo_color = Color("#42f6e7")
        glow.metallic = 0.4
        glow.emission_enabled = true
        glow.emission = Color("#19dec1")
        glow.emission_energy_multiplier = 2.5
        orb.material_override = glow
        core.add_child(orb)
        cores.append(core)
    portal = MeshInstance3D.new()
    portal.name = "Portal de extraccion"
    var portal_mesh := CylinderMesh.new()
    portal_mesh.top_radius = 2.1
    portal_mesh.bottom_radius = 2.1
    portal_mesh.height = 0.15
    portal.mesh = portal_mesh
    portal.position = anchors["exit_portal"] + Vector3(0, 0.15, 0)
    portal_material = StandardMaterial3D.new()
    portal_material.albedo_color = Color("#48596a")
    portal_material.emission_enabled = true
    portal_material.emission = Color("#112a3a")
    portal_material.emission_energy_multiplier = 1.4
    portal.material_override = portal_material
    add_child(portal)

func _create_hud() -> void:
    var overlay := CanvasLayer.new()
    add_child(overlay)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.add_child(root)
    hit_overlay = ColorRect.new()
    hit_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    hit_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hit_overlay.color = Color(0.88, 0.1, 0.06, 0.0)
    root.add_child(hit_overlay)
    var banner := Panel.new()
    banner.name = "HUD - telemetria tactica"
    banner.position = Vector2(12, 10)
    banner.size = Vector2(820, 129)
    banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var panel_skin := StyleBoxFlat.new()
    panel_skin.bg_color = Color(0.025, 0.042, 0.075, 0.90)
    panel_skin.border_color = Color("#21708a")
    panel_skin.border_width_left = 2
    panel_skin.border_width_top = 1
    panel_skin.border_width_bottom = 2
    panel_skin.corner_radius_top_left = 8
    panel_skin.corner_radius_top_right = 8
    panel_skin.corner_radius_bottom_left = 8
    panel_skin.corner_radius_bottom_right = 8
    banner.add_theme_stylebox_override("panel", panel_skin)
    root.add_child(banner)
    var bar_back := ColorRect.new()
    bar_back.position = Vector2(21, 111)
    bar_back.size = Vector2(244, 10)
    bar_back.color = Color("#284359")
    bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(bar_back)
    health_bar = ColorRect.new()
    health_bar.position = Vector2(21, 111)
    health_bar.size = Vector2(244, 10)
    health_bar.color = Color("#42d9e3")
    health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(health_bar)
    hp_label = _label(root, Vector2(20, 12), 24)
    mission_label = _label(root, Vector2(20, 49), 20)
    controls_label = _label(root, Vector2(20, 82), 16)
    controls_label.text = "WASD/flechas: mover  |  Clic/Espacio: disparar  |  Shift: impulso"
    result_label = _label(root, Vector2.ZERO, 39)
    result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_label.anchor_left = 0.15
    result_label.anchor_right = 0.85
    result_label.anchor_top = 0.38
    result_label.anchor_bottom = 0.66
    result_label.offset_left = 0.0
    result_label.offset_top = 0.0
    result_label.offset_right = 0.0
    result_label.offset_bottom = 0.0
    result_label.visible = false
    if OS.has_feature("mobile"):
        controls_label.text = "Arrastra abajo a la izquierda para moverte"
        var fire := _mobile_button(root, "DISPARAR", -210, -45, -180, -35)
        fire.button_down.connect(func() -> void: player.mobile_firing = true)
        fire.button_up.connect(func() -> void: player.mobile_firing = false)
        var dash := _mobile_button(root, "IMPULSO", -385, -220, -140, -35)
        dash.pressed.connect(func() -> void: player.request_dash())
    var restart := _mobile_button(root, "REINICIAR", -170, -20, -70, -10)
    restart.anchor_top = 0.0
    restart.anchor_bottom = 0.0
    restart.offset_top = 14.0
    restart.offset_bottom = 70.0
    restart.visible = false
    result_label.visibility_changed.connect(func() -> void: restart.visible = result_label.visible)
    restart.pressed.connect(func() -> void: get_tree().reload_current_scene())

func _label(parent: Control, location: Vector2, font_size: int) -> Label:
    var label := Label.new()
    label.position = location
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("#d4f6ff"))
    label.add_theme_color_override("font_shadow_color", Color("#061019"))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    parent.add_child(label)
    return label

func _mobile_button(parent: Control, label: String, left: int, right: int, top: int, bottom: int) -> Button:
    var button := Button.new()
    button.text = label
    button.anchor_left = 1.0
    button.anchor_right = 1.0
    button.anchor_top = 1.0
    button.anchor_bottom = 1.0
    button.offset_left = left
    button.offset_right = right
    button.offset_top = top
    button.offset_bottom = bottom
    button.add_theme_font_size_override("font_size", 21)
    parent.add_child(button)
    return button

func _input(event: InputEvent) -> void:
    if player == null or finished:
        return
    if event is InputEventScreenTouch:
        if event.pressed and move_touch_id == -1:
            var screen := get_viewport().get_visible_rect().size
            if event.position.x < screen.x * 0.48 and event.position.y > screen.y * 0.34:
                move_touch_id = event.index
                move_touch_start = event.position
        elif not event.pressed and event.index == move_touch_id:
            move_touch_id = -1
            player.touch_axis = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == move_touch_id:
        player.touch_axis = ((event.position - move_touch_start) / 78.0).limit_length(1.0)

func _process(delta: float) -> void:
    if player == null:
        return
    camera.position = camera.position.lerp(player.global_position + Vector3(0, 15, 13), minf(1.0, delta * 6.0))
    camera.look_at(player.global_position + Vector3(0, 0, -4), Vector3.UP)
    if finished:
        if Input.is_key_pressed(KEY_R):
            get_tree().reload_current_scene()
        return
    elapsed += delta
    for core in cores:
        if is_instance_valid(core):
            core.rotate_y(delta * 1.7)
            core.position.y = 1.12 + sin(elapsed * 3.0 + float(core.get_instance_id() % 5)) * 0.15
    _update_aim()
    _check_objectives()
    _update_hazard(delta)
    _update_hud()

func _physics_process(delta: float) -> void:
    if player == null or finished:
        return
    fire_timer = maxf(0.0, fire_timer - delta)
    spawn_timer -= delta
    if spawn_timer <= 0.0:
        spawn_timer = maxf(1.2, 3.0 - elapsed * 0.013)
        _spawn_enemy()
    if fire_timer <= 0.0 and player.wants_to_fire():
        fire_timer = 0.20
        _fire_rifle()

func _update_aim() -> void:
    var direction := Vector3.ZERO
    if player.mobile_firing or Input.is_key_pressed(KEY_SPACE):
        direction = _target_nearest_enemy()
    elif not OS.has_feature("mobile"):
        var cursor := get_viewport().get_mouse_position()
        var projected: Variant = Plane(Vector3.UP, 1.0).intersects_ray(camera.project_ray_origin(cursor), camera.project_ray_normal(cursor))
        if projected != null:
            direction = Vector3(projected.x - player.global_position.x, 0, projected.z - player.global_position.z)
    if direction.length_squared() > 0.01:
        player.aim_direction = direction.normalized()

func _target_nearest_enemy() -> Vector3:
    var best_distance := 34.0
    var best := Vector3.ZERO
    for node in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(node):
            continue
        var delta_pos: Vector3 = node.global_position - player.global_position
        delta_pos.y = 0.0
        if delta_pos.length() < best_distance:
            best_distance = delta_pos.length()
            best = delta_pos
    return best

func _fire_rifle() -> void:
    audio_fx.trigger("fire")
    var from: Vector3 = player.global_position + Vector3(0, 0.18, 0)
    var to: Vector3 = from + player.aim_direction * 34.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [player.get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        to = hit["position"]
        var collider: Object = hit["collider"]
        if collider != null and collider.has_method("take_hit"):
            collider.call("take_hit", 23)
    var beam := MeshInstance3D.new()
    beam.name = "Disparo"
    var shape := BoxMesh.new()
    shape.size = Vector3(0.10, 0.10, maxf(0.10, from.distance_to(to)))
    beam.mesh = shape
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#f9fcac")
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = Color("#faff9d")
    beam.material_override = material
    add_child(beam)
    beam.global_position = (from + to) * 0.5
    if from.distance_to(to) > 0.3:
        beam.look_at(to, Vector3.UP)
    get_tree().create_timer(0.07).timeout.connect(beam.queue_free)

func _spawn_enemy() -> void:
    if get_tree().get_nodes_in_group("enemies").size() >= MAX_ENEMIES:
        return
    var chosen := enemy_spawn_points[rng.randi_range(0, enemy_spawn_points.size() - 1)]
    if Vector2(chosen.x - player.position.x, chosen.z - player.position.z).length() < 8.0:
        return
    var enemy := CharacterBody3D.new()
    enemy.set_script(ENEMY_SCRIPT)
    enemy.target = player
    enemy.director = self
    enemy.position = chosen + Vector3(0, 1, 0)
    enemy.speed = 3.4 + minf(2.2, elapsed * 0.014)
    add_child(enemy)

func register_kill() -> void:
    kills += 1

func _check_objectives() -> void:
    for core in cores:
        if not is_instance_valid(core):
            continue
        if player.global_position.distance_to(core.global_position) < 1.6:
            cores.erase(core)
            core.queue_free()
            collected += 1
            audio_fx.trigger("pickup")
            if collected == CORE_GOAL:
                portal_material.albedo_color = Color("#29eacb")
                portal_material.emission = Color("#00eabc")
                portal_material.emission_energy_multiplier = 3.3
            break
    if collected >= CORE_GOAL:
        var exit_pos: Vector3 = anchors["exit_portal"]
        var flat_distance := Vector2(player.global_position.x - exit_pos.x, player.global_position.z - exit_pos.z).length()
        if flat_distance < 2.1:
            _finish(true)

func _update_hazard(delta: float) -> void:
    shock_clock += delta
    var phase := fmod(shock_clock, SHOCK_PERIOD)
    hazard_disk.visible = phase >= 9.3
    if phase < last_shock_phase:
        var gap := Vector2(player.global_position.x - hazard_center.x, player.global_position.z - hazard_center.z).length()
        if gap < hazard_radius:
            player.take_damage(20)
    last_shock_phase = phase
    if player.health <= 0:
        _finish(false)

func _update_hud() -> void:
    hp_label.text = "FISURA  //  HP %d   |   NUCLEOS %d/%d   |   BAJAS %d" % [player.health, collected, CORE_GOAL, kills]
    health_bar.size.x = 244.0 * clampf(float(player.health) / float(player.max_health), 0.0, 1.0)
    health_bar.color = Color("#fc6f62") if player.health <= 30 else Color("#42d9e3")
    if collected == CORE_GOAL:
        mission_label.text = "PORTAL ABIERTO: corre a la plataforma turquesa del norte"
    else:
        mission_label.text = "Recoge los 3 nucleos y sobrevive. Pulso peligroso en el centro cada 12 s."
    if hazard_disk.visible:
        mission_label.text += "  [PULSO INMINENTE]"

func _finish(won: bool) -> void:
    if finished:
        return
    finished = true
    player.mobile_firing = false
    player.set_physics_process(false)
    if won:
        audio_fx.trigger("victory")
    get_tree().call_group("enemies", "set_physics_process", false)
    result_label.visible = true
    if won:
        result_label.text = "EXTRACCION COMPLETA\n%d bajas en %d s\nPulsa R o REINICIAR" % [kills, int(elapsed)]
    else:
        result_label.text = "MISIÓN FALLIDA\n%d nucleos recuperados\nPulsa R o REINICIAR" % collected

func register_hit_feedback(at: Vector3) -> void:
    if audio_fx != null:
        audio_fx.trigger("hit")
    var spark := MeshInstance3D.new()
    spark.name = "Impacto de proyectil - flash"
    var mesh := SphereMesh.new()
    mesh.radius = 0.23
    mesh.height = 0.46
    spark.mesh = mesh
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color("#ffdc95")
    material.emission_enabled = true
    material.emission = Color("#ff7c31")
    material.emission_energy_multiplier = 3.0
    spark.material_override = material
    spark.position = at + Vector3(0, 0.25, 0)
    add_child(spark)
    var fade := create_tween()
    fade.tween_property(spark, "scale", Vector3.ONE * 0.05, 0.17)
    fade.finished.connect(spark.queue_free)

func register_damage_feedback() -> void:
    if audio_fx != null:
        audio_fx.trigger("damage")
    if hit_overlay == null:
        return
    hit_overlay.color = Color(0.92, 0.14, 0.06, 0.34)
    var fade := create_tween()
    fade.tween_property(hit_overlay, "color:a", 0.0, 0.32)
