extends Node3D

var xr_interface: XRInterface

func _ready():
	# Try to find the OpenXR interface
	xr_interface = XRServer.find_interface("OpenXR")
	
	if xr_interface and xr_interface.initialize():
		print("OpenXR initialized successfully!")
		
		# Tell the viewport to render in immersive VR mode
		get_viewport().use_xr = true
		
		# Optional: VSync can cause framerate hitching in mobile VR, keep it disabled
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		print("OpenXR not available or failed to initialize. Running in standard flat screen mode.")
