extends Node
class_name MatchManager

const INPUT_PARSER : Script = preload("res://character/input_parser.gd")
const GAME_DATA : Script = preload("res://data/GameData.gd")


@onready var character_scene : PackedScene = preload("res://character/character_model.tscn")
var player : CharacterBody2D
var character_data : Dictionary

func _ready() -> void:
	character_data = GAME_DATA.character_data.duplicate()
	get_tree().create_timer(1.0).timeout.connect(spawn_player)
	#spawn_ai("knight")
	set_physics_process(false)


func spawn_player() -> void:
	player = character_scene.instantiate()
	set_data(player)
	player.is_player = true
	add_child(player)
	player.add_to_group("knight")
	player.global_position = get_valid_spawn()
	var player_controller = INPUT_PARSER.new()
	player_controller.player = player
	player.add_child(player_controller)
	var player_camera = Camera2D.new()
	player.add_child(player_camera)
	player_camera.make_current()
	player.character_sprite.sprite_frames = ResourceLoader.load("res://character/knight/knight_spriteframes.tres")
	spawn_ai("orc")

func set_data(character:CharacterBody2D) -> void:
	character.base_attack_cooldown = character_data["attack_cooldown"]
	character.base_attack_damage = character_data["attack_damage"]
	character.base_attack_speed = character_data["attack_speed"]
	character.base_block_duration = character_data["block_duration"]
	character.base_block_cooldown = character_data["block_cooldown"]
	character.base_health = character_data["base_health"]
	character.base_speed = character_data["speed"]
	character.base_move_cooldown = character_data["move_cooldown"]
	character.base_kick_stun_duration = character_data["kick_stun"]
	character.base_kick_cooldown = character_data["kick_cooldown"]

func spawn_ai(team:String) -> void:
	var character = character_scene.instantiate()
	set_data(character)
	character.team = team
	add_child(character)
	character.global_position = get_valid_spawn()
	character.add_to_group(team)
	character.add_to_group("ai")
	character.character_sprite.sprite_frames = ResourceLoader.load("res://character/" + team + "/" + team + "_spriteframes.tres")

func get_valid_spawn() -> Vector2:
	var spawn_pos : Vector2
	var spawn_area : Rect2 = get_viewport().get_visible_rect()
	var valid_spawn : bool = false
	while not valid_spawn:
		var _spawn_pos : Vector2
		_spawn_pos.x = randf_range(spawn_area.position.x - 500, spawn_area.end.x + 500)
		if _spawn_pos.x > spawn_area.position.x and _spawn_pos.x < spawn_area.end.x:
			continue
			#trying to spawn just outside the screen
		_spawn_pos.y = randf_range(spawn_area.position.y, spawn_area.end.y)
		spawn_pos = _spawn_pos.snapped(Vector2(128, 128))
		var collision_checker : RayCast2D = RayCast2D.new()
		collision_checker.global_position = spawn_pos
		collision_checker.target_position = Vector2(64,64)
		collision_checker.collide_with_areas = true
		collision_checker.collision_mask = 1
		collision_checker.hit_from_inside = true
		add_child(collision_checker)
		collision_checker.force_raycast_update()
		if collision_checker.is_colliding():
			collision_checker.queue_free()
			print("Collision detected at: ", spawn_pos)
			continue
		
		else:
			collision_checker.queue_free()
			print("No collision at: ", spawn_pos)
			valid_spawn = true
	return spawn_pos

#TODO AI turn, move, attack, block, kick	
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
				#if character.stance_cooldown == false:
				#	character.update_ai_combat_stance()

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
