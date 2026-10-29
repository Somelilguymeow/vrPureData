extends RigidBody3D

var is_grabbed: bool = false
var grabber: Node3D = null
var grab_offset: Transform3D

func _ready():
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	contact_monitor = true
	max_contacts_reported = 4
	# Ensure it's in the grabbable group
	if not is_in_group("grabbable"):
		add_to_group("grabbable")

func _process(_delta):
	if is_grabbed and grabber:
		global_transform = grabber.global_transform * grab_offset

func grab(controller: Node3D):
	if not is_grabbed:
		is_grabbed = true
		grabber = controller
		grab_offset = controller.global_transform.inverse() * global_transform
		freeze = true

func release():
	if is_grabbed:
		is_grabbed = false
		grabber = null
		freeze = false
