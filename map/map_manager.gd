extends Node2D
class_name MapManager

@onready var wall_layer: TileMapLayer = $WallLayer
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var cliff_layer: TileMapLayer = $CliffLayer

#TODO spawn shadows
#TODO spawn chunks

#func _ready() -> void:
	#SignalBus.request_astar.connect(_on_request_astar)
	#_on_request_astar()

#func _on_request_astar() -> void:
#	var astar := AStarGrid2D.new()
#	var tilemap_size = ground_layer.get_used_rect().end - ground_layer.get_used_rect().position
#	var start_rect = Rect2i(Vector2i.ZERO, tilemap_size)
#	var tile_size = ground_layer.tile_set.tile_size
#	astar.region = start_rect
#	astar.cell_size = tile_size
#	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
#	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
#	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
#	astar.update()
#	
#	
#	for child in get_children():
#		if child is TileMapLayer:
#
#			for i in tilemap_size.x:
#				for j in tile_size.y:
#					var tile_coords = Vector2i(i, j)
#					var tile_data = child.get_cell_tile_data(tile_coords)
#					if tile_data and tile_data.get_custom_data("wall") == true:
#						astar.set_point_solid(tile_coords)
#	
#	SignalBus.emit_signal("pathfinding_update", astar, ground_layer, start_rect)
#	print("Astar updated")
