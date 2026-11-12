extends Area3D

@export_enum("pistol", "rifle") var weapon_id := "pistol"


func _ready() -> void:
	add_to_group("weapon_pickups")
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.22, 0.16, 0.65) if weapon_id == "rifle" else Vector3(0.18, 0.18, 0.32)
	mesh_instance.mesh = mesh
	mesh_instance.position.y = 0.55
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.16, 0.17, 0.2) if weapon_id == "rifle" else Color(0.55, 0.58, 0.62)
	material.roughness = 1.0
	mesh_instance.material_override = material
	add_child(mesh_instance)
