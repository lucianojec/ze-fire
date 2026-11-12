extends StaticBody3D

const MAX_HEALTH := 100
const RESPAWN_DELAY := 3.0

var health := MAX_HEALTH
var body_mesh: MeshInstance3D
var health_fill: MeshInstance3D
var health_back: MeshInstance3D
var collision_shape: CollisionShape3D
var respawn_timer: Timer


func _ready() -> void:
	add_to_group("targets")
	collision_shape = $CollisionShape3D
	body_mesh = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.38
	cylinder.bottom_radius = 0.48
	cylinder.height = 1.5
	body_mesh.mesh = cylinder
	body_mesh.position.y = 0.8
	body_mesh.material_override = _make_material(Color(0.92, 0.28, 0.24))
	add_child(body_mesh)

	health_back = _make_bar(Vector3(0, 1.75, 0), Vector3(0.95, 0.12, 0.03), Color(0.12, 0.12, 0.12))
	health_fill = _make_bar(Vector3(0, 1.75, -0.02), Vector3(0.9, 0.08, 0.04), Color(0.24, 0.9, 0.3))
	add_child(health_back)
	add_child(health_fill)

	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.wait_time = RESPAWN_DELAY
	respawn_timer.timeout.connect(_respawn)
	add_child(respawn_timer)


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	_update_health_bar()
	if health == 0:
		body_mesh.visible = false
		health_back.visible = false
		health_fill.visible = false
		collision_shape.set_deferred("disabled", true)
		respawn_timer.start()


func _respawn() -> void:
	health = MAX_HEALTH
	body_mesh.visible = true
	health_back.visible = true
	health_fill.visible = true
	collision_shape.set_deferred("disabled", false)
	_update_health_bar()


func _update_health_bar() -> void:
	var fraction := float(health) / float(MAX_HEALTH)
	health_fill.scale.x = maxf(fraction, 0.001)
	health_fill.position.x = -0.45 * (1.0 - fraction)


func _make_bar(bar_position: Vector3, bar_size: Vector3, color: Color) -> MeshInstance3D:
	var bar := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = bar_size
	bar.mesh = mesh
	bar.position = bar_position
	bar.material_override = _make_material(color)
	return bar


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	return material
