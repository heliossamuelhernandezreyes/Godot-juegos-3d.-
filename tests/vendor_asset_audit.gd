extends SceneTree

const SCENES = [
 "res://assets/vendor/polyhaven/barrel_03/barrel_03_1k.gltf",
 "res://assets/vendor/polyhaven/industrial_wall_lamp/industrial_wall_lamp_1k.gltf",
]
func _initialize() -> void:
 call_deferred("_check")

func _check() -> void:
 for path in SCENES:
  var scene: PackedScene = load(path)
  if scene == null:
   printerr("VENDOR IMPORT FAIL: ",path)
   quit(1)
   return
  var obj := scene.instantiate()
  root.add_child(obj)
  var meshes := _walk(obj)
  if meshes.is_empty():
   printerr("VENDOR IMPORT FAIL: no meshes in ",path)
   quit(1)
   return
  for mesh in meshes:
   print("VENDOR MESH",path,"name=",mesh.name,"bounds=",mesh.get_aabb(),"surfaces=",mesh.mesh.get_surface_count())
  print("VENDOR MODEL PASS",path,"mesh_count=",meshes.size())
  obj.queue_free()
 print("VENDOR IMPORT PASS count=",SCENES.size())
 quit(0)

func _walk(node: Node) -> Array[MeshInstance3D]:
 var found: Array[MeshInstance3D] = []
 if node is MeshInstance3D:
  found.append(node)
 for child in node.get_children():
  found.append_array(_walk(child))
 return found
