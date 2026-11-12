extends Node3D

const LEVEL_SCENE: PackedScene = preload("res://scenes/level.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const TARGET_SCENE: PackedScene = preload("res://scenes/target.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/weapon_pickup.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/hud.tscn")

var player
var hud


func _ready() -> void:
	add_child(LEVEL_SCENE.instantiate())

	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 0.05, 0)
	add_child(player)

	_add_pickup("pistol", Vector3(-1.3, 0.08, -1.2))
	_add_pickup("rifle", Vector3(1.3, 0.08, -1.2))

	for target_position in [
		Vector3(-4.5, 0, -9),
		Vector3(0, 0, -11),
		Vector3(4.5, 0, -9)
	]:
		var target: Node3D = TARGET_SCENE.instantiate() as Node3D
		target.position = target_position
		add_child(target)

	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.action_changed.connect(player.handle_action)
	hud.joystick_changed.connect(player.set_move_input)
	hud.camera_dragged.connect(player.handle_touch_look)
	player.weapon_changed.connect(hud.set_weapon_name)
	player.hit_confirmed.connect(hud.show_hit)
	player.message_changed.connect(hud.show_message)
	hud.set_weapon_name("Sem arma")


func _add_pickup(weapon_id: String, pickup_position: Vector3) -> void:
	var pickup: Area3D = PICKUP_SCENE.instantiate() as Area3D
	pickup.set("weapon_id", weapon_id)
	pickup.position = pickup_position
	add_child(pickup)
