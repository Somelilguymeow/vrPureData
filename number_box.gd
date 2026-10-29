@tool
extends MeshInstance3D

@export var pixel_width: float = 38.0:
	set(val):
		pixel_width = val
		if Engine.is_editor_hint() or is_inside_tree():
			rebuild()

const BOX_HEIGHT: float = 0.0475 # 19px height (1 pixel short vertically)
const DEPTH: float = 0.05
const SNIP_SIZE: float = 0.0125

func _ready():
	rebuild()

func rebuild():
	var total_width = pixel_width * 0.0025
	mesh = build_number_box_mesh(total_width, BOX_HEIGHT)

func build_number_box_mesh(total_width: float, height: float) -> ArrayMesh:
	var half_w = total_width / 2.0
	var half_h = height / 2.0
	var hd = DEPTH / 2.0
	
	var polygon = PackedVector2Array([
		Vector2(-half_w, half_h),                     # Top-Left
		Vector2(half_w - SNIP_SIZE, half_h),         # Top edge before snip
		Vector2(half_w, half_h - SNIP_SIZE),        # Snipped top-right corner down
		Vector2(half_w, -half_h),                    # Bottom-Right
		Vector2(-half_w, -half_h)                    # Bottom-Left
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
		st.add_vertex(Vector3(polygon[i].x, polygon[i].y, -hd))
		
	# Side Faces
	for i in range(polygon.size()):
		var p1 = polygon[i]
		var p2 = polygon[(i + 1) % polygon.size()]
		
		var dir = (p2 - p1).normalized()
		var normal = Vector3(dir.y, dir.x, 0)
		st.set_normal(normal)
		
		st.add_vertex(Vector3(p1.x, p1.y, hd))
		st.add_vertex(Vector3(p1.x, p1.y, -hd))
		st.add_vertex(Vector3(p2.x, p2.y, hd))
		
		st.add_vertex(Vector3(p2.x, p2.y, hd))
		st.add_vertex(Vector3(p1.x, p1.y, -hd))
		st.add_vertex(Vector3(p2.x, p2.y, -hd))
		
	return st.commit()
