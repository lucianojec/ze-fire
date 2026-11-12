extends Node3D


func _ready() -> void:
	_add_box("Ground", Vector3(0, -0.25, -5), Vector3(34, 0.5, 34), Color(0.25, 0.67, 0.28))
	_add_box("LowWallLeft", Vector3(-6, 0.65, -5), Vector3(0.6, 1.3, 8), Color(0.82, 0.57, 0.32))
	_add_box("BlockCenter", Vector3(0, 0.6, -6.5), Vector3(2, 1.2, 0.8), Color(0.95, 0.72, 0.27))
	_add_box("BlockRight", Vector3(6, 1, -8), Vector3(1.2, 2, 2), Color(0.3, 0.55, 0.82))


func _add_box(box_name: String, box_position: Vector3, box_size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = box_position
	add_child(body)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = _flat_material(color)
	body.add_child(mesh_instance)


func _flat_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
