extends Node
class_name MatchManager

const INPUT_PARSER : Script = preload("res://character/input_parser.gd")

@onready var character_scene : PackedScene = preload("res://character/character_model.tscn")
#var astar : AStarGrid2D
#var map : TileMapLayer = null
#var map_rect : Rect2i = Rect2i(Vector2i.ZERO, Vector2i.ZERO)

func _ready() -> void:
	var player = character_scene.instantiate()
	add_child(player)
	player.add_to_group("knight")
	player.position = Vector2(500, 500)
	var player_controller = INPUT_PARSER.new()
	player_controller.player = player
	player.add_child(player_controller)
	var player_camera = Camera2D.new()
	player.add_child(player_camera)
	player_camera.make_current()
	player.character_sprite.sprite_frames = ResourceLoader.load("res://character/knight/knight_spriteframes.tres")
	player.weapon_sprite.sprite_frames = ResourceLoader.load("res://equipment/sword/sword_spriteframes.tres")
	player.shield_sprite.sprite_frames = ResourceLoader.load("res://equipment/kite_shield/kite_shield_spriteframes.tres")
	get_tree().create_timer(5.0).timeout.connect(spawn_ai)
#	SignalBus.pathfinding_update.connect(_on_pathfinding_update)

func spawn_ai() -> void:
	var orc_ai = character_scene.instantiate()
	add_child(orc_ai)
	orc_ai.position = Vector2(randi_range(0, 500), randi_range(0, 500))
	orc_ai.add_to_group("orc")
	orc_ai.add_to_group("ai")
	orc_ai.character_sprite.sprite_frames = ResourceLoader.load("res://character/orc/orc_spriteframes.tres")
	orc_ai.weapon_sprite.sprite_frames = ResourceLoader.load("res://equipment/axe/axe_spriteframes.tres")
	orc_ai.shield_sprite.sprite_frames = ResourceLoader.load("res://equipment/round_shield/round_shield_spriteframes.tres")
	var knight_ai = character_scene.instantiate()
	add_child(knight_ai)
	knight_ai.position = Vector2(randi_range(0, 500), randi_range(0, 500))
	knight_ai.add_to_group("knight")
	knight_ai.add_to_group("ai")
	knight_ai.character_sprite.sprite_frames = ResourceLoader.load("res://character/knight/knight_spriteframes.tres")
	knight_ai.weapon_sprite.sprite_frames = ResourceLoader.load("res://equipment/sword/sword_spriteframes.tres")
	knight_ai.shield_sprite.sprite_frames = ResourceLoader.load("res://equipment/kite_shield/kite_shield_spriteframes.tres")
	get_tree().create_timer(5.0).timeout.connect(spawn_ai)
	
func _physics_process(delta: float) -> void:
	for character in get_tree().get_nodes_in_group("ai"):
		if not character.is_queued_for_deletion():
			if character.has_target == false or character.target.is_in_group("dead"):
				var target = get_target(character)
				if target != null:
					character.has_target = true
					character.start_target_cooldown()
					character.target = target
					if character.stance_cooldown == false:
						character.combat_stance()
					#character.current_path = _get_path(character, target)
				#if character.position.distance_to(target.position) > 50:
				#	character.velocity = (target.position - character.position).normalized() * 15
				#	character.position += character.velocity * delta
				#	character.move_and_slide()
			var distance_to_target = character.global_position.distance_to(character.target.global_position)
			var direction_to_target = (character.target.global_position - character.global_position)
			var speed = 30
			#print("Distance to target: ", distance_to_target)
			if character.weapon_on_cooldown == false and distance_to_target < 50:
				speed = 0
				character.attack(character.target)
				character.apply_animation()
			elif direction_to_target.x > direction_to_target.y:# character.current_path.size() > 0:
				#var target_position = map.map_to_local(character.current_path.front())
				if character.velocity.x == 0 and character.direction_cooldown == false:
					character.start_direction_cooldown()
					character.velocity = Vector2(direction_to_target.x, 0).normalized()
					character.apply_animation()	
			else:
				if character.velocity.y == 0 and character.direction_cooldown == false:
					character.start_direction_cooldown()
					character.velocity = Vector2(0, direction_to_target.y).normalized()
					character.apply_animation()
				character.velocity = Vector2(0, direction_to_target.y).normalized()	
			
			character.global_position += character.velocity * speed * delta
			character.move_and_slide()


				#if character.global_position == target_position:
				#	character.current_path.pop_front()
		else:
			print("Invalid character instance.")

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
