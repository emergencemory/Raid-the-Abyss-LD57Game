extends CharacterBody2D
class_name CharacterManager

enum DIR {
	EAST,
	WEST,
	SOUTH,
	NORTH
}

@onready var character_sprite: AnimatedSprite2D = $CharacterSprite
@onready var character_animation_player: AnimationPlayer = $CharacterAnimationPlayer

@onready var shield_sprite: AnimatedSprite2D = $ShieldSprite
@onready var shield_animation_player: AnimationPlayer = $ShieldAnimationPlayer

@onready var weapon_sprite: AnimatedSprite2D = $WeaponSprite
@onready var weapon_animation_player: AnimationPlayer = $WeaponAnimationPlayer

var health : int = 2
var stance : int
var parry : int
var block : int
var weappon_cooldown : float = 2.0
var weapon_on_cooldown : bool = false
var direction_cooldown : bool = false
var stance_cooldown : bool = false
var target_cooldown : bool = false
var target : CharacterBody2D
var has_target : bool
#var current_path : Array[Vector2i]
#TODO on set, start timer before reseting

func _ready() -> void:
	character_animation_player.play("character/idle_s")
	shield_animation_player.play("shield/idle_s")
	weapon_animation_player.play("weapon/idle_s")


func attack(_target : CharacterBody2D) -> void:
	print("Attacking target: ", _target.name)
	match stance:
		0:
			if _target.parry == DIR.EAST:
				print("Parried")
			elif _target.block == DIR.EAST:
				print("Blocked")
			else:
				print("Hit")
				_target.hit()
		1:
			if _target.parry == DIR.WEST:
				print("Parried")
			elif _target.block == DIR.WEST:
				print("Blocked")
			else:
				print("Hit")
				_target.hit()
		2:
			if _target.parry == DIR.SOUTH:
				print("Parried")
			elif _target.block == DIR.SOUTH:
				print("Blocked")
			else:
				print("Hit")
				_target.hit()
		3:
			if _target.parry == DIR.NORTH:
				print("Parried")
			elif _target.block == DIR.NORTH:
				print("Blocked")
			else:
				print("Hit")
				_target.hit()
	weapon_on_cooldown = true
	get_tree().create_timer(weappon_cooldown).timeout.connect(_on_attack_timeout)

func _on_attack_timeout() -> void:
	weapon_on_cooldown = false
	print("Attack cooldown ended")

func apply_animation() -> void:
	if velocity.x > 0:
		character_animation_player.play("character/idle_e")
	elif velocity.x < 0:
		character_animation_player.play("character/idle_w")
	elif velocity.y > 0:
		character_animation_player.play("character/idle_s")
	elif velocity.y < 0:
		character_animation_player.play("character/idle_n")
	combat_stance()

func combat_stance() -> void:
	if stance_cooldown == false:
		print("combat stance cooldown start")
		stance_cooldown = true
		get_tree().create_timer(0.5).timeout.connect(_on_stance_cooldown_timeout)
		stance = randi_range(0, 3)
	
	match stance:
		0:
			weapon_animation_player.play("weapon/idle_e")
			parry = DIR.EAST
		1:
			weapon_animation_player.play("weapon/idle_w")
			parry = DIR.WEST
		2:
			weapon_animation_player.play("weapon/idle_s")
			parry = DIR.SOUTH
		3:
			weapon_animation_player.play("weapon/idle_n")
			parry = DIR.NORTH
	if velocity.x > 0:
		if stance > 1:
			shield_animation_player.play("shield/idle_e")
			block = DIR.EAST
		else:
			shield_animation_player.play("shield/idle_n")
			block = DIR.NORTH
	elif velocity.x < 0:
		if stance > 1:
			shield_animation_player.play("shield/idle_w")
			block = DIR.WEST
		else:
			shield_animation_player.play("shield/idle_s")
			block = DIR.SOUTH
	elif velocity.y > 0:
		if stance > 1:
			shield_animation_player.play("shield/idle_s")
			block = DIR.SOUTH
		else:
			shield_animation_player.play("shield/idle_e")
			block = DIR.EAST
	elif velocity.y < 0:
		if stance > 1:
			shield_animation_player.play("shield/idle_n")
			block = DIR.NORTH
		else:
			shield_animation_player.play("shield/idle_w")
			block = DIR.WEST

func start_direction_cooldown() -> void:
	direction_cooldown = true
	get_tree().create_timer(0.5).timeout.connect(_on_direction_cooldown_timeout)
	print("Direction cooldown started")

func _on_direction_cooldown_timeout() -> void:
	direction_cooldown = false
	print("Direction cooldown ended")

func _on_stance_cooldown_timeout() -> void:
	stance_cooldown = false
	print("Stance cooldown ended")

func start_target_cooldown() -> void:
	target_cooldown = true
	get_tree().create_timer(0.5).timeout.connect(_on_target_timeout)
	print("Target cooldown started")

func _on_target_timeout() -> void:
	target_cooldown = false
	print("Target cooldown ended")

func hit() -> void:
	health -= 1
	if health <= 0:
		add_to_group("dead")
		if is_in_group("ai"):
			remove_from_group("ai")
		if is_in_group("orc"):
			remove_from_group("orc")
		if is_in_group("knight"):
			remove_from_group("knight")
		self.hide()
		get_tree().create_timer(5.0).timeout.connect(_on_death_timeout)
	else:
		print("Hit! Health: ", health)

func _on_death_timeout() -> void:
	print("Character died")
	queue_free()