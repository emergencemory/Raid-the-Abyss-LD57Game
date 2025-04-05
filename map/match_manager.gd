extends Node
class_name MatchManager

const INPUT_PARSER : Script = preload("res://character/input_parser.gd")

@onready var character_scene : PackedScene = preload("res://character/character_model.tscn")


func _ready() -> void:
	var player = character_scene.instantiate()
	add_child(player)
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
	var ai = character_scene.instantiate()
	add_child(ai)
	ai.position = Vector2(randi_range(0, 500), randi_range(0, 500))
	ai.character_sprite.sprite_frames = ResourceLoader.load("res://character/orc/orc_spriteframes.tres")
	ai.weapon_sprite.sprite_frames = ResourceLoader.load("res://equipment/axe/axe_spriteframes.tres")
	ai.shield_sprite.sprite_frames = ResourceLoader.load("res://equipment/round_shield/round_shield_spriteframes.tres")
	get_tree().create_timer(5.0).timeout.connect(spawn_ai)
	
