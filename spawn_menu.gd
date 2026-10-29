extends Node3D

# Reference to the main PatchWindow canvas workspace
@export var target_patch_window: Node3D 

# Object types you can summon onto the canvas
var module_types = ["osc~", "saw~", "bng", "inlet", "outlet", "pd"]

var button_spacing: float = 0.18
var button_size: Vector3 = Vector3(0.15, 0.1, 0.04)

func _ready():
	generate_menu_buttons()

func generate_menu_buttons():
	for i in range(module_types.size()):
		var mod_type = module_types[i]
		
		var item_root = Node3D.new()
		item_root.name = "Button_" + mod_type
		item_root.transform.origin = Vector3((i - (module_types.size() - 1) / 2.0) * button_spacing, 0, 0)
		add_child(item_root)
		
		var area = Area3D.new()
		area.name = "TouchArea"
		var col_shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = button_size
		col_shape.shape = box
		area.add_child(col_shape)
		item_root.add_child(area)
		
		var mesh_instance = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = button_size
		mesh_instance.mesh = box_mesh
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.6, 0.9)
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mesh_instance.set_material_override(mat)
		item_root.add_child(mesh_instance)
		
		area.area_entered.connect(_on_spawn_button_touched.bind(mod_type))

func _on_spawn_button_touched(area: Area3D, type_name: String):
	if area.get_parent() is XRController3D or "HandArea" in area.name:
		spawn_object_into_patch(type_name)

func spawn_object_into_patch(type_name: String):
	if not target_patch_window:
		print("Error: No target PatchWindow assigned to spawner!")
		return
		
	# Create a sub-object node (we can use a basic Node3D or instantiate a child object template)
	var new_object = Node3D.new()
	new_object.name = type_name + "_object"
	
	# Add it directly to the PatchWindow canvas workspace
	target_patch_window.add_child(new_object)
	
	# Position it at the center of the patch window (or offset slightly)
	new_object.transform.origin = Vector3(0, 0, 0.02)
	print("Summoned object into patch: ", type_name)
