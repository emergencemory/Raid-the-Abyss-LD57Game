extends Node2D
class_name MapManager

@onready var wall_layer: TileMapLayer = $WallLayer
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var cliff_layer: TileMapLayer = $CliffLayer
@onready var splat_1: Texture = preload("res://map/effects/blood_1.png")
@onready var splat_2: Texture = preload("res://map/effects/blood_2.png")
@onready var splat_3: Texture = preload("res://map/effects/blood_3.png")
@onready var blood_pool: Texture = preload("res://character/effects/blood.png")

#TODO spawn shadows
#TODO spawn chunks

var chunk_size: int = 16  # Number of tiles per chunk (e.g., 16x16 tiles)
var tile_size: int = 128  # Size of each tile in pixels
var render_distance: int = 3  # Number of chunks to load around the player
var loaded_chunks: Dictionary = {}  # Dictionary to track loaded chunks
var noise : FastNoiseLite   # FastNoiseLite instance
var player : CharacterBody2D

func _ready() -> void:
	SignalBus.health_signal.connect(spawn_blood)
	SignalBus.player_move.connect(generate_chunk)
	# Configure FastNoiseLite
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = .3

func spawn_blood(value: int, _base_value: int, character: CharacterBody2D) -> void:
	# Spawn blood effect at the player's position
	if value == _base_value:
		return
	var blood_effect :Sprite2D = Sprite2D.new()
	blood_effect.global_position = character.global_position + Vector2(randf_range(24, 84), randf_range(-30, 30)) 
	blood_effect.scale = Vector2(randf_range(0.5, 1.5), randf_range(0.5, 1.5))
	blood_effect.rotation_degrees = randf_range(0, 360)
	blood_effect.self_modulate = Color(0.5, 0.5, 0.5, 0.8)
	add_child(blood_effect)
	if value > 0:
		var roll = randi_range(0,2)
		match roll:
			0:
				blood_effect.texture = splat_1
			1:
				blood_effect.texture = splat_2
			2:
				blood_effect.texture = splat_3
	else:
		blood_effect.texture = blood_pool
	var tween = create_tween()
	tween.tween_property(blood_effect, "scale", Vector2(9,9), 20.0)

#TODO this doesnt work
func unload_chunks(player_position: Vector2) -> void:
	var cliff_tiles = cliff_layer.get_used_cells()
	var wall_tiles = wall_layer.get_used_cells()
	var ground_tiles = ground_layer.get_used_cells()
	for tile in cliff_tiles:
		if abs(tile.x - player_position.x) >= 1000 or abs(tile.y - player_position.y) >= 1000:
			# Unload the chunk if it's outside the render distance
			cliff_layer.erase_cell(tile)
	for tile in wall_tiles:
		if abs(tile.x - player_position.x) >= 1000 or abs(tile.y - player_position.y) >= 1000:
			# Unload the chunk if it's outside the render distance
			wall_layer.erase_cell(tile)
	for tile in ground_tiles:
		if abs(tile.x - player_position.x) >= 1000 or abs(tile.y - player_position.y) >= 1000:
			# Unload the chunk if it's outside the render distance
			ground_layer.erase_cell(tile)


func generate_chunk(chunk_position: Vector2) -> void:
	# Generate terrain for the chunk
	var tile_pos = wall_layer.local_to_map(chunk_position)
	for y in range(chunk_size):
		for x in range(chunk_size):
			var world_x = tile_pos.x - (chunk_size / 2) + x
			print("world_x: ", world_x)
			var world_y = tile_pos.y - (chunk_size / 2) + y
			print("world_y: ", world_y)
			if wall_layer.get_cell_source_id(Vector2i(world_x, world_y)) != -1:
				continue
			if cliff_layer.get_cell_source_id(Vector2i(world_x, world_y)) != -1:
				continue
			if ground_layer.get_cell_source_id(Vector2i(world_x, world_y)) != -1:
				continue
			if y >= 6 and y <= 10:
				ground_layer.set_cell(Vector2i(world_x, world_y), 0, Vector2i(0,0))
				continue
			var value = noise.get_noise_2d(world_x, world_y)*10
			print(value)
			if value > 1.5:
				wall_layer.set_cell(Vector2i(world_x, world_y), 0, Vector2i(0,0))
	#tile_pos = cliff_layer.local_to_map(chunk_position)
	
			if value < -1.5:
				cliff_layer.set_cell(Vector2i(world_x, world_y), 0, Vector2i(0,0))
	#tile_pos = ground_layer.local_to_map(chunk_position)

			else:
				ground_layer.set_cell(Vector2i(world_x, world_y), 0, Vector2i(0,0))
	#!unload_chunks(chunk_position)
