extends Node3D
class_name ItemContainer

const GRID_SIZE = 0.1

#@export var size : Vector3i

const VISUALIZER_SCENE = preload("uid://d3d6ssea441iy")

@export var grid : ItemGrid


func _ready() -> void:
	pass
	# Create base grid
	#for x in range(size.x):
		#for y in range(size.y):
			#for z in range(size.z):
				#var new_vis = VISUALIZER_SCENE.instantiate()
				#add_child(new_vis)
				#new_vis.position = Vector3i(x, y, z) * GRID_SIZE
