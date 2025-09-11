@tool
extends Node3D
class_name TerrainGenerator

@export var noise: FastNoiseLite
@export var ground_parent: Node3D
@export var player_node: Node3D
@export var chunk_size: int = 256
@export var terrain_height: float = 50.0
@export var terrain_material: Material
@export var load_radius_chunks: int = 3
@export var unload_radius_chunks: int = 5

# Dictionary. key = Vector2(chunk_x, chunk_z)
var active_chunks: Dictionary = {}

# Called in editor or at runtime
func generate_initial_chunks():
	if not player_node or not ground_parent:
		printerr("Assign player_node and ground_parent before generating terrain.")
		return
	_update_chunks()

# wippe generated chuinks 
func wipe_terrain():
	for chunk in active_chunks.values():
		chunk.queue_free()
	active_chunks.clear()

# compputer

# FIND 
func _get_player_chunk_coords() -> Vector2:
	var px = int(player_node.global_transform.origin.x / chunk_size)
	var pz = int(player_node.global_transform.origin.z / chunk_size)
	return Vector2(px, pz)

# generate OR remove
func _update_chunks():
	var player_chunk = _get_player_chunk_coords()
	
	# Generate new
	for dz in range(-load_radius_chunks, load_radius_chunks + 1):
		for dx in range(-load_radius_chunks, load_radius_chunks + 1):
			var chunk_coords = Vector2(player_chunk.x + dx, player_chunk.y + dz)
			if not active_chunks.has(chunk_coords):
				var new_chunk = _generate_chunk(chunk_coords)
				active_chunks[chunk_coords] = new_chunk
	
	# Remove 
	var keys_to_remove := []
	for coords in active_chunks.keys():
		if coords.distance_to(player_chunk) > unload_radius_chunks:
			active_chunks[coords].queue_free()
			keys_to_remove.append(coords)
	for k in keys_to_remove:
		active_chunks.erase(k)

# Generate a single chunk a t ppos 
func _generate_chunk(chunk_coords: Vector2) -> MeshInstance3D:
	var start_x = int(chunk_coords.x) * chunk_size
	var start_z = int(chunk_coords.y) * chunk_size
	var end_x = start_x + chunk_size
	var end_z = start_z + chunk_size

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(start_z, end_z - 1):
		for x in range(start_x, end_x - 1):
			# Sample noise
			var h1 = noise.get_noise_2d(x, z) * terrain_height
			var h2 = noise.get_noise_2d(x + 1, z) * terrain_height
			var h3 = noise.get_noise_2d(x, z + 1) * terrain_height
			var h4 = noise.get_noise_2d(x + 1, z + 1) * terrain_height

			var v1 = Vector3(x,     h1, z)
			var v2 = Vector3(x + 1, h2, z)
			var v3 = Vector3(x,     h3, z + 1)
			var v4 = Vector3(x + 1, h4, z + 1)

			# First triangle
			st.add_vertex(v1)
			st.add_vertex(v2)
			st.add_vertex(v3)
			# Second triangle
			st.add_vertex(v2)
			st.add_vertex(v4)
			st.add_vertex(v3)

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3.ZERO

	# material
	if terrain_material:
		mi.set_surface_override_material(0, terrain_material)

	# colide
	var shape := HeightMapShape3D.new()
	shape.map_width = chunk_size
	shape.map_depth = chunk_size
	var local_height := PackedFloat32Array()
	local_height.resize(chunk_size * chunk_size)
	for z in range(chunk_size):
		for x in range(chunk_size):
			local_height[z * chunk_size + x] = noise.get_noise_2d(start_x + x, start_z + z) * terrain_height
	shape.map_data = local_height

	var col := CollisionShape3D.new()
	col.shape = shape
	mi.add_child(col)

	# adopt
	ground_parent.add_child(mi)
	if Engine.is_editor_hint():
		mi.owner = get_tree().edited_scene_root

	return mi

# call when schmove
func _process(delta):
	if player_node:
		_update_chunks()
