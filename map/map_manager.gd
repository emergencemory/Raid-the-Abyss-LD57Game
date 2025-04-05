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

#TODO spawn shadows
#TODO spawn chunks