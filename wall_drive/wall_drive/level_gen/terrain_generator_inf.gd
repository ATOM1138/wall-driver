@tool
extends Node3D
class_name TerrainGenerator

@export_tool_button("Generate Terrain") var ter_gen = generate_initial_chunks
@export_tool_button("Test Terrain") var ter_test = generate_test_chunk
@export_tool_button("Wipe Terrain") var ter_wipe = wipe_terrain

@export var noise: FastNoiseLite
@export var ground_parent: Node3D
@export var player_node: Node3D
@export var wall_generator : WallGenerator
@export var chunk_size: int = 256
@export var terrain_height: float = 50.0
@export var terrain_material: Material
@export var load_radius_chunks: int = 3
@export var unload_radius_chunks: int = 5

# Dictionary. key = Vector2(chunk_x, chunk_z)
var active_chunks: Dictionary = {}

var gen_thread := Thread.new()
## Only an export because tool script weirdness, pls dont touch
@export var segments_pos : Array[Vector3]


func _ready() -> void:
	wipe_terrain()
	generate_initial_chunks()


# Called in editor or at runtime
func generate_initial_chunks():
	if Engine.is_editor_hint():
		gen_thread = Thread.new()
	
	if not player_node or not ground_parent:
		printerr("Assign player_node and ground_parent before generating terrain.")
		return
	update_chunks()

# wipe generated chuinks 
func wipe_terrain():
	for chunk in active_chunks.values():
		if chunk:
			chunk.queue_free()
	active_chunks.clear()
	
	for child in ground_parent.get_children():
		child.queue_free()


func generate_test_chunk():
	generate_chunk(Vector2.ZERO)


# compputer

# FIND 
func get_player_chunk_coords() -> Vector2:
	var px = int(player_node.global_transform.origin.x / chunk_size)
	var pz = int(player_node.global_transform.origin.z / chunk_size)
	return Vector2(px, pz)

# generate OR remove
func update_chunks():
	if player_node == null:
		return
	
	var player_chunk = get_player_chunk_coords()
	
	# Remove 
	var keys_to_remove := []
	for coords in active_chunks.keys():
		if coords.distance_to(player_chunk) > unload_radius_chunks:
			active_chunks[coords].queue_free()
			keys_to_remove.append(coords)
	for k in keys_to_remove:
		active_chunks.erase(k)
	
	if not gen_thread.is_alive() and gen_thread.is_started():
		var return_values : Array = gen_thread.wait_to_finish()
		var new_chunk = return_values[0]
		active_chunks[return_values[1]] = new_chunk
	
	# Generate new
	if not gen_thread.is_started():
		for dz in range(-load_radius_chunks, load_radius_chunks + 1):
			for dx in range(-load_radius_chunks, load_radius_chunks + 1):
				var chunk_coords = Vector2(player_chunk.x + dx, player_chunk.y + dz)
				if not active_chunks.has(chunk_coords):
					gen_thread.start(generate_chunk.bind(chunk_coords))
					return
		

# Generate a single chunk a t ppos 
func generate_chunk(chunk_coords: Vector2) -> Array:
	var world_chunk_coords := chunk_coords * chunk_size
	
	noise.offset = Vector3(world_chunk_coords.x, world_chunk_coords.y, 0)
	
	var modify_data := PackedFloat32Array()
	for segment_i in len(wall_generator.segments):
		var segment : WallSegment = wall_generator.segments[segment_i]
		
		var segment_pos : Vector3 = segments_pos[segment_i]
		for modifier in segment.terrain_modifiers:
			print(modifier.offset + Vector2(segment_pos.x, segment_pos.z))
	
	var height_data := PackedFloat32Array()
	for z in range(chunk_size + 1):
		for x in range(chunk_size + 1):
			height_data.append(noise.get_noise_2d(x, z) * terrain_height)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(0, chunk_size):
		for x in range(0, chunk_size):
			# Sample noise
			var h1 = height_data[(z * (chunk_size + 1)) + x]
			var h2 = height_data[(z * (chunk_size + 1)) + x + 1]
			var h3 = height_data[((z + 1) * (chunk_size + 1)) + x]
			var h4 = height_data[((z + 1) * (chunk_size + 1)) + x + 1]

			var v1 = Vector3(x,     h1, z)
			var v2 = Vector3(x + 1, h2, z)
			var v3 = Vector3(x,     h3, z + 1)
			var v4 = Vector3(x + 1, h4, z + 1)

			# First triangle
			#var normal = get_triangle_normal(v1, v2, v3)
			#st.set_normal(normal)
			st.add_vertex(v1)
			#st.set_normal(normal)
			st.add_vertex(v2)
			#st.set_normal(normal)
			st.add_vertex(v3)
			# Second triangle
			#normal = get_triangle_normal(v2, v4, v3)
			#st.set_normal(normal)
			st.add_vertex(v2)
			#st.set_normal(normal)
			st.add_vertex(v4)
			#st.set_normal(normal)
			st.add_vertex(v3)

	#st.generate_normals()
	st.index()
	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3.ZERO

	# material
	if terrain_material:
		mi.set_surface_override_material(0, terrain_material)
	
	var sb := StaticBody3D.new()
	sb.position = Vector3(world_chunk_coords.x , 0, world_chunk_coords.y)
	sb.add_child(mi)
	
	# colide
	var shape := HeightMapShape3D.new()
	shape.map_width = chunk_size + 1
	shape.map_depth = chunk_size + 1
	shape.map_data = height_data

	var col := CollisionShape3D.new()
	col.shape = shape
	sb.add_child(col)
	col.position = Vector3(chunk_size / 2.0, 0, chunk_size / 2.0)

	# adopt
	#ground_parent.add_child(sb)
	ground_parent.call_deferred("add_child", sb)
	#if Engine.is_editor_hint():
		#sb.owner = ground_parent
		#col.owner = ground_parent
	
	return [sb, chunk_coords]


func get_triangle_normal(a, b, c):
	# Find the surface normal given 3 vertices.
	var side1 = b - a
	var side2 = c - a
	var normal = side1.cross(side2)
	return -normal
