#OBSOLETE :thumbsupp:

@tool
extends Node
class_name TerrainGenerator_at

@export_tool_button("Generate Terrain") var ter_gen := Callable(self, "generate_terrain")
@export_tool_button("Wipe Terrain") var ter_wipe := Callable(self, "wipe_terrain")
@export var noise : FastNoiseLite

@export var ground_mesh : MeshInstance3D
@export var ground_collider : CollisionShape3D

@export var terrain_width : int = 1024
@export var terrain_length : int = 2048
@export var terrain_height : float


func _ready() -> void:
	await generate_terrain()


func wipe_terrain():
	ground_mesh.mesh = null
	ground_collider.shape = null


func generate_terrain():
	var start_time = Time.get_unix_time_from_system()

# generate noise in one go
	var img := noise.get_image(terrain_width, terrain_length, false, false, true)
	var height_data := PackedFloat32Array()
	height_data.resize(terrain_width * terrain_length)
	
	for z in range(terrain_length):
		for x in range(terrain_width):
			# pixel value is in [0..1], scale to height
			height_data[z * terrain_width + x] = img.get_pixel(x, z).r * terrain_height


	# make mesh 
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(terrain_length - 1):
		for x in range(terrain_width - 1):
			var h1 = height_data[z * terrain_width + x]
			var h2 = height_data[z * terrain_width + x + 1]
			var h3 = height_data[(z + 1) * terrain_width + x]
			var h4 = height_data[(z + 1) * terrain_width + x + 1]

			var v1 = Vector3(x,     h1, z)
			var v2 = Vector3(x + 1, h2, z)
			var v3 = Vector3(x,     h3, z + 1)
			var v4 = Vector3(x + 1, h4, z + 1)

			# 1 triangle
			st.add_vertex(v1)
			st.add_vertex(v2)
			st.add_vertex(v3)

			# 2 triangle
			st.add_vertex(v2)
			st.add_vertex(v4)
			st.add_vertex(v3)

	# Generate normals in c++ 
	st.generate_normals()

	var array_mesh := st.commit()
	ground_mesh.mesh = array_mesh


	# colider
	var shape := HeightMapShape3D.new()
	shape.map_width = terrain_width
	shape.map_depth = terrain_length
	shape.map_data = height_data

	ground_collider.shape = shape
	ground_collider.position = Vector3(terrain_width / 2.0, 0, terrain_length / 2.0)

	print("Terrain generated in: ", Time.get_unix_time_from_system() - start_time, "s")
