extends Node3D

@onready var area_3d: Area3D = $Area3D
@onready var module_label: Label = $PatchWindowViewport/Control/Label

# Null texture fix nodes
@onready var mesh_instance: MeshInstance3D = $PatchScreenMesh
@onready var sub_viewport: SubViewport = $PatchWindowViewport

# Type configuration ("osc~", "bng", "inlet", "outlet")
@export var module_type: String = "osc~" : set = set_module_type

# Controller tracking references
var left_controller: XRController3D = null
var right_controller: XRController3D = null

# Grab state variables
var active_grabber: XRController3D = null
var is_grabbed: bool = false
var grab_offset: Transform3D = Transform3D()

# Grid snapping configuration (in meters)
@export var snap_grid_size: float = 0.25

func _ready():
	# --- NULL TEXTURE FIX ---
	var mat = mesh_instance.get_active_material(0)
	if not mat:
		mat = StandardMaterial3D.new()
		mesh_instance.set_material_override(mat)
	mat.albedo_texture = sub_viewport.get_texture()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	# ------------------------

	area_3d.area_entered.connect(_on_area_entered)
	area_3d.area_exited.connect(_on_area_exited)
	
	set_module_type(module_type)

func set_module_type(new_type: String):
	module_type = new_type
	if module_label and is_inside_tree():
		module_label.text = module_type

func _on_area_entered(area: Area3D):
	var parent = area.get_parent()
	if parent is XRController3D:
		if parent.tracker == "left" or "Left" in parent.name:
			left_controller = parent
		elif parent.tracker == "right" or "Right" in parent.name:
			right_controller = parent

func _on_area_exited(area: Area3D):
	var parent = area.get_parent()
	if not is_grabbed:
		var left_hand_area = left_controller.get_node_or_null("HandArea") as Area3D if left_controller else null
		var right_hand_area = right_controller.get_node_or_null("HandArea") as Area3D if right_controller else null
		
		if parent == left_controller and (not left_hand_area or not area_3d.overlaps_area(left_hand_area)):
			left_controller = null
		if parent == right_controller and (not right_hand_area or not area_3d.overlaps_area(right_hand_area)):
			right_controller = null

func _process(delta):
	if is_grabbed:
		if active_grabber:
			var grip_released = not (active_grabber.is_button_pressed("grip_click") or active_grabber.is_button_pressed("trigger_click"))
			if grip_released:
				release_module()
			else:
				global_transform = active_grabber.global_transform * grab_offset
		return

	var left_hand_area = left_controller.get_node_or_null("HandArea") as Area3D if left_controller else null
	var right_hand_area = right_controller.get_node_or_null("HandArea") as Area3D if right_controller else null

	var left_touching = left_controller and left_hand_area and area_3d.overlaps_area(left_hand_area)
	var right_touching = right_controller and right_hand_area and area_3d.overlaps_area(right_hand_area)

	var left_pressed = left_touching and (left_controller.is_button_pressed("grip_click") or left_controller.is_button_pressed("trigger_click"))
	var right_pressed = right_touching and (right_controller.is_button_pressed("grip_click") or right_controller.is_button_pressed("trigger_click"))

	if left_pressed:
		start_grab(left_controller)
	elif right_pressed:
		start_grab(right_controller)

func start_grab(controller: XRController3D):
	is_grabbed = true
	active_grabber = controller
	grab_offset = active_grabber.global_transform.affine_inverse() * global_transform

func release_module():
	is_grabbed = false
	active_grabber = null
	
	var current_pos = global_transform.origin
	current_pos.x = round(current_pos.x / snap_grid_size) * snap_grid_size
	current_pos.y = round(current_pos.y / snap_grid_size) * snap_grid_size
	global_transform.origin = current_pos
