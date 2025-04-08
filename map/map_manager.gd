extends Node2D
class_name MapManager

@onready var wall_layer: TileMapLayer = $WallLayer
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var cliff_layer: TileMapLayer = $CliffLayer

#TODO spawn shadows
#TODO spawn chunks

var chunk_size: int = 16  # Number of tiles per chunk (e.g., 16x16 tiles)
var tile_size: int = 128  # Size of each tile in pixels
var render_distance: int = 3  # Number of chunks to load around the player
var loaded_chunks: Dictionary = {}  # Dictionary to track loaded chunks

var noise = FastNoiseLite.new()  # FastNoiseLite instance

func _ready() -> void:
	# Configure FastNoiseLite
	noise.seed = randi()
	noise.frequency = 0.01

func update_chunks(player_position: Vector2) -> void:
	# Calculate the player's current chunk position
	var player_chunk = Vector2(
		floor(player_position.x / (chunk_size * tile_size)),
		floor(player_position.y / (chunk_size * tile_size))
	)

	# Load chunks within the render distance
	for x in range(player_chunk.x - render_distance, player_chunk.x + render_distance + 1):
		for y in range(player_chunk.y - render_distance, player_chunk.y + render_distance + 1):
			var chunk_position = Vector2(x, y)
			if not loaded_chunks.has(chunk_position):
				generate_chunk(chunk_position)

	# Unload chunks outside the render distance
	#for chunk_position in loaded_chunks.keys():
		#if chunk_position.distance_to(player_chunk) > render_distance:
		#	unload_chunk(chunk_position)

func generate_chunk(chunk_position: Vector2) -> void:
	# Generate terrain for the chunk
	var chunk_origin = chunk_position * chunk_size * tile_size
	for x in range(chunk_size):
		for y in range(chunk_size):
			var world_position = chunk_origin + Vector2(x * tile_size, y * tile_size)
			var noise_value = noise.get_noise_2d(world_position.x, world_position.y)
			
			var source_id = 0  # Tile ID for the wall layer
			var atlas_coords = Vector2i(0, 0)  # Atlas coordinates for the wall layer
			# Map noise values to layers
			if noise_value > 0.5:
				wall_layer.set_cell(world_position, source_id, atlas_coords)  # Wall tile
			elif noise_value > -0.5:
				ground_layer.set_cell(world_position, source_id, atlas_coords)  # Ground tile
			else:
				cliff_layer.set_cell(world_position, source_id, atlas_coords)  # Cliff tile

	# Mark the chunk as loaded
	loaded_chunks[chunk_position] = true

#func unload_chunk(chunk_position: Vector2) -> void:
	# Clear tiles in the chunk
#	for x in range(chunk_size):
#		for y in range(chunk_size):
#			wall_layer.set_cell(x + chunk_position.x * chunk_size, y + chunk_position.y * chunk_size, -1)  # Clear wall tile
#			ground_layer.set_cell(x + chunk_position.x * chunk_size, y + chunk_position.y * chunk_size, -1)  # Clear ground tile
#			cliff_layer.set_cell(x + chunk_position.x * chunk_size, y + chunk_position.y * chunk_size, -1)  # Clear cliff tile
#
#	# Remove the chunk from the loaded chunks dictionary
#	loaded_chunks.erase(chunk_position)
