extends Area3D

@export var default_parent : Node3D


func set_freeze(frozen : bool):
	for body in get_overlapping_bodies():
		if body is RigidBody3D:
			body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
			body.freeze = frozen
			
			if frozen:
				body.reparent(self)
			else:
				if default_parent == null:
					print_rich("[color=red]{%s} default parent not set.[/color]" % name)
					return
				body.reparent(default_parent)

func _physics_process(delta: float) -> void:
	position.x = sin(float(Engine.get_frames_drawn() % 2048) / 2048.0) * 8
	print(float(Engine.get_frames_drawn() % 256) / 256.0)
	
	if Input.is_action_just_pressed("walk_grab"):
		set_freeze(true)
	if Input.is_action_just_pressed("walk_jump"):
		set_freeze(false)
