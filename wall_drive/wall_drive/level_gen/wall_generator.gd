@tool
extends Node3D
class_name WallGenerator


#@export_tool_button("Generate Wall") var wall_gen = generate_wall
@export_tool_button("Wipe Wall") var wall_wipe = wipe_wall
@export var player_node: Node3D
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var load_distance : float
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var unload_distance : float
@export var segment_scenes : Array[PackedScene]

var segments : Array[WallSegment] = []


func _ready() -> void:
	wipe_wall()


func wipe_wall():
	segments = []
	
	for child in get_children():
		child.queue_free()


# Hacky workaround to get segment positions from thread
func get_segment_pos() -> Array[Vector3]:
	var positions : Array[Vector3] = []
	for segment in segments:
		positions.append(segment.global_position)
	
	return positions


func update_wall():
	if len(segments) > 0:
		if player_node.position.z - segments[len(segments) - 1].position.z < load_distance:
			generate_wall_segment()
		
		if segments[0].position.z - player_node.position.z > unload_distance:
			segments[0].queue_free()
			segments.pop_front()
	
	else:
		generate_wall_segment()


func generate_wall_segment():
	var segment : WallSegment = segment_scenes[randi() % len(segment_scenes)].instantiate()
	
	# DEBUG
	if len(segments) == 0:
		segment = segment_scenes[0].instantiate()
	
	add_child(segment)
	
	if len(segments) > 0:
		var last_exit := segments[len(segments) - 1].exit_marker.global_position
		var this_entrance = segment.entrance_marker.position
		segment.global_position = last_exit - this_entrance
	
	segments.append(segment)
