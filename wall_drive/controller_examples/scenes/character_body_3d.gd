extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 6.0
@export var ground_acceleration: float = 10.0
@export var air_acceleration: float = 3.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var mouse_sensitivity: float = 0.002
@export var camera_tilt_amount: float = 5.0   # degrees of tilt for movement
@export var camera_tilt_speed: float = 6.0    # how fast the tilt interpolates

var pitch: float = 0.0
@onready var camera_pivot: Node3D = $CameraPivot


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movement input (NO normalization)
	var input_vec = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("back") - Input.get_action_strength("forward")
	)

	# Local to world direction
	var direction = (transform.basis * Vector3(input_vec.x, 0, input_vec.y))

	# Pick accel based on grounded/airborne
	var accel: float
	if is_on_floor():
		accel = ground_acceleration
	else:
		accel = air_acceleration

	# Target velocity (no normalization, full speed stacking on diagonals)
	var target_velocity = direction * speed

	velocity.x = lerp(velocity.x, target_velocity.x, accel * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, accel * delta)

	move_and_slide()

	# --- CAMERA SWAY ---
	var tilt_target = Vector3.ZERO
	if input_vec.length() > 0.0:
		# Tilt sideways when strafing, forward/back for lean effect
		tilt_target.z = -input_vec.x * camera_tilt_amount
		tilt_target.x = input_vec.y * camera_tilt_amount * 0.5  # smaller forward tilt

	# Smoothly interpolate camera pivot rotation towards tilt or back to neutral
	camera_pivot.rotation_degrees.x = lerp(camera_pivot.rotation_degrees.x, pitch * rad_to_deg(1) + tilt_target.x, camera_tilt_speed * delta)
	camera_pivot.rotation_degrees.z = lerp(camera_pivot.rotation_degrees.z, tilt_target.z, camera_tilt_speed * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Yaw
		rotate_y(-event.relative.x * mouse_sensitivity)

		# Pitch
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-80), deg_to_rad(80))
		camera_pivot.rotation.x = pitch
