@tool
extends Resource
class_name ItemGrid


## Size of this grid before subtractions
@export var size : Vector3i
## Offset used when this grid is subtracted from another
@export var offset : Vector3i
## Grids to be subtracted from this one
@export var subtractions : Array[ItemGrid]

@export_tool_button("Construct Grid") var construct_grid_action = construct_grid

var grid : Array[Array] = []


func construct_grid():
	init_matrix()
	
	subtract_grids()
	
	print_grid()


func init_matrix():
	grid.resize(size.x)
	
	for x in size.x:
		grid[x] = []
		grid[x].resize(size.y)
		
		for y in size.y:
			grid[x][y] = []
			grid[x][y].resize(size.z)
			
			for z in size.z:
				grid[x][y][z] = true


func subtract_grids():
	for sub_grid in subtractions:
		pass


func print_grid():
	var grid_string : String = ""
	
	for y in size.y:
		grid_string += "%s\n" % y
		for z in size.z:
			for x in size.x:
				match grid[x][y][z]:
					true:
						grid_string += "X"
					false:
						grid_string += " "
			grid_string += "\n"
		grid_string += "\n"
	print(grid_string)
