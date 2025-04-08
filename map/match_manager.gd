extends Node
class_name MatchManager

const INPUT_PARSER : Script = preload("res://character/input_parser.gd")
const GAME_DATA : Script = preload("res://data/GameData.gd")


@onready var character_scene : PackedScene = preload("res://character/character_model.tscn")
#var astar : AStarGrid2D
#var map : TileMapLayer = null
#var map_rect : Rect2i = Rect2i(Vector2i.ZERO, Vector2i.ZERO)
var player : CharacterBody2D
var character_data : Dictionary

func _ready() -> void:
	character_data = GAME_DATA.character_data.duplicate()
	player = character_scene.instantiate()
	player.base_health = character_data["base_health"]
	player.base_attack_cooldown = character_data["attack_cooldown"]
	player.base_attack_damage = character_data["attack_damage"]
	player.base_block_duration = character_data["block_duration"]
	player.base_block_cooldown = character_data["block_cooldown"]
	player.base_speed = character_data["speed"]
	player.base_move_cooldown = character_data["move_cooldown"]
	player.base_kick_stun_duration = character_data["kick_stun"]
	player.base_kick_cooldown = character_data["kick_cooldown"]
	add_child(player)
	player.add_to_group("knight")
	player.position = Vector2(54, 128)
	var player_controller = INPUT_PARSER.new()
	player_controller.player = player
	player.add_child(player_controller)
	var player_camera = Camera2D.new()
	player.add_child(player_camera)
	player_camera.make_current()
	player.character_sprite.sprite_frames = ResourceLoader.load("res://character/knight/knight_spriteframes.tres")
	#spawn_ai()
	set_physics_process(false)



func spawn_ai() -> void:
	var orc_ai = character_scene.instantiate()
	add_child(orc_ai)
	orc_ai.global_position = player.global_position + Vector2(512, 0)
	orc_ai.add_to_group("orc")
	orc_ai.add_to_group("ai")
	orc_ai.character_sprite.sprite_frames = ResourceLoader.load("res://character/orc/orc_spriteframes.tres")
	var knight_ai = character_scene.instantiate()
	add_child(knight_ai)
	knight_ai.global_position = player.global_position - Vector2(512, 0)
	knight_ai.add_to_group("knight")
	knight_ai.add_to_group("ai")
	knight_ai.character_sprite.sprite_frames = ResourceLoader.load("res://character/knight/knight_spriteframes.tres")
	#get_tree().create_timer(5.0).timeout.connect(spawn_ai)
	
func _physics_process(delta: float) -> void:
	for character in get_tree().get_nodes_in_group("ai"):
		if not is_instance_valid(character) or character.is_queued_for_deletion() or character.is_in_group("dead"):
			continue

		# Update facing direction based on target
		if character.has_target == false or not is_instance_valid(character.target) or character.target.is_in_group("dead"):
			var target = get_target(character)
			if target != null:
				character.has_target = true
				get_tree().create_timer(1.0).timeout.connect(character._on_target_timeout)
				character.target = target
				if character.stance_cooldown == false:
					character.update_ai_combat_stance()

		var distance_to_target = character.global_position.distance_to(character.target.global_position)
		var direction_to_target = (character.target.global_position - character.global_position)
		var speed = 30

		if character.weapon_on_cooldown == false and distance_to_target < 50:
			speed = 0
			character.attack()
			character.update_animations()
		elif abs(direction_to_target.x) > abs(direction_to_target.y):
			if character.velocity.x == 0 and character.direction_cooldown == false:
				character.start_direction_cooldown()
				character.velocity = Vector2(direction_to_target.x, 0).normalized()
				character.update_animations()
		else:
			if character.velocity.y == 0 and character.direction_cooldown == false:
				character.start_direction_cooldown()
				character.velocity = Vector2(0, direction_to_target.y).normalized()
				character.update_animations()
			character.velocity = Vector2(0, direction_to_target.y).normalized()

		character.global_position += character.velocity * speed * delta

func get_target(character: CharacterBody2D) -> CharacterBody2D:
	var nearest_target = null
	#if astar == null:
	#	print("Astar is null")
	#	SignalBus.emit_signal("request_astar")
	#	return nearest_target
	if character.is_in_group("orc"):
		var potential_targets = get_tree().get_nodes_in_group("knight")
		for target in potential_targets:
			if not target.is_queued_for_deletion():
				if nearest_target == null or character.position.distance_to(target.position) < character.position.distance_to(nearest_target.position):
					nearest_target = target
	elif character.is_in_group("knight"):
		var potential_targets = get_tree().get_nodes_in_group("orc")
		for target in potential_targets:
			if not target.is_queued_for_deletion():
				if nearest_target == null or character.position.distance_to(target.position) < character.position.distance_to(nearest_target.position):
					nearest_target = target
	return nearest_target

#func _on_pathfinding_update(_astar: AStarGrid2D, _ground_layer : TileMapLayer, _map_rect : Rect2i) -> void:
#	astar = _astar
#	update_diagonal_mode()
#	map = _ground_layer
#	map_rect = _map_rect
#	print(astar.diagonal_mode, "Astar updated", _astar.diagonal_mode)

#func _get_path(character: CharacterBody2D, target: CharacterBody2D) -> Array[Vector2i]:
#	if astar == null:
#		print("Astar is null")
#		return []
#	var path = astar.get_id_path(map.local_to_map(character.global_position), map.local_to_map(target.global_position)).slice(1)
#	return path

#func is_valid_path(pos) -> bool:
#	var map_position = map.local_to_map(pos)
#	if map_rect.has_point(map_position) and not astar.is_point_solid(map_position):
#		return true
#	return false

#func update_diagonal_mode() -> void:
#	if astar.diagonal_mode == AStarGrid2D.DIAGONAL_MODE_NEVER:
#		print("Diagonal mode is set to NEVER")
#		return
#	elif astar.diagonal_mode == AStarGrid2D.DIAGONAL_MODE_ALWAYS:
#		astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
#		print("Diagonal mode is changed to NEVER")
