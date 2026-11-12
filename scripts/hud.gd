extends CanvasLayer

signal action_changed(action: String, pressed: bool)
signal joystick_changed(value: Vector2)
signal camera_dragged(delta: Vector2)

var weapon_label: Label
var message_label: Label
var crosshair: Label
var hit_timer := 0.0
var joystick_touch := -1
var joystick_center := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var look_touch := -1
var look_position := Vector2.ZERO
var mobile_controls: Array[Control] = []


func _ready() -> void:
	_create_hud()
	var is_mobile := OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	for control in mobile_controls:
		control.visible = is_mobile


func _process(delta: float) -> void:
	if hit_timer > 0.0:
		hit_timer -= delta
		if hit_timer <= 0.0:
			crosshair.text = "+"
			crosshair.add_theme_color_override("font_color", Color.WHITE)


func set_weapon_name(value: String) -> void:
	weapon_label.text = "Arma: " + value


func show_hit() -> void:
	hit_timer = 0.16
	crosshair.text = "×"
	crosshair.add_theme_color_override("font_color", Color(1.0, 0.35, 0.2))


func show_message(value: String) -> void:
	message_label.text = value
	message_label.visible = true
	get_tree().create_timer(1.6).timeout.connect(func(): message_label.visible = false)


func _create_hud() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	weapon_label = Label.new()
	weapon_label.position = Vector2(18, 16)
	weapon_label.add_theme_font_size_override("font_size", 20)
	root.add_child(weapon_label)

	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-12, -22)
	crosshair.add_theme_font_size_override("font_size", 32)
	crosshair.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(crosshair)

	message_label = Label.new()
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.position = Vector2(-150, 62)
	message_label.size = Vector2(300, 32)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.visible = false
	root.add_child(message_label)

	var look_area := Control.new()
	look_area.anchor_left = 0.5
	look_area.anchor_right = 1.0
	look_area.anchor_bottom = 0.72
	look_area.mouse_filter = Control.MOUSE_FILTER_STOP
	look_area.gui_input.connect(_on_look_input)
	root.add_child(look_area)
	mobile_controls.append(look_area)

	var joystick := Control.new()
	joystick.anchor_left = 0.02
	joystick.anchor_top = 0.62
	joystick.anchor_bottom = 0.98
	joystick.offset_right = 180
	joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	joystick.draw.connect(_draw_joystick.bind(joystick))
	joystick.gui_input.connect(_on_joystick_input.bind(joystick))
	root.add_child(joystick)
	mobile_controls.append(joystick)

	_add_action_button(root, "ATIRAR", "shoot", Vector2(0.79, 0.73), Vector2(100, 100))
	_add_action_button(root, "PULAR", "jump", Vector2(0.9, 0.57), Vector2(76, 76))
	_add_action_button(root, "SHIFT", "shift_lock", Vector2(0.67, 0.78), Vector2(74, 58))
	_add_action_button(root, "PEGAR", "pickup", Vector2(0.67, 0.9), Vector2(74, 58))
	_add_action_button(root, "TROCAR", "switch", Vector2(0.9, 0.84), Vector2(76, 58))


func _add_action_button(root: Control, title: String, action: String, anchor: Vector2, dimensions: Vector2) -> void:
	var button := Button.new()
	button.text = title
	button.anchor_left = anchor.x
	button.anchor_top = anchor.y
	button.anchor_right = anchor.x
	button.anchor_bottom = anchor.y
	button.offset_left = -dimensions.x * 0.5
	button.offset_top = -dimensions.y * 0.5
	button.offset_right = dimensions.x * 0.5
	button.offset_bottom = dimensions.y * 0.5
	button.add_theme_font_size_override("font_size", 15)
	button.button_down.connect(func(): action_changed.emit(action, true))
	button.button_up.connect(func(): action_changed.emit(action, false))
	root.add_child(button)
	mobile_controls.append(button)


func _draw_joystick(control: Control) -> void:
	var center := control.size * 0.5
	control.draw_circle(center, 66, Color(0.08, 0.08, 0.1, 0.28))
	control.draw_arc(center, 66, 0, TAU, 48, Color(1, 1, 1, 0.65), 2)
	control.draw_circle(center + joystick_vector * 38, 27, Color(0.85, 0.88, 0.92, 0.65))


func _on_joystick_input(event: InputEvent, control: Control) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and joystick_touch == -1:
			joystick_touch = event.index
			joystick_center = control.size * 0.5
			_update_joystick(_to_control_position(control, event.position))
		elif not event.pressed and event.index == joystick_touch:
			joystick_touch = -1
			joystick_vector = Vector2.ZERO
			joystick_changed.emit(Vector2.ZERO)
			control.queue_redraw()
	elif event is InputEventScreenDrag and event.index == joystick_touch:
		_update_joystick(_to_control_position(control, event.position))
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			joystick_touch = -2
			joystick_center = control.size * 0.5
			_update_joystick(_to_control_position(control, event.position))
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			joystick_touch = -1
			joystick_vector = Vector2.ZERO
			joystick_changed.emit(Vector2.ZERO)
			control.queue_redraw()
	elif event is InputEventMouseMotion and joystick_touch == -2:
		_update_joystick(_to_control_position(control, event.position))


func _update_joystick(position: Vector2) -> void:
	joystick_vector = ((position - joystick_center) / 58.0).limit_length()
	joystick_changed.emit(joystick_vector)


func _to_control_position(control: Control, position: Vector2) -> Vector2:
	return control.get_global_transform_with_canvas().affine_inverse() * position


func _on_look_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and look_touch == -1:
			look_touch = event.index
			look_position = event.position
		elif not event.pressed and event.index == look_touch:
			look_touch = -1
	elif event is InputEventScreenDrag and event.index == look_touch:
		camera_dragged.emit(event.position - look_position)
		look_position = event.position
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			look_touch = -2 if event.pressed else -1
			look_position = event.position
	elif event is InputEventMouseMotion and look_touch == -2:
		camera_dragged.emit(event.position - look_position)
		look_position = event.position
