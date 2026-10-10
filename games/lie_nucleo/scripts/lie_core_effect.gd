extends CompositorEffect
## LIE: Núcleo Omega prototype. Based on the audited LIE-08 viewport path.
## Static four-direction spherical capture is reconstructed via real Vulkan
## computation at each game-camera pose; Godot keeps physics and other meshes.
## Native depth compositing is borrowed from LIE-09 to handle foreground cover.

const REPROJECTION_SHADER: RDShaderFile = preload("res://shaders/lie_projection.glsl")
const COMPOSITE_SHADER: RDShaderFile = preload("res://shaders/lie_depth_composite.glsl")

const TEXTURE_SIZE := 256
const SOURCE_SIZE := 64
const VIEWS := 4
const SAMPLE_COUNT := VIEWS * SOURCE_SIZE * SOURCE_SIZE

var _rd: RenderingDevice
var _reprojection_shader: RID
var _reprojection_pipeline: RID
var _composite_shader: RID
var _composite_pipeline: RID
var _pipeline_set: RID
var _output_texture: RID
var _buffers: Array[RID] = []
var _samples := PackedFloat32Array()
var _colors := PackedFloat32Array()
var _attributes := PackedFloat32Array()
var _mutex := Mutex.new()
var _camera_revision := 0
var _applied_camera_revision := -1
var _pending_camera_bytes := PackedByteArray()
var _sampler: RID
var gpu_ready := false
var frame_count := 0

func _init() -> void:
    effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
    access_resolved_color = true
    access_resolved_depth = true
    _make_procedural_capture()

func set_target_camera(transform: Transform3D, fov_deg: float, aspect: float) -> void:
    # Called on main thread. Copy only immutable bytes into the render thread.
    var data: PackedByteArray = _camera_data(transform, fov_deg, aspect).to_byte_array()
    _mutex.lock()
    _pending_camera_bytes = data
    _camera_revision += 1
    _mutex.unlock()

func _make_procedural_capture() -> void:
    for view in range(VIEWS):
        var yaw: float = TAU * float(view) / float(VIEWS)
        var right := Vector3(cos(yaw),0.0,-sin(yaw))
        var facing := Vector3(sin(yaw),0.0,cos(yaw))
        for py in range(SOURCE_SIZE):
            for px in range(SOURCE_SIZE):
                var u: float = (float(px)+0.5)/float(SOURCE_SIZE)
                var v: float = (float(py)+0.5)/float(SOURCE_SIZE)
                var x: float = (u-0.5)*2.0
                var y: float = (0.5-v)*2.0
                var rr: float = x*x+y*y
                if rr > 0.9*0.9:
                    _samples.append_array(PackedFloat32Array([u,v,0.0,0.0]))
                    _colors.append_array(PackedFloat32Array([0,0,0,0]))
                    _attributes.append_array(PackedFloat32Array([view,0,0,0]))
                    continue
                var bulge: float = sqrt(0.9*0.9-rr)
                var z: float = 3.0-bulge
                var norm := (right*x + Vector3.UP*y + facing*bulge).normalized()
                var stripes: float = 0.08 if int(floor((x+y)*8.0))%2 == 0 else 0.0
                var red: float = clampf(0.18 + 0.28*(norm.y+1.0)*0.5 + stripes,0.0,1.0)
                var green: float = clampf(0.28+0.4*absf(norm.x),0.0,1.0)
                var blue: float = clampf(0.60+0.3*maxf(norm.z,0.0),0.0,1.0)
                _samples.append_array(PackedFloat32Array([u,v,(z-1.5)/3.0,1.0]))
                _colors.append_array(PackedFloat32Array([red,green,blue,1.0]))
                _attributes.append_array(PackedFloat32Array([float(view),1.0,1.0,0.0]))

func _camera_data(transform: Transform3D, fov_deg: float, aspect: float) -> PackedFloat32Array:
    var data := PackedFloat32Array()
    var eye: Vector3 = transform.origin
    var target_right: Vector3 = transform.basis.x.normalized()
    var target_up: Vector3 = transform.basis.y.normalized()
    var target_forward: Vector3 = -transform.basis.z.normalized()
    for view in range(VIEWS):
        var yaw: float = TAU*float(view)/float(VIEWS)
        var facing := Vector3(sin(yaw),0.0,cos(yaw))
        var right := Vector3(cos(yaw),0.0,-sin(yaw))
        var origin: Vector3 = Vector3(0,1.65,0)+facing*3.0
        data.append_array(PackedFloat32Array([
            origin.x,origin.y,origin.z,0,
            right.x,right.y,right.z,0,
            0,1,0,0,
            -facing.x,-facing.y,-facing.z,0,
            eye.x,eye.y,eye.z,0,
            target_right.x,target_right.y,target_right.z,0,
            target_up.x,target_up.y,target_up.z,0,
            target_forward.x,target_forward.y,target_forward.z,0,
            2.0,1.5,4.5,0,
            tan(deg_to_rad(fov_deg)*0.5),maxf(aspect,0.1),0.1,100.0
        ]))
    return data

func _storage_buffer(data: PackedByteArray) -> RID:
    return _rd.storage_buffer_create(data.size(),data)

func _make_storage_uniform(binding: int, id: RID) -> RDUniform:
    var u := RDUniform.new()
    u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
    u.binding = binding
    u.add_id(id)
    return u

func _make_image_uniform(binding: int, id: RID) -> RDUniform:
    var u := RDUniform.new()
    u.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
    u.binding = binding
    u.add_id(id)
    return u

func _initialize_gpu() -> bool:
    _rd = RenderingServer.get_rendering_device()
    if _rd == null:
        push_error("LIE-08 requires RenderingDevice renderer (Vulkan)")
        return false
    var proj_spirv := REPROJECTION_SHADER.get_spirv()
    var composite_spirv := COMPOSITE_SHADER.get_spirv()
    var proj_error: String = proj_spirv.get_stage_compile_error(RenderingDevice.SHADER_STAGE_COMPUTE)
    var composite_error: String = composite_spirv.get_stage_compile_error(RenderingDevice.SHADER_STAGE_COMPUTE)
    if proj_error != "" or composite_error != "":
        push_error("LIE-08 shader errors: "+proj_error+" / "+composite_error)
        return false
    _reprojection_shader = _rd.shader_create_from_spirv(proj_spirv)
    _composite_shader = _rd.shader_create_from_spirv(composite_spirv)
    if not _reprojection_shader.is_valid() or not _composite_shader.is_valid():
        push_error("LIE-08 shader RID invalid")
        return false
    _reprojection_pipeline = _rd.compute_pipeline_create(_reprojection_shader)
    _composite_pipeline = _rd.compute_pipeline_create(_composite_shader)
    if not _reprojection_pipeline.is_valid() or not _composite_pipeline.is_valid():
        push_error("LIE-08 pipeline creation failed")
        return false

    var zeros := PackedFloat32Array()
    zeros.resize(SAMPLE_COUNT*4)
    var depth := PackedInt32Array()
    depth.resize(TEXTURE_SIZE*TEXTURE_SIZE)
    var accum := PackedInt32Array()
    accum.resize(TEXTURE_SIZE*TEXTURE_SIZE*4)
    _buffers = [
        _storage_buffer(_samples.to_byte_array()),
        _storage_buffer(_colors.to_byte_array()),
        _storage_buffer(_attributes.to_byte_array()),
        _storage_buffer(_camera_data(Transform3D(Basis.IDENTITY,Vector3(0,3,8)),60.0,16.0/9.0).to_byte_array()),
        _storage_buffer(zeros.to_byte_array()),
        _storage_buffer(depth.to_byte_array()),
        _storage_buffer(accum.to_byte_array()),
        _storage_buffer(PackedInt32Array([TEXTURE_SIZE,TEXTURE_SIZE,2,0]).to_byte_array())
    ]
    for item in _buffers:
        if not item.is_valid():
            push_error("LIE-08 GPU input buffer invalid")
            return false
    var format := RDTextureFormat.new()
    format.width = TEXTURE_SIZE
    format.height = TEXTURE_SIZE
    format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
    format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
    _output_texture = _rd.texture_create(format,RDTextureView.new(),[])
    if not _output_texture.is_valid():
        push_error("LIE-08 RGBA32F texture allocation failed")
        return false
    var uniforms: Array[RDUniform] = []
    for binding in range(_buffers.size()):
        uniforms.append(_make_storage_uniform(binding,_buffers[binding]))
    uniforms.append(_make_image_uniform(8,_output_texture))
    var filter := RDSamplerState.new()
    filter.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
    filter.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
    _sampler = _rd.sampler_create(filter)
    if not _sampler.is_valid():
        push_error("Lie GPU native depth sampler invalid")
        return false
    _pipeline_set = _rd.uniform_set_create(uniforms,_reprojection_shader,0)
    gpu_ready = _pipeline_set.is_valid()
    if not gpu_ready:
        push_error("LIE-08 GPU uniform set creation failed")
    return gpu_ready

func _render_callback(kind: int, render_data: RenderData) -> void:
    if kind != EFFECT_CALLBACK_TYPE_POST_TRANSPARENT:
        return
    var scene_buffers: RenderSceneBuffersRD = render_data.get_render_scene_buffers()
    if scene_buffers == null:
        return
    var raster_size: Vector2i = scene_buffers.get_internal_size()
    if raster_size.x <= 0 or raster_size.y <= 0:
        return
    if not gpu_ready and not _initialize_gpu():
        return

    _mutex.lock()
    var revision: int = _camera_revision
    var camera_bytes: PackedByteArray = _pending_camera_bytes.duplicate()
    _mutex.unlock()
    if revision != _applied_camera_revision and camera_bytes.size()>0:
        _rd.buffer_update(_buffers[3],0,camera_bytes.size(),camera_bytes)
        _applied_camera_revision = revision

    var commands: int = _rd.compute_list_begin()
    _rd.compute_list_bind_compute_pipeline(commands,_reprojection_pipeline)
    _rd.compute_list_bind_uniform_set(commands,_pipeline_set,0)
    for phase in range(5):
        var push := PackedInt32Array([phase]).to_byte_array()
        _rd.compute_list_set_push_constant(commands,push,push.size())
        var threads: int = TEXTURE_SIZE*TEXTURE_SIZE if phase == 0 or phase == 4 else SAMPLE_COUNT
        _rd.compute_list_dispatch(commands,int(ceil(float(threads)/64.0)),1,1)
        _rd.compute_list_add_barrier(commands)

    _rd.compute_list_bind_compute_pipeline(commands,_composite_pipeline)
    var scene_data: RenderSceneData = render_data.get_render_scene_data()
    if scene_data == null:
        _rd.compute_list_end()
        return
    for view in range(scene_buffers.get_view_count()):
        var framebuffer: RID = scene_buffers.get_color_layer(view)
        var native_depth: RID = scene_buffers.get_depth_layer(view)
        if not framebuffer.is_valid() or not native_depth.is_valid():
            continue
        var depth_uniform := RDUniform.new()
        depth_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
        depth_uniform.binding = 2
        depth_uniform.add_id(_sampler)
        depth_uniform.add_id(native_depth)
        var screen_set: RID = UniformSetCacheRD.get_cache(_composite_shader,0,[
            _make_image_uniform(0,framebuffer),
            _make_image_uniform(1,_output_texture),
            depth_uniform,
            _make_storage_uniform(3,_buffers[5])
        ])
        _rd.compute_list_bind_uniform_set(commands,screen_set,0)
        var proj: Projection = scene_data.get_view_projection(view)
        var params := PackedInt32Array([raster_size.x,raster_size.y,TEXTURE_SIZE,TEXTURE_SIZE]).to_byte_array()
        params.append_array(PackedFloat32Array([proj[2].z,proj[3].z,proj[2].w,proj[3].w]).to_byte_array())
        _rd.compute_list_set_push_constant(commands,params,params.size())
        _rd.compute_list_dispatch(commands,
            int(ceil(float(raster_size.x)/8.0)),
            int(ceil(float(raster_size.y)/8.0)),1)
    _rd.compute_list_end()
    frame_count += 1

func shutdown() -> void:
    # Call while a strong reference to this effect still exists, not from
    # NOTIFICATION_PREDELETE: Godot invalidates 'self' during destruction.
    enabled = false
    if _rd != null:
        RenderingServer.call_on_render_thread(Callable(self,"_release_gpu"))

func _release_gpu() -> void:
    if _rd == null:
        return
    if _pipeline_set.is_valid():
        _rd.free_rid(_pipeline_set)
    if _output_texture.is_valid():
        _rd.free_rid(_output_texture)
    for rid in _buffers:
        if rid.is_valid():
            _rd.free_rid(rid)
    for rid in [_reprojection_pipeline,_composite_pipeline,_reprojection_shader,_composite_shader]:
        if rid.is_valid():
            _rd.free_rid(rid)
    if _sampler.is_valid():
        _rd.free_rid(_sampler)
    _buffers.clear()
    gpu_ready = false
