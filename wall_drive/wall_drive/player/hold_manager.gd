extends Node
class_name HoldManager


@export var hold_marker: Node3D
@export var hold_ray: RayCast3D
@export var ray_exeptions: Array[CollisionObject3D]


func _ready() -> void:
	for object in ray_exeptions:
		hold_ray.add_exception(object)


func _physics_process(_delta: float) -> void:
	pass
	#if hold_ray.get_collider():
		#print(hold_ray.get_collider().name)
