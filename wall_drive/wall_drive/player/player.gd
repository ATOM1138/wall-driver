extends CharacterBody3D
class_name Player


enum States {WALK, DRIVE}
var state = States.WALK

var mass = 75


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
