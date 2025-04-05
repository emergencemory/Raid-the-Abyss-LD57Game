extends Node
class_name MatchManager

const INPUT_PARSER : Script = preload("res://character/input_parser.gd")

@onready var character_scene : PackedScene = preload("res://character/character_model.tscn")


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
			var target = get_target(character)
			if target != null:
				if character.position.distance_to(target.position) > 50:
					character.velocity = (target.position - character.position).normalized() * 15
					character.position += character.velocity * delta
					character.move_and_slide()
				elif character.weapon_on_cooldown == false:
					character.attack(target)
		else:
			print("Invalid character instance.")

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
