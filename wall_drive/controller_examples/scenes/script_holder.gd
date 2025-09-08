## Attach this script to the **Vehicle** root node (Node3D)
## Requires:
## - Seat (Node3D) -> snap point for player
## - VehicleController (Node) -> driving script
## - InteractionArea (Area3D with CollisionShape) -> detects player presence
## - UI Prompt (Label or Control node) -> shows "Press E to enter vehicle"

extends Node3D

@export var seat: Node3D
@export var vehicle_controller: Node
@export var interaction_area: Area3D
@export var ui_prompt: Control

var player: CharacterBody3D = null
var is_player_inside: bool = false
var can_interact: bool = false



	
func _ready() -> void:
	if seat == null:
		push_error("Seat node is not assigned")
	if vehicle_controller == null:
		push_error("Vehicle controller is not assigned")
	if interaction_area == null:
		push_error("Interaction area is not assigned")
	else:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	if ui_prompt != null:
		ui_prompt.visible = false
	else:
		push_warning("UI prompt is not assigned; no on-screen prompt will be shown")


	
func _physics_process(_delta: float) -> void:
	if can_interact and Input.is_action_just_pressed("interact"):
		print("interact caugt")
		if player != null:
			interact(player)
			


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and not is_player_inside:
		player = body
		can_interact = true
		if ui_prompt != null:
			ui_prompt.text = "Press E to enter vehicle"
			ui_prompt.visible = true
		print("Player entered interaction area")

func _on_body_exited(body: Node) -> void:
	if body == player and not is_player_inside:
		can_interact = false
		if ui_prompt != null:
			ui_prompt.visible = false
		player = null
		print("Player exited interaction area")

func interact(player_ref: CharacterBody3D) -> void:
	if is_player_inside:
		exit_vehicle()
	else:
		enter_vehicle(player_ref)

func enter_vehicle(player_ref: CharacterBody3D) -> void:
	if is_player_inside:
		return

	player = player_ref

	# Snap player to seat
	player.global_transform = seat.global_transform

	# Disable player controller
	player.set_process(false)
	player.set_physics_process(false)
	print("Player controller disabled")

	# Parent player to vehicle
	player.get_parent().remove_child(player)
	seat.add_child(player)
	print("Player parented to seat")

	# Enable vehicle controller
	vehicle_controller.set_process(true)
	vehicle_controller.set_physics_process(true)
	print("Vehicle controller enabled")

	is_player_inside = true
	can_interact = false
	if ui_prompt != null:
		ui_prompt.visible = false



func exit_vehicle() -> void:
	if not is_player_inside:
		return

	# Detach player from vehicle
	seat.remove_child(player)
	get_parent().add_child(player)
	print("Player detached from vehicle")

	# Place player outside vehicle
	var exit_pos = seat.global_transform.origin + seat.global_transform.basis.z * -2.0
	player.global_transform.origin = exit_pos
	print("Player moved outside vehicle")

	# Enable player controller
	player.set_process(true)
	player.set_physics_process(true)
	print("Player controller re-enabled")

	# Disable vehicle controller
	vehicle_controller.set_process(false)
	vehicle_controller.set_physics_process(false)
	print("Vehicle controller disabled")

	player = null
	is_player_inside = false
	can_interact = false
	if ui_prompt != null:
		ui_prompt.visible = false
