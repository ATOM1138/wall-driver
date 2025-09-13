extends Resource
class_name TerrainModifer

@export var modify_map : Texture2D
## Height relative to scene origin
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var height : float
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var offset : Vector2
