extends CharacterBody2D
class_name CharacterManager

enum DIR {
	NORTH,
	EAST,
	SOUTH,
	WEST
}


@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var attack_area: Area2D = $AttackArea
@onready var hitbox: Area2D = $Hitbox
@onready var strike_shape: CollisionShape2D = $AttackArea/StrikeShape
@onready var character_sprite: AnimatedSprite2D = $CharacterSprite
@onready var character_animation_player: AnimationPlayer = $CharacterAnimationPlayer
@onready var shield_sprite: AnimatedSprite2D = $ShieldSprite
@onready var shield_animation_player: AnimationPlayer = $ShieldAnimationPlayer
@onready var weapon_sprite: AnimatedSprite2D = $WeaponSprite
@onready var weapon_animation_player: AnimationPlayer = $WeaponAnimationPlayer
@onready var strike_label: Label = $AttackArea/StrikeLabel
@onready var parry_label: Label = $WeaponSprite/ParryLabel
@onready var block_label: Label = $ShieldSprite/BlockLabel

var health: int = 2
var stance: int = DIR.SOUTH
var block_offset: int = 0  # 0 = same as stance, 1 = one step clockwise
var weapon_on_cooldown: bool = false
var stance_cooldown: bool = false
var direction_cooldown: bool = false
var target_cooldown: bool = false
var target: CharacterBody2D
var has_target: bool = false
var parry_direction: int = DIR.NORTH  # Direction the weapon is being held
var block_direction: int = DIR.NORTH  # Direction the shield is being held


func _ready() -> void:
	update_animations()

func attack() -> void:
# Activate the attack area
	print("Attacking!")
	strike_shape.disabled = false





	# Disable the ray after the attack
	#strike_shape.disabled = true

	# Start weapon cooldown
	weapon_on_cooldown = true
	get_tree().create_timer(2.0).timeout.connect(_on_attack_timeout)

func _on_attack_timeout() -> void:
	weapon_on_cooldown = false
	print("Attack cooldown ended")

func update_animations() -> void:
	# Update character movement animation
	if velocity.x > 0:
		character_animation_player.play("character/idle_e")
		attack_area.position = Vector2i(52, 0)
	elif velocity.x < 0:
		character_animation_player.play("character/idle_w")
		attack_area.position = Vector2i(-52, 0)
	elif velocity.y > 0:
		character_animation_player.play("character/idle_s")
		attack_area.position = Vector2i(0, 52)
	elif velocity.y < 0:
		character_animation_player.play("character/idle_n")
		attack_area.position = Vector2i(0, -52)
	#else:
		#character_animation_player.play("character/idle_s")  # Default idle animation

	# Update weapon animation based on parry direction
	match parry_direction:
		DIR.NORTH:
			weapon_animation_player.play("weapon/idle_n")
			parry_label.text = "Parry North"
			strike_label.text = "Attack from North"
		DIR.EAST:
			weapon_animation_player.play("weapon/idle_e")
			parry_label.text = "Parry East"
			strike_label.text = "Attack from East"
		DIR.SOUTH:
			weapon_animation_player.play("weapon/idle_s")
			parry_label.text = "Parry South"
			strike_label.text = "Attack from South"
		DIR.WEST:
			weapon_animation_player.play("weapon/idle_w")
			parry_label.text = "Parry West"
			strike_label.text = "Attack from West"

	# Update shield animation based on block direction
	match block_direction:
		DIR.NORTH:
			shield_animation_player.play("shield/idle_n")
			block_label.text = "Block North"
		DIR.EAST:
			shield_animation_player.play("shield/idle_e")
			block_label.text = "Block East"
		DIR.SOUTH:
			shield_animation_player.play("shield/idle_s")
			block_label.text = "Block South"
		DIR.WEST:
			shield_animation_player.play("shield/idle_w")
			block_label.text = "Block West"

func get_block_direction() -> int:
	return (stance - block_offset + 4) % 4

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

func trigger_block_effect(target: CharacterManager) -> void:
	print("Triggering block effect on:", target.name)
	# Add block effect logic here (e.g., particles, sound, etc.)

func trigger_parry_effect(target: CharacterManager) -> void:
	print("Triggering parry effect on:", target.name)
	# Add parry effect logic here (e.g., particles, sound, etc.)

func trigger_hit_effect(target: CharacterManager) -> void:
	print("Triggering hit effect on:", target.name)
	# Add hit effect logic here (e.g., particles, sound, etc.)

func get_direction_vector(direction: int) -> Vector2:
	match direction:
		DIR.NORTH:
			return Vector2(0, -1)
		DIR.EAST:
			return Vector2(1, 0)
		DIR.SOUTH:
			return Vector2(0, 1)
		DIR.WEST:
			return Vector2(-1, 0)
		_:
			return Vector2.ZERO

func angle_to_direction(angle: float) -> int:
	angle = wrapf(angle, -PI, PI)  # Normalize angle to [-PI, PI]
	if angle >= -PI / 4 and angle < PI / 4:
		return DIR.EAST
	elif angle >= PI / 4 and angle < 3 * PI / 4:
		return DIR.SOUTH
	elif angle >= -3 * PI / 4 and angle < -PI / 4:
		return DIR.NORTH
	else:
		return DIR.WEST

func update_directions() -> void:
	# Calculate the facing direction (stance) based on velocity
	if velocity.x > 0:
		stance = DIR.EAST
	elif velocity.x < 0:
		stance = DIR.WEST
	elif velocity.y > 0:
		stance = DIR.SOUTH
	elif velocity.y < 0:
		stance = DIR.NORTH

	# Calculate the mouse position relative to the player
	var mouse_position = get_global_mouse_position() - global_position
	var mouse_angle = mouse_position.angle()

	# Determine the parry direction based on the mouse angle
	if Input.is_action_pressed("attack"):
		parry_direction = angle_to_direction(mouse_angle)
	else:
		parry_direction = stance  # Default to stance when not attacking

	# Determine the block direction based on the mouse angle
	if Input.is_action_pressed("block"):
		block_direction = angle_to_direction(mouse_angle)
	else:
		block_direction = stance  # Default to stance when not blocking

func _on_attack_area_entered(area: Area2D) -> void:
	target = area.get_parent()
	if target is CharacterBody2D:
		if target.parry_direction == parry_direction:
			print("Parried!")
			trigger_parry_effect(target)
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Metal Armour"
			audio_stream_player_2d.play()
		elif target.block_direction == parry_direction:
			print("Blocked!")
			trigger_block_effect(target)
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Wooden"
			audio_stream_player_2d.play()
		else:
			print("Hit!")
			trigger_hit_effect(target)
			target.hit()
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Body"
			audio_stream_player_2d.play()
	else:
		print("Attack missed!")
		audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Sword And Swipe"
		audio_stream_player_2d.play()
	strike_shape.disabled = true
