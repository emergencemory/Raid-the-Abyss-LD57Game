extends CharacterBody2D
class_name CharacterManager

@onready var character_sprite: AnimatedSprite2D = $CharacterSprite
@onready var character_animation_player: AnimationPlayer = $CharacterAnimationPlayer

@onready var shield_sprite: AnimatedSprite2D = $ShieldSprite
@onready var shield_animation_player: AnimationPlayer = $ShieldAnimationPlayer

@onready var weapon_sprite: AnimatedSprite2D = $WeaponSprite
@onready var weapon_animation_player: AnimationPlayer = $WeaponAnimationPlayer

func _ready() -> void:
	character_animation_player.play("character/idle_s")
	shield_animation_player.play("shield/idle_s")
	weapon_animation_player.play("weapon/idle_s")





