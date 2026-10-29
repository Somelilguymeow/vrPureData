extends RigidBody3D

@onready var patch_window: Node3D = null
var cell_size: float = 0.1 # Size of each grid cell in meters
var is_dragging: bool = false
var drag_controller: Node3D = null
var local_offset: Transform3D

func _ready():
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	# Automatically find the PatchWindow in the scene tree
	var windows = get_tree().get_nodes_in_group("patch_window")
	if windows.size() > 0:
		patch_window = windows[0]
		
	# Ensure the module is grabbable too
	if not is_in_group("grabbable"):
		add_to_group("grabbable")

func _process(_delta):
	if is_dragging and drag_controller:
		# Track controller movement while maintaining local alignment
		var target_global = drag_controller.global_transform * local_offset
		if patch_window:
			var local_pos = patch_window.to_local(target_global.origin)
			# Snap coordinates to the grid step
			local_pos.x = round(local_pos.x / cell_size) * cell_size
			local_pos.y = round(local_pos.y / cell_size) * cell_size
			local_pos.z = 0.02 # Rest slightly above the patch window surface
			global_position = patch_window.to_global(local_pos)
		else:
			global_position = target_global.origin

func grab(controller: Node3D):
	is_dragging = true
	drag_controller = controller
	local_offset = controller.global_transform.inverse() * global_transform
	freeze = true

func release():
	is_dragging = false
	drag_controller = null
	freeze = false
	snap_to_grid()

func snap_to_grid():
	if not patch_window: return
	var local_pos = patch_window.to_local(global_position)
	local_pos.x = round(local_pos.x / cell_size) * cell_size
	local_pos.y = round(local_pos.y / cell_size) * cell_size
	local_pos.z = 0.02
	global_position = patch_window.to_global(local_pos)
