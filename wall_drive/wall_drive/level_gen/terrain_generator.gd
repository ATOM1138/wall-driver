@tool
extends Node
class_name TerrainGenerator

@export_tool_button("Generate Terrain") var ter_gen = generate_terrain
@export_tool_button("Wipe Terrain") var ter_wipe = wipe_terrain
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
	
	var height_data := PackedFloat32Array()
	for z in range(terrain_width):
		for x in range(terrain_length):
			height_data.append(noise.get_noise_2d(x, z) * terrain_height)
	
	var mesh := PlaneMesh.new()
	mesh.size = Vector2i(terrain_width - 1, terrain_length - 1)
	mesh.subdivide_width = terrain_width - 2
	mesh.subdivide_depth = terrain_length - 2
	
	var mesh_arrays := mesh.surface_get_arrays(0)
	for vertex_i in len(mesh_arrays[Mesh.ARRAY_VERTEX]):
		var vertex : Vector3 = mesh_arrays[Mesh.ARRAY_VERTEX][vertex_i]
		vertex += Vector3(terrain_width / 2.0, 0, terrain_length / 2.0)
		vertex.y = height_data[(int(vertex.z) * terrain_width) + int(vertex.x)]
		vertex -= Vector3(0.5, 0, 0.5)
		
		mesh_arrays[Mesh.ARRAY_VERTEX][vertex_i] = vertex
	
	var array_mesh := ArrayMesh.new()
	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	# Calc normals
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(array_mesh, 0)
	for vert in range(mdt.get_vertex_count()):
		var normal := Vector3.ZERO
		for face in mdt.get_vertex_faces(vert):
			normal += mdt.get_face_normal(face)
		
		mdt.set_vertex_normal(vert, normal)
	
	array_mesh.clear_surfaces()
	mdt.commit_to_surface(array_mesh)
	ground_mesh.mesh = array_mesh
	
	var shape := HeightMapShape3D.new()
	
	shape.map_width = terrain_width
	shape.map_depth = terrain_length
	shape.map_data = height_data
	
	ground_collider.shape = shape
	ground_collider.position = Vector3(terrain_width / 2.0, 0, terrain_length / 2.0) - Vector3(0.5, 0, 0.5)
	
	print(Time.get_unix_time_from_system() - start_time)
