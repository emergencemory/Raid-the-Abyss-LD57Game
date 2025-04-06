extends Node2D
class_name MapManager

@onready var right_cliff_lower_layer: TileMapLayer = $RightCliffLowerLayer
@onready var right_cliff_mid_layer: TileMapLayer = $RightCliffMidLayer
@onready var right_cliff_upper_layer: TileMapLayer = $RightCliffUpperLayer
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var shadow_layer: TileMapLayer = $ShadowLayer
@onready var details_layer: TileMapLayer = $DetailsLayer
@onready var props_layer: TileMapLayer = $PropsLayer
@onready var left_wall_layer: TileMapLayer = $LeftWallLayer
@onready var high_left_wall_layer: TileMapLayer = $HighLeftWallLayer
@onready var high_left_wall_layer_2: TileMapLayer = $HighLeftWallLayer2
var astar := AStarGrid2D.new()

#TODO spawn shadows
#TODO spawn chunks

func _ready() -> void:
	var start_rect = ground_layer.get_used_rect()
	var tile_size = ground_layer.get_tileset().tile_size
	astar.region = start_rect
	astar.cell_size = tile_size
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	for child in get_children():
		if child is TileMapLayer:

			for i in start_rect.x:
				for j in start_rect.y:
					var tile_coords = Vector2i(i, j)
					var tile_data = child.get_cell_data(tile_coords)
					if tile_data and tile_data.get_custom_data("wall") == true:
						astar.set_point_solid(tile_coords)