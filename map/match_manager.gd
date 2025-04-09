extends Node
class_name MatchManager

const INPUT_PARSER : Script = preload("res://character/input_parser.gd")
const GAME_DATA : Script = preload("res://data/GameData.gd")


@onready var character_scene : PackedScene = preload("res://character/character_model.tscn")
var player : CharacterBody2D
var hud_scene : PackedScene = preload("res://ui/hud.tscn")
var character_data : Dictionary
var layer : int = 1
var current_orcs : int = 0
var current_knights : int = 0
var enemy_deaths : int = 0
var knight_deaths : int = 0
var your_deaths : int = -1
var knight_kills : int = 0
var your_kills : int = 0
var hud : CanvasLayer
var player_controller : INPUT_PARSER

signal update_player_hud(layer, current_orcs, your_kills, your_deaths, current_knights, knight_kills, knight_deaths)

func _ready() -> void:
	character_data = GAME_DATA.character_data.duplicate()
	player_controller = INPUT_PARSER.new()
	player_controller.name = "InputParser"
	add_child(player_controller)
	hud = hud_scene.instantiate()
	update_player_hud.connect(hud._on_update_player_hud)
	player_controller.add_child(hud)
	SignalBus.health_signal.connect(hud._on_health_changed)
	get_tree().create_timer(1.0).timeout.connect(spawn_player)

func spawn_player() -> void:
	player = character_scene.instantiate()
	set_data(player)
	player.is_player = true
	add_child(player)
	player.add_to_group("knight")
	player.team = "knight"
	player.global_position = get_valid_spawn(player)
	player_controller.player = player
	player.attack_signal.connect(hud._on_attack_cooldown_started)
	player.block_signal.connect(hud._on_block_cooldown_started)
	player.move_signal.connect(hud._on_move_cooldown_started)
	player.kick_signal.connect(hud._on_kick_cooldown_started)
	player.killed_by_knight.connect(_on_knight_kill)
	player.killed_by_orc.connect(_on_orc_kill)
	player.killed_by_player.connect(_on_player_kill)
	var player_camera = Camera2D.new()
	player_camera.position_smoothing_enabled = true
	player.add_child(player_camera)
	your_deaths += 1
	update_hud()
	player_camera.make_current()
	player.character_sprite.sprite_frames = ResourceLoader.load("res://character/knight/knight_spriteframes.tres")
	spawn_ai("orc")
	spawn_ai("knight")

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
	character.base_health_regen = character_data["health_regen"]

func spawn_ai(team:String) -> void:
	var character = character_scene.instantiate()
	set_data(character)
	character.team = team
	character.killed_by_knight.connect(_on_knight_kill)
	character.killed_by_orc.connect(_on_orc_kill)
	character.killed_by_player.connect(_on_player_kill)
	add_child(character)
	character.add_to_group(team)
	character.global_position = get_valid_spawn(character)
	character.add_to_group("ai")
	character.character_sprite.sprite_frames = ResourceLoader.load("res://character/" + team + "/" + team + "_spriteframes.tres")
	if team == "orc":
		character.block_right_sprite.texture = ResourceLoader.load("res://ui/round_shield_icon.png")
		character.block_left_sprite.texture = ResourceLoader.load("res://ui/round_shield_icon.png")
		character.attack_from_right_sprite.texture = ResourceLoader.load("res://ui/axe_icon.png")
		character.attack_from_left_sprite.texture = ResourceLoader.load("res://ui/axe_icon.png")
		current_orcs += 1
	if team == "knight":
		current_knights += 1
	update_hud()

func get_valid_spawn(character : CharacterBody2D) -> Vector2:
	var spawn_pos : Vector2
	var spawn_area : Rect2 = player.get_viewport().get_visible_rect()
	var valid_spawn : bool = false
	var team : String
	if character.is_in_group("orc"):
		team = "orc"
	elif character.is_in_group("knight"):
		team = "knight"
	else:
		printerr("Invalid team for character: ", character.name)
		return Vector2.ZERO
	while not valid_spawn:
		var _spawn_pos : Vector2
		if character.is_player:
			# Spawn in the centerish of the screen
			_spawn_pos.x = randf_range(spawn_area.position.x, (spawn_area.end.x)/2)  + (256*(layer -1))
		elif team == "knight":
			# Spawn on the left side of the screen
			_spawn_pos.x = randf_range(spawn_area.position.x - 256, spawn_area.position.x) + (256*(layer-1))
		else: # orc
			# Spawn on the right side of the screen
			_spawn_pos.x = randf_range(spawn_area.end.x, spawn_area.end.x + 256)  + (256*(layer-1))
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
			#print("Collision detected at: ", spawn_pos)
			continue
		
		else:
			collision_checker.queue_free()
			#print("No collision at: ", spawn_pos)
			valid_spawn = true
	return spawn_pos


func _physics_process(delta: float) -> void:
	if current_orcs <= 1 and player != null:
		layer += 1
		for i in layer:
			spawn_ai("orc")
		update_hud()
	if current_knights <= 1 and player != null:	
		for i in layer:
			spawn_ai("knight")
		update_hud()

	for character in get_tree().get_nodes_in_group("ai"):
		if not is_instance_valid(character) or character.is_queued_for_deletion() or character.is_in_group("dead"):
			continue
		elif character.has_target == false or not is_instance_valid(character.target) or character.target.is_in_group("dead"):
			var target = get_target(character) # this spawns new waves too
			if target != null:
				character.has_target = true
				character.cooldown_time_target = 1.0
				character.set_physics_process(true)
				character.target = target
		else:
			character.order_ticks -= delta
			if character.order_ticks > 0:
				continue
			else:
				ai_action(character)

func ai_action(character: CharacterBody2D) -> void:
	character.order_ticks = 0.5
	var coin_flip = randi_range(0, 4)
	character.ray_cast_2d.force_raycast_update()
	if character.ray_cast_2d.is_colliding() and character.ray_cast_2d.get_collider() == character.target:
			if coin_flip == 0: 
				if character.is_preparing_attack == false:
					character.swing_from_right = true
					character.prepare_attack()
				else:
					character.attack()
			elif coin_flip == 1:
				if character.is_preparing_attack == false:
					character.swing_from_right = false
					character.prepare_attack()
				else:
					character.attack()
			elif coin_flip == 2:
				character.block_to_right = true
				character.block()
			elif coin_flip == 3:
				character.block_to_right = false
				character.block()
			else:
				character.kick()
	elif character.target.global_position.x < character.global_position.x:
		if coin_flip == 0 or coin_flip == 1:
			if character.facing_direction == character.DIR.WEST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.WEST)
		elif coin_flip == 2:
			if character.facing_direction == character.DIR.NORTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.NORTH)
		elif coin_flip == 3:
			if character.facing_direction == character.DIR.SOUTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.SOUTH)
		else:
			if character.facing_direction == character.DIR.EAST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.EAST)
	elif character.target.global_position.x > character.global_position.x:
		if coin_flip == 0 or coin_flip == 1:
			if character.facing_direction == character.DIR.EAST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.EAST)
		elif coin_flip == 2:
			if character.facing_direction == character.DIR.NORTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.NORTH)
		elif coin_flip == 3:
			if character.facing_direction == character.DIR.SOUTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.SOUTH)
		else:
			if character.facing_direction == character.DIR.WEST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.WEST)
	elif character.target.global_position.y < character.global_position.y:
		if coin_flip == 0 or coin_flip == 1:
			if character.facing_direction == character.DIR.NORTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.NORTH)
		elif coin_flip == 2:
			if character.facing_direction == character.DIR.EAST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.EAST)
		elif coin_flip == 3:
			if character.facing_direction == character.DIR.WEST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.WEST)
		else:
			if character.facing_direction == character.DIR.SOUTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.SOUTH)
	elif character.target.global_position.y > character.global_position.y:
		if coin_flip == 0 or coin_flip == 1:
			character.turn(character.DIR.SOUTH)
			if character.facing_direction == character.DIR.SOUTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.SOUTH)
		elif coin_flip == 2:
			if character.facing_direction == character.DIR.EAST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.EAST)
		elif coin_flip == 3:
			if character.facing_direction == character.DIR.WEST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.WEST)
		else:
			if character.facing_direction == character.DIR.NORTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.NORTH)


		



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

func _on_knight_kill(team: String) -> void:
	if team == "orc":
		current_orcs -= 1
		knight_kills += 1
	elif team == "knight":
		current_knights -= 1
	update_hud()

func _on_orc_kill(team: String) -> void:
	if team == "knight":
		current_knights -= 1
		knight_deaths += 1
	elif team == "orc":
		current_orcs -= 1
	update_hud()

func _on_player_kill(team: String) -> void:
	if team == "orc":
		current_orcs -= 1
		your_kills += 1
	elif team == "knight":
		current_knights -= 1
	update_hud()


func update_hud() -> void:
	emit_signal("update_player_hud", layer, current_orcs, your_kills, your_deaths, current_knights, knight_kills, knight_deaths)
