@tool
extends EditorPlugin

var button_generate: Button
var button_wipe: Button

func _enter_tree():
	# Create Generate button
	button_generate = Button.new()
	button_generate.text = "Generate Terrain"
	button_generate.pressed.connect(_on_generate_pressed)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, button_generate)

	# Create Wipe button
	button_wipe = Button.new()
	button_wipe.text = "Wipe Terrain"
	button_wipe.pressed.connect(_on_wipe_pressed)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, button_wipe)

func _exit_tree():
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, button_generate)
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, button_wipe)
	button_generate = null
	button_wipe = null

func _get_selected_terrain() -> TerrainGenerator:
	var selected = get_editor_interface().get_selection().get_selected_nodes()
	for node in selected:
		if node is TerrainGenerator:
			return node
	return null

func _on_generate_pressed():
	var terrain = _get_selected_terrain()
	if terrain:
		terrain.generate_terrain()
	else:
		printerr("Select a TerrainGenerator node first.")

func _on_wipe_pressed():
	var terrain = _get_selected_terrain()
	if terrain:
		terrain.wipe_terrain()
	else:
		printerr("Select a TerrainGenerator node first.")
