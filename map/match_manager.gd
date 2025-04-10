extends Node
class_name MatchManager

const INPUT_PARSER : Script = preload("res://character/input_parser.gd")
const GAME_DATA : Script = preload("res://data/GameData.gd")


@onready var character_scene : PackedScene = preload("res://character/character_model.tscn")
#@onready var orc_spriteframes : SpriteFrames = preload("res://character/orc/orc_spriteframes.tres")
@onready var knight_spriteframes : SpriteFrames = preload("res://character/knight/knight_spriteframes.tres")
#@onready var round_shield_icon : Texture= preload("res://ui/round_shield_icon.png")
#@onready var axe_icon : Texture = preload("res://ui/axe_icon.png")
@onready var kite_shield_icon : Texture = preload("res://ui/kite_shield_icon_2.png")
@onready var sword_icon : Texture = preload("res://ui/sword_icon_2.png")
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
var spawn_center : Vector2 = Vector2(0,0)

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
	SignalBus.request_reinforcements.connect(spawn_ai)
	SignalBus.console_kill_ai.connect(_on_console_kill_ai)
	SignalBus.player_move.connect(update_spawn_area)
	get_tree().create_timer(1.0).timeout.connect(spawn_player)

func _on_console_kill_ai() -> void:
	for character in get_tree().get_nodes_in_group("ai"):
		if character != null and not character.is_queued_for_deletion():
			print("Killing AI: ", character.name)
			if character.is_in_group("orc"):
				current_orcs -= 1
			elif character.is_in_group("knight"):
				current_knights -= 1
			character.queue_free()
		else:
			print("Invalid character for deletion")
	
	update_hud()

func update_spawn_area(player_pos : Vector2) -> void:
	spawn_center = player_pos

func spawn_player() -> void:
	player = character_scene.instantiate()
	set_data(player)
	player.is_player = true
	add_child(player)
	player.add_to_group("knight")
	player.team = "knight"
	player.global_position = await(get_valid_spawn(player.team))
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
	player.player_camera = player_camera
	player.add_child(player_camera)
	your_deaths += 1
	update_hud()
	player_camera.make_current()
	player.character_sprite.sprite_frames = knight_spriteframes
	player.shadow_sprite.sprite_frames = knight_spriteframes
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
	character.current_xp = character_data["base_xp"]
	character.current_xp_to_next_level = character_data["base_xp_to_next_level"]
	character.base_xp_to_next_level_multiplier = character_data["base_xp_to_next_level_multiplier"]
	character.current_level = character_data["base_level"]
	character.level_up_multiplier = character_data["level_up_multiplier"]
	character.level_up_addition = character_data["level_up_addition"]

func spawn_ai(team:String) -> void:
	var character = character_scene.instantiate()
	set_data(character)
	character.team = team
	character.killed_by_knight.connect(_on_knight_kill)
	character.killed_by_orc.connect(_on_orc_kill)
	character.killed_by_player.connect(_on_player_kill)
	add_child(character)
	character.add_to_group(team)
	character.position = await(get_valid_spawn(character.team))
	character.add_to_group("ai")
	if team == "orc":
	#	character.character_sprite.sprite_frames = orc_spriteframes
	#	character.shadow_sprite.sprite_frames = orc_spriteframes
	#	character.block_right_sprite.texture = round_shield_icon
	#	character.block_left_sprite.texture = round_shield_icon
	#	character.attack_from_right_sprite.texture = axe_icon
	#	character.attack_from_left_sprite.texture = axe_icon
		current_orcs += 1
	if team == "knight":
		character.character_sprite.sprite_frames = knight_spriteframes
		character.shadow_sprite.sprite_frames = knight_spriteframes
		character.block_right_sprite.texture = kite_shield_icon
		character.block_left_sprite.texture = kite_shield_icon
		character.attack_from_right_sprite.texture = sword_icon
		character.attack_from_left_sprite.texture = sword_icon
		current_knights += 1
	for i in (randi_range(0, layer)):
		character.level_up()
	update_hud()



func get_valid_spawn(team:String) -> Vector2:
	var spawn_pos : Vector2
	#var spawn_area : Rect2 = player.get_viewport().get_visible_rect()
	var valid_spawn : bool = false
	#var team : String
	var attempts : int = 0
	var max_attempts : int = 50
	while not valid_spawn and attempts < max_attempts:
		attempts += 1
		#var _spawn_pos : Vector2
		#if character.is_player:
			# Spawn in the centerish of the screen
			#_spawn_pos.x = randf_range(spawn_area.position.x, (spawn_area.end.x)/2)  + (256*(layer -1))
		if team == "knight":
			# Spawn on the left side of the screen
			spawn_pos.x = randf_range(spawn_center.x - 1028, spawn_center.x - 256) #+ (256*(layer-1))
		else: # orc
			# Spawn on the right side of the screen
			spawn_pos.x = randf_range(spawn_center.x + 768, spawn_center.x + 1540)  #+ (256*(layer-1))
		spawn_pos.y = randf_range(spawn_center.y - 256, spawn_center.y + 256)
		spawn_pos = spawn_pos.snapped(Vector2(128, 128))
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
			await(get_tree().physics_frame)
			continue
		else:
			collision_checker.queue_free()
			valid_spawn = true
	if not valid_spawn:
		print("Failed to find a valid spawn position after ", max_attempts, " attempts.")
		#spawn_pos = spawn_center
		#return spawn_pos
	return spawn_pos


func _physics_process(delta: float) -> void:
	if current_orcs <= 1 and player != null:
		layer += 1
		spawn_wave("orc")

	if current_knights <= 1 and player != null:	
		spawn_wave("knight")


	for character in get_tree().get_nodes_in_group("ai"):
		if not is_instance_valid(character) or character.is_queued_for_deletion() or character.is_in_group("dead"):
			continue
		elif character.has_target == false or not is_instance_valid(character.target) or character.target.is_in_group("dead"):
			var target = get_target(character)
			if target != null:
				character.has_target = true
				character.cooldown_time_target = 1.0
				#character.set_physics_process(true)
				character.target = target
		else:
			character.order_ticks -= delta
			if character.order_ticks > 0:
				continue
			else:
				ai_action(character)

func spawn_wave(team:String) -> void:
	for i in range(layer):
		spawn_ai(team)
		update_hud()
		await(get_tree().physics_frame)
	


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
		#current_knights = 0
		var potential_targets = get_tree().get_nodes_in_group("knight")
		for target in potential_targets:
			if not target.is_queued_for_deletion():
				#current_knights += 1
				if nearest_target == null or character.position.distance_to(target.position) < character.position.distance_to(nearest_target.position):
					nearest_target = target
	elif character.is_in_group("knight"):
		#current_orcs = 0
		var potential_targets = get_tree().get_nodes_in_group("orc")
		for target in potential_targets:
			if not target.is_queued_for_deletion():
				#current_orcs += 1
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
