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

var noise = FastNoiseLite.new()  # FastNoiseLite instance

func _ready() -> void:
	SignalBus.health_signal.connect(spawn_blood)
	# Configure FastNoiseLite
	noise.seed = randi()
	noise.frequency = 0.01

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
