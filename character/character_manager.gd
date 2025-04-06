extends CharacterBody2D
class_name CharacterManager

enum DIR {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

@onready var character_sprite: AnimatedSprite2D = $CharacterSprite
@onready var character_animation_player: AnimationPlayer = $CharacterAnimationPlayer
@onready var shield_sprite: AnimatedSprite2D = $ShieldSprite
@onready var shield_animation_player: AnimationPlayer = $ShieldAnimationPlayer
@onready var weapon_sprite: AnimatedSprite2D = $WeaponSprite
@onready var weapon_animation_player: AnimationPlayer = $WeaponAnimationPlayer

var health: int = 2
var stance: int = DIR.SOUTH
var block_offset: int = 0  # 0 = same as stance, 1 = one step clockwise

var weapon_on_cooldown: bool = false
var stance_cooldown: bool = false
var direction_cooldown: bool = false
var target_cooldown: bool = false
var target: CharacterBody2D
var has_target: bool = false

func _ready() -> void:
	update_animations()

func attack(_target: CharacterBody2D) -> void:
	print("Attacking target: ", _target.name)
	if _target.stance == stance:
		print("Parried")
	elif _target.get_block_direction() == stance:
		print("Blocked")
	else:
		print("Hit")
		_target.hit()
	weapon_on_cooldown = true
	get_tree().create_timer(2.0).timeout.connect(_on_attack_timeout)

func _on_attack_timeout() -> void:
	weapon_on_cooldown = false
	print("Attack cooldown ended")

func update_animations() -> void:
	# Update character movement animation
	if velocity.x > 0:
		character_animation_player.play("character/idle_e")
		stance = DIR.EAST
	elif velocity.x < 0:
		character_animation_player.play("character/idle_w")
		stance = DIR.WEST
	elif velocity.y > 0:
		character_animation_player.play("character/idle_s")
		stance = DIR.SOUTH
	elif velocity.y < 0:
		character_animation_player.play("character/idle_n")
		stance = DIR.NORTH
	else:
		character_animation_player.play("character/idle_s")  # Default idle animation

	# Update weapon animation based on stance
	match stance:
		DIR.NORTH:
			weapon_animation_player.play("weapon/idle_n")
		DIR.EAST:
			weapon_animation_player.play("weapon/idle_e")
		DIR.SOUTH:
			weapon_animation_player.play("weapon/idle_s")
		DIR.WEST:
			weapon_animation_player.play("weapon/idle_w")

	# Update shield animation based on block direction
	match get_block_direction():
		DIR.NORTH:
			shield_animation_player.play("shield/idle_n")
		DIR.EAST:
			shield_animation_player.play("shield/idle_e")
		DIR.SOUTH:
			shield_animation_player.play("shield/idle_s")
		DIR.WEST:
			shield_animation_player.play("shield/idle_w")

func get_block_direction() -> int:
	return (stance + block_offset) % 4

func hit() -> void:
	health -= 1
	if health <= 0:
		add_to_group("dead")
		self.hide()
		get_tree().create_timer(5.0).timeout.connect(_on_death_timeout)
	else:
		print("Hit! Health: ", health)

func _on_death_timeout() -> void:
	print("Character died")
	queue_free()

func update_ai_combat_stance() -> void:
	if not stance_cooldown:
		stance_cooldown = true
		get_tree().create_timer(0.5).timeout.connect(_on_stance_cooldown_timeout)
		stance = randi_range(0, 3)
		block_offset = randi_range(0, 1)
		update_animations()

func _on_stance_cooldown_timeout() -> void:
	stance_cooldown = false


func start_target_cooldown() -> void:
	if not target_cooldown:
		target_cooldown = true
		get_tree().create_timer(1.0).timeout.connect(_on_target_cooldown_timeout)  # 1-second cooldown

func _on_target_cooldown_timeout() -> void:
	target_cooldown = false

func start_direction_cooldown() -> void:
	if not direction_cooldown:
		direction_cooldown = true
		get_tree().create_timer(0.5).timeout.connect(_on_direction_cooldown_timeout)  # 0.5-second cooldown

func _on_direction_cooldown_timeout() -> void:
	direction_cooldown = false
