#OBSOLETE but now wtih chunks! :thumbsupp:

@tool
extends Node
class_name TerrainGenerator_at_2_old

@export var noise: FastNoiseLite
@export var ground_parent: Node3D
@export var chunk_size: int = 256
@export var terrain_width: int = 1024
@export var terrain_length: int = 2048
@export var terrain_height: float = 50.0
@export var terrain_material: Material


func wipe_terrain():
	if ground_parent:
		for c in ground_parent.get_children():
			c.queue_free()

func generate_terrain():
	var start_time = round(Time.get_unix_time_from_system())
	# grenerate full heightmap
	var img := noise.get_image(terrain_width, terrain_length, false, false, true)
	var height_data := PackedFloat32Array()
	height_data.resize(terrain_width * terrain_length)

	for z in range(terrain_length):
		for x in range(terrain_width):
			height_data[z * terrain_width + x] = img.get_pixel(x, z).r * terrain_height

	# Step 2: Generate chunks
	wipe_terrain()

	for cz in range(0, terrain_length, chunk_size):
		for cx in range(0, terrain_width, chunk_size):
			var chunk := _generate_chunk(cx, cz, height_data)
			if ground_parent:
				ground_parent.add_child(chunk)

		print("Terrain generated in: ", Time.get_unix_time_from_system() - start_time, "s")


func _generate_chunk(start_x: int, start_z: int, height_data: PackedFloat32Array) -> Node3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Limit chunk bounds
	var end_x = min(start_x + chunk_size, terrain_width - 1)
	var end_z = min(start_z + chunk_size, terrain_length - 1)

	for z in range(start_z, end_z):
		for x in range(start_x, end_x):
			var h1 = height_data[z * terrain_width + x]
			var h2 = height_data[z * terrain_width + x + 1]
			var h3 = height_data[(z + 1) * terrain_width + x]
			var h4 = height_data[(z + 1) * terrain_width + x + 1]

			var v1 = Vector3(x,    h1, z)
			var v2 = Vector3(x + 1, h2, z)
			var v3 = Vector3(x,    h3, z + 1)
			var v4 = Vector3(x + 1, h4, z + 1)

			# 1 triangle
			st.add_vertex(v1)
			st.add_vertex(v2)
			st.add_vertex(v3)

			# 2 triangle
			st.add_vertex(v2)
			st.add_vertex(v4)
			st.add_vertex(v3)

	st.generate_normals()
	var mesh := st.commit()

	# make mesh
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3.ZERO

# Apply material if set
	if terrain_material:
		mi.set_surface_override_material(0, terrain_material)

	# Collider (make disable for LOD)
	var shape := HeightMapShape3D.new()
	shape.map_width = end_x - start_x
	shape.map_depth = end_z - start_z

	var local_height := PackedFloat32Array()
	local_height.resize(shape.map_width * shape.map_depth)
	for z in range(shape.map_depth):
		for x in range(shape.map_width):
			local_height[z * shape.map_width + x] = height_data[(start_z + z) * terrain_width + (start_x + x)]

	shape.map_data = local_height

	var col := CollisionShape3D.new()
	col.shape = shape
	mi.add_child(col)
	
	# kill
	if Engine.is_editor_hint():
		ground_parent.add_child(mi)
		mi.owner = get_tree().edited_scene_root
	else:
		ground_parent.add_child(mi)

	return mi
