extends XRController3D

var held_object: Node3D = null
const GRAB_DISTANCE = 0.5 # Maximum distance in meters to grab modules

func _ready():
	# Connect to controller button signals for spawning and grabbing
	button_pressed.connect(_on_button_pressed)
	button_released.connect(_on_button_released)

func _process(_delta):
	var is_gripping = is_button_pressed("grip")
	
	if is_gripping:
		if not held_object:
			# Find any grabbable module within range of this hand
			var grabbables = get_tree().get_nodes_in_group("grabbable")
			for obj in grabbables:
				# Don't grab the patch window itself, just modules
				if obj == self or obj.name == "PatchWindow":
					continue
				if global_position.distance_to(obj.global_position) < GRAB_DISTANCE:
					held_object = obj
					if held_object.has_method("grab"):
						held_object.grab(self)
					break
	else:
		if held_object:
			if held_object.has_method("release"):
				held_object.release()
			held_object = null

func _on_button_pressed(name: String):
	# Pressing the A button (Right hand) or X button (Left hand) spawns a new Pd module
	if name == "ax_button" or name == "primary_click":
		spawn_pd_module()

func _on_button_released(name: String):
	# Handle grip release explicitly if needed
	if name == "grip":
		if held_object:
			if held_object.has_method("release"):
				held_object.release()
			held_object = null

func spawn_pd_module():
	var new_module = RigidBody3D.new()
	new_module.set_script(load("res://pd_module.gd"))
	
	# Visual box representing a Pd object window
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.18, 0.1, 0.02)
	mesh.mesh = box
	new_module.add_child(mesh)
	
	# Collision shape for future interaction
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	new_module.add_child(collision)
	
	# Safely access the main scene tree root to find the patch window
	var main_loop = Engine.get_main_loop() as SceneTree
	if main_loop and main_loop.root:
		var windows = main_loop.get_nodes_in_group("patch_window")
		if windows.size() > 0:
			var patch_win = windows[0]
			patch_win.add_child(new_module)
			new_module.global_position = global_position
			if new_module.has_method("snap_to_grid"):
				new_module.snap_to_grid()
