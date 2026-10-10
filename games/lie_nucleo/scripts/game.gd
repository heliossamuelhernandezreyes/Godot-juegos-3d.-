extends Node3D
## LIE: NUCLEO OMEGA — playable prototype in isolated Godot 4.7.2 project.
## Hybrid: conventional CharacterBody3D/physics/level; the central core is
## genuinely drawn by Lie Vulkan image-based depth reconstruction (no sphere mesh).
const LieCore = preload("res://scripts/lie_core_effect.gd")
const SPEED := 6.0
const DASH_SPEED := 14.0
const CORE_POS := Vector3(0,1.65,0)
const SPAWNS := [Vector3(-7,0,-3),Vector3(7,0,-4),Vector3(3,0,8),Vector3(-7,0,6)]
const BEACON_SPOTS := [Vector3(-7,0,-6),Vector3(7,0,-6),Vector3(0,0,9)]

var world_environment: WorldEnvironment
var player: CharacterBody3D
var player_visual: MeshInstance3D
var camera: Camera3D
var lie_effect: CompositorEffect
var core_fallback: MeshInstance3D
var enemies: Array[Node3D] = []
var enemy_hp: Dictionary = {}
var beacons: Array[Node3D] = []
var gate: Node3D
var health := 100
var collected := 0
var kills := 0
var finished := false
var won := false
var yaw := 0.0
var health_label: Label
var info_label: Label
var tech_label: Label
var help_label: Label
var firing := false
var fire_cooldown := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var hit_cooldown := 0.0
var beam_time := 0.0
var beam: MeshInstance3D
var touch_left := -1
var touch_right := -1
var left_origin := Vector2.ZERO
var touch_move := Vector2.ZERO

func _ready() -> void:
    _create_world()
    _create_player()
    _create_camera_and_lie()
    _create_objectives()
    _create_enemies()
    _create_hud()
    _update_camera()
    _refresh_hud()

func _mat(color: Color, emission: float = 0.0, metal: float = 0.15) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metal
    material.roughness = 0.36
    if emission > 0.0:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = emission
    return material

func _mesh_box(parent: Node3D, name: String, at: Vector3, size: Vector3,
        color: Color, metal: float = 0.18) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = name
    var m := BoxMesh.new()
    m.size = size
    instance.mesh = m
    instance.material_override = _mat(color,0.0,metal)
    instance.position = at
    parent.add_child(instance)
    return instance

func _static_box(name: String, pos: Vector3, size: Vector3, color: Color) -> void:
    var body := StaticBody3D.new()
    body.name = name
    body.position = pos
    add_child(body)
    _mesh_box(body,"Mesh",Vector3.ZERO,size,color)
    var c := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    c.shape = shape
    body.add_child(c)

func _create_world() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.018,0.029,0.055)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.23,0.35,0.53)
    env.ambient_light_energy = 0.6
    world.environment = env
    world.name = "WorldEnvironment"
    world_environment = world
    add_child(world)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-48,28,0)
    light.light_color = Color(0.57,0.77,1.0)
    light.light_energy = 1.3
    add_child(light)
    _static_box("Arena",Vector3(0,-0.55,0),Vector3(27,1,27),Color(0.12,0.17,0.23))
    for x in range(-12,13,3):
        _mesh_box(self,"FloorSeamX",Vector3(float(x),0.008,0),Vector3(0.045,0.015,26),Color(0.16,0.32,0.38))
        _mesh_box(self,"FloorSeamZ",Vector3(0,0.009,float(x)),Vector3(26,0.015,0.045),Color(0.16,0.32,0.38))
    _static_box("WallNorth",Vector3(0,1.4,-13.5),Vector3(27,2.8,0.8),Color(0.14,0.2,0.27))
    _static_box("WallSouth",Vector3(0,1.4,13.5),Vector3(27,2.8,0.8),Color(0.14,0.2,0.27))
    _static_box("WallEast",Vector3(13.5,1.4,0),Vector3(0.8,2.8,27),Color(0.14,0.2,0.27))
    _static_box("WallWest",Vector3(-13.5,1.4,0),Vector3(0.8,2.8,27),Color(0.14,0.2,0.27))
    for x in [-9.0,9.0]:
        for z in [-9.0,0.0,9.0]:
            _static_box("SteelCover",Vector3(x,0.8,z),Vector3(2.2,1.6,1.0),Color(0.29,0.34,0.41))
            _mesh_box(self,"CoverMark",Vector3(x,1.61,z),Vector3(1.8,0.04,0.55),Color(0.08,0.58,0.65))
    var base := CylinderMesh.new()
    base.top_radius = 1.55
    base.bottom_radius = 1.7
    base.height = 0.4
    var pedestal := MeshInstance3D.new()
    pedestal.mesh = base
    pedestal.position = Vector3(0,0.21,0)
    pedestal.material_override = _mat(Color(0.12,0.23,0.34),0.0,0.7)
    add_child(pedestal)
    var glow := OmniLight3D.new()
    glow.position = Vector3(0,2.4,0)
    glow.light_color = Color(0.27,0.58,1.0)
    glow.light_energy = 1.9
    glow.omni_range = 7.0
    add_child(glow)
    for i in range(8):
        var phi: float = float(i)*TAU/8.0
        _mesh_box(self,"ReactorGuard",Vector3(1.85*sin(phi),0.47,1.85*cos(phi)),
            Vector3(0.24,0.9,0.24),Color(0.22,0.48,0.58))
    for z in [-5.5,5.5]:
        for x in [-3.8,3.8]:
            _static_box("LowCover",Vector3(x,0.55,z),Vector3(2,1.1,0.6),Color(0.19,0.27,0.33))

func _create_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Operator"
    player.position = Vector3(0,0.95,6.0)
    add_child(player)
    var shape := CapsuleShape3D.new()
    shape.radius = 0.39
    shape.height = 1.8
    var collision := CollisionShape3D.new()
    collision.shape = shape
    player.add_child(collision)
    player_visual = MeshInstance3D.new()
    var model := CapsuleMesh.new()
    model.radius = 0.39
    model.height = 1.8
    player_visual.mesh = model
    player_visual.material_override = _mat(Color(0.18,0.67,0.84),0.15)
    player.add_child(player_visual)
    _mesh_box(player,"ArmorPlate",Vector3(0,0.18,-0.24),
        Vector3(0.61,0.58,0.18),Color(0.11,0.24,0.37),0.5)

func _create_camera_and_lie() -> void:
    camera = Camera3D.new()
    camera.name = "PlayerCamera"
    camera.fov = 65.0
    camera.near = 0.1
    camera.far = 100.0
    camera.current = true
    add_child(camera)
    lie_effect = LieCore.new()
    var comp := Compositor.new()
    comp.compositor_effects = [lie_effect]
    world_environment.compositor = comp
    # Explicitly marked fallback when Forward+ Vulkan isn't available.
    core_fallback = MeshInstance3D.new()
    var fallback_mesh := SphereMesh.new()
    fallback_mesh.radius = 0.9
    fallback_mesh.height = 1.8
    core_fallback.mesh = fallback_mesh
    core_fallback.material_override = _mat(Color(0.25,0.43,0.72),1.0,0.2)
    core_fallback.position = CORE_POS
    core_fallback.visible = false
    add_child(core_fallback)

func _create_objectives() -> void:
    for i in range(BEACON_SPOTS.size()):
        var pos: Vector3 = BEACON_SPOTS[i]
        var beacon := Node3D.new()
        beacon.name = "ArchiveModule%d"%i
        beacon.position = pos+Vector3(0,0.95,0)
        add_child(beacon)
        var m := SphereMesh.new()
        m.radius = 0.34
        m.height = 0.68
        var mesh := MeshInstance3D.new()
        mesh.mesh = m
        mesh.material_override = _mat(Color(1.0,0.71,0.19),1.5,0.3)
        beacon.add_child(mesh)
        beacons.append(beacon)
        var lamp := OmniLight3D.new()
        lamp.light_color = Color(1.0,0.52,0.19)
        lamp.light_energy = 0.65
        lamp.omni_range = 2.7
        beacon.add_child(lamp)
    gate = Node3D.new()
    gate.name = "Extraction"
    gate.position = Vector3(0,0,-11)
    add_child(gate)
    for x in [-1.45,1.45]:
        _mesh_box(gate,"GateColumn",Vector3(x,1.4,0),Vector3(0.35,2.8,0.5),Color(0.33,0.55,0.59))
    _mesh_box(gate,"GateTop",Vector3(0,2.9,0),Vector3(3.2,0.35,0.5),Color(0.36,0.58,0.64))
    _mesh_box(gate,"GateSign",Vector3(0,2.35,0),Vector3(1.5,0.23,0.1),Color(0.07,0.66,0.71))

func _create_enemies() -> void:
    for spawn in SPAWNS:
        var drone := Node3D.new()
        drone.name = "Drone"
        drone.position = spawn+Vector3(0,1.3,0)
        add_child(drone)
        var m := SphereMesh.new()
        m.radius = 0.44
        m.height = 0.88
        var mesh := MeshInstance3D.new()
        mesh.mesh = m
        mesh.material_override = _mat(Color(0.91,0.20,0.25),0.7)
        drone.add_child(mesh)
        _mesh_box(drone,"DroneWing",Vector3.ZERO,Vector3(1.35,0.18,0.25),Color(0.32,0.15,0.24))
        enemies.append(drone)
        enemy_hp[drone] = 3

func _create_hud() -> void:
    var ui := CanvasLayer.new()
    ui.name = "HUD"
    add_child(ui)
    var root := Control.new()
    root.name = "Overlay"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    ui.add_child(root)
    health_label = _label(root,Vector2(24,18),26,Color(0.93,0.97,1.0))
    info_label = _label(root,Vector2(24,52),19,Color(0.98,0.78,0.35))
    tech_label = _label(root,Vector2(24,83),15,Color(0.55,0.88,0.96))
    help_label = _label(root,Vector2(24,114),15,Color(0.69,0.78,0.86))
    help_label.text = "WASD mover · ratón derecho cámara · clic izquierdo disparar · Shift dash · R reiniciar"
    var notice := _label(root,Vector2(24,145),13,Color(0.71,0.78,0.84))
    notice.text = "MÓVIL: arrastra izquierda para mover y derecha para mirar."
    var fire_btn := _button(root,"DISPARAR",Vector2(-166,-139),Vector2(148,64))
    fire_btn.button_down.connect(func() -> void: firing = true)
    fire_btn.button_up.connect(func() -> void: firing = false)
    var dash_btn := _button(root,"DASH",Vector2(-325,-122),Vector2(130,52))
    dash_btn.pressed.connect(_dash)
    var restart_btn := _button(root,"REINICIAR",Vector2(-145,12),Vector2(120,42),true)
    restart_btn.pressed.connect(_restart)

func _label(parent: Control, pos: Vector2, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.position = pos
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label

func _button(parent: Control, caption: String, pos: Vector2, size: Vector2,
        top_right: bool = false) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = size
    button.add_theme_font_size_override("font_size",19)
    button.focus_mode = Control.FOCUS_NONE
    if top_right:
        button.anchor_left = 1.0
        button.anchor_right = 1.0
        button.position = pos
    else:
        button.anchor_left = 1.0
        button.anchor_right = 1.0
        button.anchor_top = 1.0
        button.anchor_bottom = 1.0
        button.position = pos
    parent.add_child(button)
    return button

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        yaw = wrapf(yaw-float(event.relative.x)*0.006,-PI,PI)
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            firing = event.pressed
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_SHIFT:
            _dash()
        elif event.keycode == KEY_R:
            _restart()
    elif event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        var half: float = get_viewport().get_visible_rect().size.x/2.0
        if touch.pressed:
            if touch.position.x<half and touch_left==-1:
                touch_left = touch.index
                left_origin = touch.position
                touch_move = Vector2.ZERO
            elif touch.position.x>=half and touch_right==-1:
                touch_right = touch.index
        else:
            if touch.index==touch_left:
                touch_left=-1
                touch_move=Vector2.ZERO
            if touch.index==touch_right:
                touch_right=-1
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == touch_left:
            touch_move = (drag.position-left_origin)/75.0
            touch_move = touch_move.limit_length(1.0)
        elif drag.index == touch_right:
            yaw = wrapf(yaw-drag.relative.x*0.009,-PI,PI)

func _dash() -> void:
    if dash_cooldown<=0.0 and not finished:
        dash_time = 0.23
        dash_cooldown = 1.5

func _restart() -> void:
    get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
    if player == null or finished:
        return
    dash_cooldown = maxf(0,dash_cooldown-delta)
    dash_time = maxf(0,dash_time-delta)
    fire_cooldown = maxf(0,fire_cooldown-delta)
    hit_cooldown = maxf(0,hit_cooldown-delta)
    var input := Vector2.ZERO
    if Input.is_key_pressed(KEY_A):
        input.x -= 1.0
    if Input.is_key_pressed(KEY_D):
        input.x += 1.0
    if Input.is_key_pressed(KEY_W):
        input.y += 1.0
    if Input.is_key_pressed(KEY_S):
        input.y -= 1.0
    input += Vector2(touch_move.x,-touch_move.y)
    input = input.limit_length(1)
    var basis := Basis(Vector3.UP,yaw)
    var forward: Vector3 = -(basis.z)
    var right: Vector3 = basis.x
    var direction: Vector3 = right*input.x + forward*input.y
    var speed: float = DASH_SPEED if dash_time>0.0 else SPEED
    player.velocity.x = direction.x*speed
    player.velocity.z = direction.z*speed
    if player.is_on_floor():
        player.velocity.y = -0.2
    else:
        player.velocity.y -= 24.0*delta
    if player.is_on_floor() and Input.is_key_pressed(KEY_SPACE):
        player.velocity.y = 7.5
    player.move_and_slide()
    if direction.length_squared()>0.01:
        player_visual.rotation.y = atan2(direction.x,direction.z)
    if firing and fire_cooldown<=0.0:
        _shoot()
    _update_enemies(delta)
    _check_pickups()
    _update_camera()

func _process(delta: float) -> void:
    if beacons.size()>0:
        for i in range(beacons.size()):
            if is_instance_valid(beacons[i]):
                beacons[i].rotate_y(delta*1.4)
    if beam!=null:
        beam_time-=delta
        if beam_time<=0:
            beam.queue_free()
            beam=null
    if lie_effect!=null and core_fallback!=null:
        var active: bool=bool(lie_effect.get("gpu_ready"))
        if not active and int(lie_effect.get("frame_count"))==0 and Engine.get_frames_drawn()>90:
            core_fallback.visible=true
        elif active:
            core_fallback.visible=false
    _refresh_hud()

func _update_camera() -> void:
    if camera==null or player==null:
        return
    var basis:=Basis(Vector3.UP,yaw)
    var behind: Vector3=basis.z*7.0
    var ahead: Vector3=-basis.z*2.4
    camera.global_position=player.global_position+behind+Vector3(0,4.2,0)
    camera.look_at(player.global_position+ahead+Vector3(0,1.35,0),Vector3.UP)
    var screen: Vector2=get_viewport().get_visible_rect().size
    lie_effect.call("set_target_camera",camera.global_transform,camera.fov,
        screen.x/maxf(screen.y,1.0))

func _shoot() -> void:
    fire_cooldown=0.24
    var closest: Node3D=null
    var distance:=19.0
    var origin: Vector3=player.global_position+Vector3(0,1.1,0)
    for drone in enemies:
        if not is_instance_valid(drone):
            continue
        var d: float=origin.distance_to(drone.global_position)
        if d<distance:
            closest=drone
            distance=d
    if closest==null:
        return
    enemy_hp[closest]=int(enemy_hp[closest])-1
    if beam!=null:
        beam.queue_free()
    beam=MeshInstance3D.new()
    var sphere:=SphereMesh.new()
    sphere.radius=0.11
    sphere.height=0.22
    beam.mesh=sphere
    beam.material_override=_mat(Color(0.29,0.9,1.0),2.5)
    beam.position=closest.global_position
    add_child(beam)
    beam_time=0.16
    if int(enemy_hp[closest])<=0:
        enemy_hp.erase(closest)
        enemies.erase(closest)
        closest.queue_free()
        kills+=1

func _update_enemies(delta: float) -> void:
    for i in range(enemies.size()):
        var drone: Node3D = enemies[i]
        if not is_instance_valid(drone):
            continue
        var diff: Vector3=player.global_position-drone.global_position
        diff.y=0
        if diff.length()>1.5:
            drone.position+=diff.normalized()*delta*1.25
        drone.position.y=1.4+sin(float(Time.get_ticks_msec())/450.0+float(i))*0.14
        drone.rotate_y(delta*1.9)
        if diff.length()<1.7 and hit_cooldown<=0:
            health=maxi(health-12,0)
            hit_cooldown=1.1
            if health==0:
                finished=true
                won=false

func _check_pickups() -> void:
    for i in range(beacons.size()):
        var beacon: Node3D=beacons[i]
        if is_instance_valid(beacon) and player.global_position.distance_to(beacon.global_position)<1.5:
            beacon.queue_free()
            beacons[i]=null
            collected+=1
    if collected==3 and player.global_position.distance_to(gate.global_position)<2.2:
        finished=true
        won=true

func _refresh_hud() -> void:
    if health_label==null:
        return
    health_label.text="LIE  //  NÚCLEO OMEGA     VIDA %03d"%health
    if finished:
        info_label.text="EXTRACCIÓN COMPLETADA  ·  R para reiniciar" if won else "MISIÓN FALLIDA  ·  R para reiniciar"
    else:
        info_label.text="MÓDULOS %d/3     DRONES %d     SALIDA: PUERTA NORTE" % [collected,enemies.size()]
    tech_label.text="NÚCLEO: LIE GPU / VULKAN" if bool(lie_effect.get("gpu_ready")) else "NÚCLEO: esperando Vulkan (o modo 3D auxiliar)"

func _exit_tree() -> void:
    if lie_effect!=null:
        lie_effect.call("shutdown")
