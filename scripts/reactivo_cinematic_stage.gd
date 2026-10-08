extends Node3D
## FISURA 0.8: dedicated modular-industrial art for 84x66 Reactivo-13.
## Game collision geometry and anchor navigation remain in the map/mission scripts.
## Uses source-traced CC0 Poly Haven PBR from ARCONT-approved game vault.
const PILLAR = preload("res://assets/models/sentinel_pillar.obj")
const CRATE = preload("res://assets/models/armored_crate.obj")
const REACTOR = preload("res://assets/models/reactor_altar.obj")
const PORTAL = preload("res://assets/models/extraction_gate.obj")
const POLY_BARREL = preload("res://assets/vendor/polyhaven/barrel_03/barrel_03_1k.gltf")
const POLY_LAMP = preload("res://assets/vendor/polyhaven/industrial_wall_lamp/industrial_wall_lamp_1k.gltf")
const POLY_CART = preload("res://assets/vendor/polyhaven_cinematic/industrial_storage_cart/industrial_storage_cart_1k.gltf")
const POLY_CONTAINER = preload("res://assets/vendor/polyhaven_cinematic/industrial_pastic_container/industrial_pastic_container_1k.gltf")

var environment_parts := 0
var unique_lights := 0
var instanced_tiles := 0
var reactor_light: OmniLight3D
var alarm_lights: Array[OmniLight3D] = []
var is_alarm := false
var active_time := 0.0
var metal: Material
var concrete: Material
var floor_mat: Material
var dark: Material
var brass: Material
var cyan: Material
var amber: Material
var danger: Material

func build(map_data: Dictionary, anchors: Dictionary) -> void:
    name = "REACTIVO 13 | industrial environment art LOD budget"
    metal = _pbr("green_metal_rust", Color("#a5aeb1"), 0.21)
    concrete = _pbr("concrete_wall_007", Color("#a5adb1"), 0.26)
    floor_mat = _pbr("concrete_floor_worn_02", Color("#9da6a9"), 0.35)
    dark = _mat(Color("#253743"), 0.78, 0.37)
    brass = _mat(Color("#9d7749"), 0.76, 0.32)
    cyan = _emission(Color("#45d3e9"), 2.3)
    amber = _emission(Color("#ee8e48"), 2.4)
    danger = _emission(Color("#d94532"), 3.1)
    _floor(map_data)
    _perimeter(float(map_data["bounds"]["width"]), float(map_data["bounds"]["depth"]))
    _halls()
    _walkway_overheads()
    _coolant_system()
    _reactor(anchors["reactor_altar"])
    _dock(anchors["extraction_pad"])
    _consoles(anchors)
    _covers(map_data)
    _authored_props(map_data)
    _vendor_props()
    _lights()
    print("REACTIVO ART PASS nodes=%d tiles=%d omnies=%d" % [environment_parts,instanced_tiles,unique_lights])

func _process(delta: float) -> void:
    active_time += delta
    if reactor_light != null:
        reactor_light.light_energy = (1.1 + 0.35 * sin(active_time * (3.5 if is_alarm else 1.1)))
    if is_alarm:
        for light in alarm_lights:
            light.light_energy = 0.8 + 0.65 * maxf(0.0, sin(active_time * 5.0))

func set_alarm(active: bool) -> void:
    is_alarm = active

func _pbr(slug: String, tint: Color, tile_size: float) -> ORMMaterial3D:
    var p := "res://assets/vendor/polyhaven_materials/" + slug + "/"
    var result := ORMMaterial3D.new()
    result.albedo_color = tint
    result.albedo_texture = load(p + "diff.jpg") as Texture2D
    result.orm_texture = load(p + "arm.jpg") as Texture2D
    result.normal_enabled = true
    result.normal_texture = load(p + "nor_gl.jpg") as Texture2D
    result.uv1_triplanar = true
    result.uv1_scale = Vector3.ONE * tile_size
    return result

func _mat(tint: Color, metal_factor: float, roughness: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = tint
    m.metallic = metal_factor
    m.roughness = roughness
    return m

func _emission(tint: Color, energy: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = tint
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.emission_enabled = true
    m.emission = tint
    m.emission_energy_multiplier = energy
    return m

func _beam(label: String, pos: Vector3, size: Vector3, mat: Material, cast_shadow: bool = false) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.position = pos
    item.material_override = mat
    if not cast_shadow:
        item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(item)
    environment_parts += 1
    return item

func _tube(label: String, a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
    var direction: Vector3 = b - a
    if direction.length() < 0.1:
        return
    var piece := MeshInstance3D.new()
    piece.name = label
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = direction.length()
    cylinder.radial_segments = 10
    piece.mesh = cylinder
    piece.material_override = mat
    piece.position = (a+b) * 0.5
    piece.quaternion = Quaternion(Vector3.UP, direction.normalized())
    piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(piece)
    environment_parts += 1

func _floor(map_data: Dictionary) -> void:
    var width: float = float(map_data["bounds"]["width"])
    var depth: float = float(map_data["bounds"]["depth"])
    var mesh := BoxMesh.new()
    mesh.size = Vector3(4.0,0.055,4.0)
    var floor_multi := MultiMesh.new()
    floor_multi.transform_format = MultiMesh.TRANSFORM_3D
    floor_multi.mesh = mesh
    var count_x := int(width/4.0)
    var count_z := int(depth/4.0)
    floor_multi.instance_count = count_x*count_z
    var at := 0
    for ix in range(count_x):
        for iz in range(count_z):
            floor_multi.set_instance_transform(at,Transform3D(Basis.IDENTITY,Vector3(-width*0.5+2+float(ix)*4,0.025,-depth*0.5+2+float(iz)*4)))
            at+=1
    var instance := MultiMeshInstance3D.new()
    instance.name = "Industrial ground | PBR floor instanced"
    instance.multimesh = floor_multi
    instance.material_override = floor_mat
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(instance)
    environment_parts+=1
    instanced_tiles=at
    # Directional lane language; footpaths visibly lead to usable objective areas.
    _beam("Main service spine | steel",Vector3(0,0.086,3),Vector3(5.4,0.07,55),dark)
    for side in [-1.0,1.0]:
        _beam("Spine yellow hazard inlay",Vector3(side*2.62,0.13,3),Vector3(0.13,0.035,55),brass)
        for zz in range(-29,30,4):
            _beam("Route bracket",Vector3(side*3.1,0.13,float(zz)),Vector3(0.52,0.03,0.13),amber)
    _beam("Left process lane",Vector3(-26,0.09,3),Vector3(6,0.055,28),dark)
    _beam("Right process lane",Vector3(26,0.09,3),Vector3(6,0.055,28),dark)

func _perimeter(width: float, depth: float) -> void:
    var x0 := width/2.0-0.95
    var z0 := depth/2.0-0.95
    # Actual map shell is game-owned. These are visual facade panels on the inner wall.
    for x in range(-40,41,4):
        for z_edge in [-z0,z0]:
            _beam("High wall | rib", Vector3(float(x),4.1,z_edge),Vector3(0.24,6.1,0.62),metal)
            _beam("High wall | lower plinth",Vector3(float(x),0.6,z_edge),Vector3(3.8,1.0,0.18),concrete)
            _beam("High wall | strip",Vector3(float(x),5.8,z_edge*0.994),Vector3(3.5,0.11,0.11),cyan if x%12==0 else brass)
    for z in range(-30,31,4):
        for x_edge in [-x0,x0]:
            _beam("Side wall | rib",Vector3(x_edge,4.1,float(z)),Vector3(0.62,6.1,0.24),metal)
            _beam("Side wall | panel",Vector3(x_edge,2.2,float(z)),Vector3(0.24,3.8,3.7),concrete)
    for side in [-1.0,1.0]:
        _beam("West-east upper rail",Vector3(0,6.95,side*z0),Vector3(width-1.7,0.46,0.55),dark)
        _beam("North-south upper rail",Vector3(side*x0,6.95,0),Vector3(0.55,0.46,depth-1.7),dark)

func _halls() -> void:
    # 2 symmetrical machinery banks keep a readable road through both mission nodes.
    for side in [-1.0,1.0]:
        var cx: float = 27.0 * float(side)
        for zz in [-11.0,15.0]:
            _beam("Cryo processor plinth",Vector3(cx,0.50,zz),Vector3(6.0,1,3.0),dark)
            _beam("Cryo processor vessel",Vector3(cx,2.55,zz),Vector3(4.5,3.15,2.45),metal)
            _beam("Cryo processor header",Vector3(cx,4.12,zz),Vector3(5.2,0.4,2.85),brass)
            _beam("Coolant viewport",Vector3(cx,2.65,zz+1.27),Vector3(2.7,1.7,0.07),cyan)
            for n in [-1.0,1.0]:
                _tube("Cooled steam riser",Vector3(cx+n*2.2,4.15,zz),Vector3(cx+n*2.2,9.3,zz),0.15,metal)
        _tube("Long return pipe",Vector3(side*36.7,8.75,-25),Vector3(side*36.7,8.75,24),0.39,metal)
        _tube("Long copper pipe",Vector3(side*37.8,7.7,-25),Vector3(side*37.8,7.7,24),0.25,brass)
        _sign("ENERGY " + ("A" if side<0 else "B"),Vector3(side*28.0,5.5,6.8),Color("#61e0f2") if side<0 else Color("#eda45a"))
    for z in [-22.0,5.0,23.0]:
        _beam("Bulkhead lintel",Vector3(0,8.65,z),Vector3(42,0.65,1.7),dark)
        for side in [-1.0,1.0]:
            _beam("Bulkhead structural post",Vector3(side*20.7,4.6,z),Vector3(1.2,8.7,1.7),metal)
            _beam("Post signal",Vector3(side*20.7,4.3,z+0.91),Vector3(0.17,2.5,0.09),amber)

func _walkway_overheads() -> void:
    # Decoration is above combat camera; no walkable surfaces or invisible colliders.
    for side in [-1.0,1.0]:
        var x: float = float(side) * 19.6
        for z in range(-28,29,8):
            _beam("Catwalk overhead rail",Vector3(x,10.5,float(z)),Vector3(2.3,0.25,7.5),dark)
            _beam("Catwalk safety rail",Vector3(x+side*1.15,11.2,float(z)),Vector3(0.14,1.3,7.2),brass)
        for z in [-28.0,0.0,28.0]:
            _tube("Cable tower suspension",Vector3(x,11.2,z),Vector3(x,14.5,z),0.085,metal)
    for z in [-30.0,0.0,30.0]:
        _beam("Ceiling air truss",Vector3(0,14.9,z),Vector3(68,0.35,1.1),metal)

func _coolant_system() -> void:
    # Thick coolant conduits frame the reactor without obscuring the approach camera.
    for side in [-1.0,1.0]:
        for zz in [-17.0,-5.0]:
            _tube("Reactor coolant inlet",Vector3(side*11.0,0.6,zz),Vector3(side*11.0,6.9,zz),0.34,brass)
            _tube("Reactor coolant manifold",Vector3(side*11.0,6.9,zz),Vector3(side*5.2,6.9,zz),0.28,metal)
        _tube("Reactor high tube",Vector3(side*11.0,8.4,-22),Vector3(side*11.0,8.4,0),0.40,metal)

func _reactor(at: Vector3) -> void:
    var center := Vector3(at.x,2.5,at.z)
    for ring in range(3):
        var radius := 3.3+float(ring)*1.3
        var height := 3.1+float(ring)*2.1
        for n in range(16):
            var angle1 := float(n)*TAU/16.0
            var angle2 := float(n+1)*TAU/16.0
            var a := center + Vector3(cos(angle1)*radius,height-2.5,sin(angle1)*radius)
            var b := center + Vector3(cos(angle2)*radius,height-2.5,sin(angle2)*radius)
            _tube("Reactor containment ring",a,b,0.14,brass if ring==1 else metal)
    var vessel := MeshInstance3D.new()
    vessel.name = "Reactivo 13 | active core globe"
    var orb := SphereMesh.new()
    orb.radius = 1.72
    orb.height = 3.44
    orb.radial_segments = 24
    orb.rings = 12
    vessel.mesh = orb
    vessel.material_override = amber
    vessel.position = center
    add_child(vessel)
    environment_parts+=1
    for side in [-1.0,1.0]:
        _beam("Reactor containment stabilizer",center+Vector3(side*5.0,0,0),Vector3(0.65,7.5,0.65),metal)
        _beam("Reactor containment light",center+Vector3(side*5.0,1.2,0),Vector3(0.13,2.0,0.68),amber)
    _sign("R-13  //  CONTAINMENT",center+Vector3(0,6.4,0),Color("#ffc079"))

func _dock(at: Vector3) -> void:
    # Extraction silhouette deliberately simple but readable at 720p.
    for side in [-1.0,1.0]:
        _beam("Extraction tall gate pillar",at+Vector3(side*4.1,4.25,0),Vector3(1.0,8.5,1.2),metal)
        _beam("Extraction cian left-right",at+Vector3(side*4.1,4.5,0.65),Vector3(0.20,7.6,0.11),cyan)
    _beam("Extraction upper lintel",at+Vector3(0,8.5,0),Vector3(9.1,0.95,1.4),dark)
    _beam("Extraction active signal",at+Vector3(0,8.5,0.76),Vector3(7.8,0.14,0.12),cyan)
    _sign("EVAC  //  GATE 13",at+Vector3(0,9.8,0),Color("#5cf0df"))
    _beam("Extraction vehicle landing pad",at+Vector3(0,0.10,2),Vector3(13,0.08,7),dark)
    _beam("Extraction landing strip",at+Vector3(0,0.16,2),Vector3(0.15,0.05,6),cyan)

func _consoles(anchors: Dictionary) -> void:
    for key in ["node_a_console","node_b_console","stabilizer"]:
        var at: Vector3 = anchors[key]
        var signal_mat: Material = cyan if key=="node_a_console" else amber
        _beam("Mission console 3D base " + key,at+Vector3(0,0.6,0.9),Vector3(2.2,1.2,1.15),metal)
        var console := _beam("Mission terminal display " + key,at+Vector3(0,1.75,0.9),Vector3(1.7,1.13,0.22),signal_mat)
        console.rotation.x = -0.24
        _sign(key.to_upper().replace("_"," "),at+Vector3(0,3.6,0.8),Color("#75eafb"))

func _covers(world: Dictionary) -> void:
    for guide in world.get("authoring",{}).get("structure_guides",[]):
        if str(guide.get("kind",""))!="cover":
            continue
        var where: Array = guide["position"]
        var width: Array = guide["size"]
        var p := Vector3(float(where[0]),float(where[1]),float(where[2]))
        var scale := Vector3(float(width[0]),float(width[1]),float(width[2]))
        # Visual armor plate in same geometry volume as canonical cover collider.
        _beam("Cover front PBR armor",p+Vector3(0,0,scale.z*0.5+0.035),Vector3(scale.x+0.08,scale.y*0.8,0.08),metal)
        _beam("Cover rib upper",p+Vector3(0,scale.y*0.5+0.06,0),Vector3(scale.x+0.18,0.16,scale.z+0.1),brass)
        for side in [-1.0,1.0]:
            _beam("Cover corner flange",p+Vector3(side*(scale.x*0.5+0.05),0,0),Vector3(0.12,scale.y,scale.z+0.1),dark)
        _beam("Cover warning stripe",p+Vector3(0,-scale.y*0.25,scale.z*0.5+0.09),Vector3(scale.x*0.8,0.10,0.04),amber)

func _authored_props(world: Dictionary) -> void:
    var lookup := {"pillar":PILLAR,"crate":CRATE,"reactor":REACTOR}
    for prop in world.get("authoring",{}).get("world_props",[]):
        var kind: String = str(prop.get("kind",""))
        if not lookup.has(kind):
            continue
        var pos: Array = prop["position"]
        var dims: Array = prop["collider_size"]
        var body := StaticBody3D.new()
        body.name = str(prop["id"])+" | gameplay collider"
        body.position = Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
        add_child(body)
        var collider := CollisionShape3D.new()
        var geometry := BoxShape3D.new()
        geometry.size = Vector3(float(dims[0]),float(dims[1]),float(dims[2]))
        collider.shape=geometry
        collider.position.y=geometry.size.y*0.5
        body.add_child(collider)
        var visual := MeshInstance3D.new()
        visual.mesh=lookup[kind]
        visual.name="Source-vetted authored mesh | "+kind
        body.add_child(visual)
        environment_parts+=1

func _vendor_props() -> void:
    # Two actual Poly Haven photogrammetric 3D meshes, not procedural cube substitutes.
    for point in [Vector3(-32,0,-19),Vector3(32,0,19)]:
        var item := POLY_CART.instantiate()
        item.name = "Poly Haven CC0 PBR storage cart | 1K"
        item.position = point
        item.rotation.y = 1.57
        add_child(item)
        environment_parts += 1
    for point in [Vector3(-33,0,18),Vector3(33,0,-17),Vector3(-23,0,-23),Vector3(23,0,22)]:
        var item := POLY_CONTAINER.instantiate()
        item.name = "Poly Haven CC0 industrial container | 1K"
        item.position = point
        add_child(item)
        environment_parts += 1
    for point in [Vector3(-16,0,18),Vector3(17,0,16),Vector3(-19,0,-16),Vector3(19,0,-14)]:
        var item := POLY_BARREL.instantiate()
        item.name="Poly Haven CC0 oil barrel PBR"
        item.position=point
        add_child(item)
        environment_parts+=1
    for side in [-1.0,1.0]:
        for z in [-21.0,0.0,20.0]:
            var item := POLY_LAMP.instantiate()
            item.name="Poly Haven CC0 industrial lamp"
            item.position=Vector3(side*40.0,3.4,z)
            item.rotation.y=PI*0.5 if side<0 else -PI*0.5
            item.scale=Vector3.ONE*2.2
            add_child(item)
            environment_parts+=1

func _light(label: String, pos: Vector3, color: Color, strength: float, reach: float) -> OmniLight3D:
    var point := OmniLight3D.new()
    point.name=label
    point.position=pos
    point.light_color=color
    point.light_energy=strength
    point.omni_range=reach
    point.shadow_enabled=false
    add_child(point)
    unique_lights+=1
    return point

func _lights() -> void:
    _light("Hero cyan entry light",Vector3(0,7.8,19),Color("#b6e2f6"),1.6,19)
    _light("Node A cyan pool",Vector3(-28,7,4),Color("#34c6fa"),1.5,18)
    _light("Node B golden pool",Vector3(28,7,4),Color("#ef994f"),1.5,18)
    reactor_light=_light("Reactivo warm core",Vector3(0,6,-11),Color("#ff964c"),1.3,19)
    _light("Extraction teal guidance",Vector3(0,7,-28),Color("#54d9ca"),1.4,18)
    for side in [-1.0,1.0]:
        alarm_lights.append(_light("Emergency warning",Vector3(side*14,8,-18),Color("#fa4237"),0.0,12))

func _sign(label: String, at: Vector3, tone: Color) -> void:
    var t := Label3D.new()
    t.name="Diegetic mission signage"
    t.text=label
    t.font_size=60
    t.pixel_size=0.003
    t.modulate=tone
    t.outline_modulate=Color("#0d1820")
    t.outline_size=8
    t.position=at
    add_child(t)
    environment_parts+=1
