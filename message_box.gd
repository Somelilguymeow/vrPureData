@tool
extends MeshInstance3D

@export var pixel_width: float = 26.0:
	set(val):
		pixel_width = val
		if Engine.is_editor_hint() or is_inside_tree():
			rebuild()

const BOX_HEIGHT: float = 0.05
const DEPTH: float = 0.05
const TAPER_OFFSET: float = 0.0125  # 0.0125m offset for 45° angle & tip dimensions
const RIGHT_SHIFT: float = 0.0125   # Net shift right

func _ready():
	rebuild()

func rebuild():
	var base_width = pixel_width * 0.0025
	mesh = build_message_box_mesh(base_width)

func build_message_box_mesh(base_width: float) -> ArrayMesh:
	var hw = base_width / 2.0
	var hh = BOX_HEIGHT / 2.0
	var hd = DEPTH / 2.0
	
	var polygon = PackedVector2Array([
		Vector2(-hw, hh),                                          # 0: Top-Left
		Vector2(-hw, -hh),                                         # 1: Bottom-Left
		Vector2(hw + RIGHT_SHIFT, -hh),                            # 2: Bottom-Right outer corner
		Vector2((hw - TAPER_OFFSET) + RIGHT_SHIFT, -TAPER_OFFSET), # 3: Bottom of tip face
		Vector2((hw - TAPER_OFFSET) + RIGHT_SHIFT, TAPER_OFFSET),  # 4: Top of tip face
		Vector2(hw + RIGHT_SHIFT, hh)                              # 5: Top-Right outer corner
	])
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var indices = Geometry2D.triangulate_polygon(polygon)
	if indices.is_empty(): return null
		
	# Front Face (Z = hd)
	st.set_normal(Vector3(0, 0, 1))
	for i in range(indices.size() - 1, -1, -1):
		st.add_vertex(Vector3(polygon[indices[i]].x, polygon[indices[i]].y, hd))
		
	# Back Face (Z = -hd)
	st.set_normal(Vector3(0, 0, -1))
	for i in indices:
		st.add_vertex(Vector3(polygon[indices[i]].x, polygon[indices[i]].y, -hd))
		
	# Side Faces
	for i in range(polygon.size()):
		var p1 = polygon[i]
		var p2 = polygon[(i + 1) % polygon.size()]
		
		var dir = (p2 - p1).normalized()
		var normal = Vector3(-dir.y, dir.x, 0)
		st.set_normal(normal)
		
		st.add_vertex(Vector3(p1.x, p1.y, hd))
		st.add_vertex(Vector3(p2.x, p2.y, hd))
		st.add_vertex(Vector3(p1.x, p1.y, -hd))
		
		st.add_vertex(Vector3(p2.x, p2.y, hd))
		st.add_vertex(Vector3(p2.x, p2.y, -hd))
		st.add_vertex(Vector3(p1.x, p1.y, -hd))
		
	return st.commit()
