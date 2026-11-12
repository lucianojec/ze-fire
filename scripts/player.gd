extends CharacterBody3D

signal weapon_changed(weapon_name: String)
signal hit_confirmed()
signal message_changed(message: String)

const WALK_SPEED := 5.0
const RUN_SPEED := 8.0
const JUMP_VELOCITY := 5.0
const CAMERA_DISTANCE := 5.5
const WEAPONS := {
	"pistol": {"name": "Pistola", "damage": 20, "interval": 0.55, "automatic": false},
	"rifle": {"name": "Rifle", "damage": 10, "interval": 0.12, "automatic": true}
}

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var move_input := Vector2.ZERO
var inventory: Dictionary = {}
var equipped_weapon := ""
var firing := false
var shift_lock := false
var look_sensitivity := 0.003
var pitch := -0.12
var camera_yaw := 0.0
var fire_timer := 0.0
var walk_time := 0.0
var hit_flash_timer := 0.0
var limbs: Array[Node3D] = []
var held_weapon: MeshInstance3D


func _ready() -> void:
	_build_stick_figure()
	_build_held_weapon()
	camera_pivot.rotation.x = pitch
	camera_yaw = rotation.y
	_sync_camera_yaw()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if OS.has_feature("web") else Input.MOUSE_MODE_CAPTURED
	weapon_changed.emit("Sem arma")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_camera(event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and OS.has_feature("web") and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		firing = event.pressed
		if firing and equipped_weapon == "pistol":
			_try_fire()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		elif event.keycode == KEY_SHIFT:
			_toggle_shift_lock()
		elif event.keycode == KEY_E:
			_try_pickup()
		elif event.keycode == KEY_1:
			_equip("pistol")
		elif event.keycode == KEY_2:
			_equip("rifle")


func _physics_process(delta: float) -> void:
	fire_timer = maxf(0.0, fire_timer - delta)
	hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	elif Input.is_key_pressed(KEY_SPACE) or _action_is_active("jump"):
		velocity.y = JUMP_VELOCITY

	var keyboard_input := Vector2.ZERO
	keyboard_input.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	keyboard_input.y = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	var input_vector := keyboard_input + move_input
	input_vector = input_vector.limit_length()

	var camera_forward := -camera_pivot.global_basis.z
	var camera_right := camera_pivot.global_basis.x
	camera_forward.y = 0
	camera_right.y = 0
	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()
	var direction := camera_right * input_vector.x + camera_forward * -input_vector.y

	if direction.length_squared() > 0.001:
		var speed := RUN_SPEED if Input.is_key_pressed(KEY_CTRL) else WALK_SPEED
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if not shift_lock:
			rotation.y = atan2(-direction.x, -direction.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 5.0 * delta)

	if shift_lock:
		rotation.y = camera_yaw
	_sync_camera_yaw()

	move_and_slide()
	_update_camera_collision()
	_update_animation(delta, input_vector.length() > 0.05)

	if firing and equipped_weapon == "rifle":
		_try_fire()


func handle_action(action: String, pressed: bool) -> void:
	match action:
		"shoot":
			firing = pressed
			if pressed and equipped_weapon == "pistol":
				_try_fire()
			elif pressed and equipped_weapon == "rifle":
				_try_fire()
		"jump":
			if pressed and is_on_floor():
				velocity.y = JUMP_VELOCITY
		"shift_lock":
			if pressed:
				_toggle_shift_lock()
		"pickup":
			if pressed:
				_try_pickup()
		"switch":
			if pressed:
				if equipped_weapon == "pistol":
					_equip("rifle")
				else:
					_equip("pistol")


func set_move_input(value: Vector2) -> void:
	move_input = value


func handle_touch_look(delta: Vector2) -> void:
	_rotate_camera(delta)


func _rotate_camera(delta: Vector2) -> void:
	camera_yaw -= delta.x * look_sensitivity
	pitch = clampf(pitch - delta.y * look_sensitivity, -0.75, 0.28)
	camera_pivot.rotation.x = pitch
	if shift_lock:
		rotation.y = camera_yaw
	_sync_camera_yaw()


func _sync_camera_yaw() -> void:
	camera_pivot.rotation.y = camera_yaw - rotation.y


func _toggle_shift_lock() -> void:
	shift_lock = not shift_lock
	if shift_lock:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	message_changed.emit("Shift Lock " + ("ativado" if shift_lock else "desativado"))


func _try_pickup() -> void:
	var nearest: Node3D
	var nearest_distance := 2.8
	for pickup_node in get_tree().get_nodes_in_group("weapon_pickups"):
		var pickup := pickup_node as Node3D
		if pickup == null:
			continue
		if not is_instance_valid(pickup):
			continue
		var distance := global_position.distance_to(pickup.global_position)
		if distance < nearest_distance:
			nearest = pickup
			nearest_distance = distance
	if nearest == null:
		return

	var weapon_id := str(nearest.get("weapon_id"))
	inventory[weapon_id] = true
	_equip(weapon_id)
	message_changed.emit(WEAPONS[weapon_id]["name"] + " coletada")
	nearest.queue_free()


func _equip(weapon_id: String) -> void:
	if not inventory.has(weapon_id):
		return
	equipped_weapon = weapon_id
	held_weapon.visible = true
	var weapon_data: Dictionary = WEAPONS[weapon_id]
	weapon_changed.emit(weapon_data["name"])
	if weapon_id == "pistol":
		held_weapon.scale = Vector3(0.65, 0.65, 0.65)
		held_weapon.position = Vector3(0.34, -0.28, -0.7)
	else:
		held_weapon.scale = Vector3(1.0, 1.0, 1.0)
		held_weapon.position = Vector3(0.38, -0.28, -0.82)


func _try_fire() -> void:
	if equipped_weapon.is_empty() or fire_timer > 0.0:
		return
	var weapon_data: Dictionary = WEAPONS[equipped_weapon]
	fire_timer = weapon_data["interval"]
	var ray_start := camera.project_ray_origin(get_viewport().get_visible_rect().size * 0.5)
	var ray_end := ray_start + camera.project_ray_normal(get_viewport().get_visible_rect().size * 0.5) * 100.0
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return

	var hit_object: Node = result["collider"]
	if hit_object.is_in_group("targets"):
		if hit_object.has_method("take_damage"):
			hit_object.call("take_damage", weapon_data["damage"])
		hit_confirmed.emit()
	elif hit_object.get_parent() != null and hit_object.get_parent().is_in_group("targets"):
		if hit_object.get_parent().has_method("take_damage"):
			hit_object.get_parent().call("take_damage", weapon_data["damage"])
		hit_confirmed.emit()


func _action_is_active(action_name: String) -> bool:
	return Input.is_action_pressed(action_name) if InputMap.has_action(action_name) else false


func _update_camera_collision() -> void:
	var desired_position := camera_pivot.global_position + camera_pivot.global_basis * Vector3(0, 0, CAMERA_DISTANCE)
	var query := PhysicsRayQueryParameters3D.create(camera_pivot.global_position, desired_position)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		camera.global_position = desired_position
	else:
		camera.global_position = result["position"] + result["normal"] * 0.2


func _build_stick_figure() -> void:
	var black := _make_material(Color(0.035, 0.035, 0.045))
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.27
	head_mesh.height = 0.54
	head.mesh = head_mesh
	head.position = Vector3(0, 1.66, 0)
	head.material_override = black
	add_child(head)

	var torso := _make_limb(Vector3(0, 1.12, 0), 0.78, 0.105, black)
	torso.name = "Torso"
	add_child(torso)

	for side in [-1.0, 1.0]:
		var arm_pivot := Node3D.new()
		arm_pivot.position = Vector3(side * 0.12, 1.42, 0)
		add_child(arm_pivot)
		var arm := _make_limb(Vector3(side * 0.3, -0.05, 0), 0.67, 0.055, black)
		arm.rotation.z = -side * PI * 0.5
		arm_pivot.add_child(arm)
		limbs.append(arm_pivot)

		var leg_pivot := Node3D.new()
		leg_pivot.position = Vector3(side * 0.12, 0.78, 0)
		add_child(leg_pivot)
		var leg := _make_limb(Vector3(0, -0.34, 0), 0.72, 0.065, black)
		leg_pivot.add_child(leg)
		limbs.append(leg_pivot)


func _make_limb(limb_position: Vector3, length: float, radius: float, material: Material) -> MeshInstance3D:
	var limb := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	limb.mesh = mesh
	limb.position = limb_position
	limb.material_override = material
	return limb


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


func _build_held_weapon() -> void:
	held_weapon = MeshInstance3D.new()
	var weapon_mesh := BoxMesh.new()
	weapon_mesh.size = Vector3(0.16, 0.16, 0.52)
	held_weapon.mesh = weapon_mesh
	held_weapon.material_override = _make_material(Color(0.14, 0.15, 0.18))
	held_weapon.position = Vector3(0.34, -0.28, -0.7)
	held_weapon.visible = false
	camera.add_child(held_weapon)


func _update_animation(delta: float, moving: bool) -> void:
	if moving and is_on_floor():
		walk_time += delta * 9.0
		for index in limbs.size():
			var phase := walk_time + (PI if index % 2 == 0 else 0.0)
			limbs[index].rotation.x = sin(phase) * 0.48
	else:
		for limb in limbs:
			limb.rotation.x = move_toward(limb.rotation.x, 0.0, delta * 4.0)
