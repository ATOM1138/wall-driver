@tool
extends Node3D
class_name WorldGenerator

@export var wall_generator : WallGenerator
@export var terrain_generator : TerrainGenerator
@export_tool_button("Wipe World") var world_wipe = wipe_world


func wipe_world():
	if wall_generator:
		wall_generator.wipe_wall()
	if terrain_generator:
		terrain_generator.wipe_terrain()


func _process(delta: float) -> void:
	if wall_generator:
		wall_generator.update_wall()
	if terrain_generator:
		if wall_generator:
			terrain_generator.segments_pos = wall_generator.get_segment_pos()
		
		terrain_generator.update_chunks()
