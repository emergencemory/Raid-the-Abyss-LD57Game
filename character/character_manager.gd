extends CharacterBody2D
class_name CharacterManager

enum DIR {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

@onready var block_right_sprite: Sprite2D = $BlockRightSprite
@onready var block_left_sprite: Sprite2D = $BlockLeftSprite
@onready var attack_from_right_sprite: Sprite2D = $AttackFromRightSprite
@onready var attack_from_left_sprite: Sprite2D = $AttackFromLeftSprite
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var strike_shape: CollisionShape2D = $CharacterSprite/HitBox/StrikeShape
@onready var character_sprite: AnimatedSprite2D = $CharacterSprite
@onready var ray_cast_2d: RayCast2D = $CharacterCollider/RayCast2D

var has_target: bool = false
var target: CharacterBody2D
var base_health: int
var base_attack_damage: int
var base_attack_cooldown : float 
var base_block_duration: float
var base_block_cooldown: float 
var base_speed: float 
var base_move_cooldown: float 
var base_kick_stun_duration: float 
var base_kick_cooldown: float
var current_health: int
var facing_direction: int = 0
var attack_direction: int = -1
var swing_from_right: bool = false
var current_attack_damage: int
var current_attack_cooldown: float
var attack_on_cooldown: bool = false
var block_direction: int = -1
var block_to_right: bool = false
var current_block_duration: float
var current_block_cooldown: float 
var block_on_cooldown: bool = false
var current_speed: float 
var current_move_cooldown: float 
var move_on_cooldown: bool = false
var is_kicking: bool = false
var current_kick_stun_duration: float
var current_kick_cooldown: float
var kick_on_cooldown: bool = false
var base_attack_speed
var current_attack_speed
var moving: bool = false
var is_player: bool = false
var team: String
var is_attacking: bool = false

signal attack_signal(value: float)
signal block_signal(value: float)
signal move_signal(value: float)
signal kick_signal(value: float)
signal health_signal(value: int, base_value: int)


func _ready() -> void:
	current_attack_damage = base_attack_damage
	current_health = base_health
	current_attack_cooldown = base_attack_cooldown
	current_block_duration = base_block_duration
	current_block_cooldown = base_block_cooldown
	current_speed = base_speed
	current_move_cooldown = base_move_cooldown
	current_kick_stun_duration = base_kick_stun_duration
	current_kick_cooldown = base_kick_cooldown
	current_attack_speed = base_attack_speed

func prepare_attack() -> void:
	if swing_from_right:
		attack_from_right_sprite.show()
		attack_from_left_sprite.hide()
		attack_direction = (facing_direction + 1) % 4
	else:
		attack_from_right_sprite.hide()
		attack_from_left_sprite.show()
		attack_direction = (facing_direction - 1) % 4


func attack() -> void:
# Activate the attack area
	attack_from_left_sprite.hide()
	attack_from_right_sprite.hide()
	if attack_on_cooldown:
		print("Attack on cooldown")
		return
	if is_attacking:
		print("attacking, cannot attack")
		return
	if moving:
		print("Moving, cannot attack")
		return
	print("Attacking!")
	if swing_from_right:
		character_sprite.play("attack_from_right")
	else:
		character_sprite.play("attack_from_left")
	is_attacking = true
	get_tree().create_timer(current_attack_speed/2).timeout.connect(_on_attack_begin)
	get_tree().create_timer(current_attack_speed).timeout.connect(_on_attack_timeout)
	# Start weapon cooldown
	attack_on_cooldown = true
	get_tree().create_timer(current_attack_cooldown).timeout.connect(_on_attack_cooldown_timeout)
	emit_signal("attack_signal", current_attack_cooldown)

func block() -> void:
	if block_on_cooldown:
		print("Block on cooldown")
		return
	if is_attacking:
		print("attacking, cannot block")
		return
	if moving:
		print("Moving, cannot block")
		return
	block_direction = get_block_direction()
	print("Blocking!")
	character_sprite.play("block")
	block_on_cooldown = true
	get_tree().create_timer(current_block_duration).timeout.connect(_on_block_timeout)
	emit_signal("block_signal", current_block_cooldown)
	get_tree().create_timer(current_block_cooldown).timeout.connect(_on_block_cooldown_timeout)

func kick() -> void:
	if moving:
		print("Moving, cannot kick")
		return
	if is_attacking:
		print("attacking, cannot kick")
		return
	if kick_on_cooldown:
		print("Kick on cooldown")
		return
	kick_on_cooldown = true
	is_kicking = true
	print("Kicking!")
	character_sprite.play("kick")
	get_tree().create_timer(current_kick_cooldown).timeout.connect(_on_kick_cooldown_timeout)
	emit_signal("kick_signal", current_kick_cooldown)
	get_tree().create_timer(current_kick_stun_duration).timeout.connect(_on_kick_timeout)
	
func move(direction: int) -> void:
	if ray_cast_2d.is_colliding():
		print("Collision detected, cannot move")
		return
	if move_on_cooldown:
		print("Move on cooldown")
		return
	character_sprite.play("walk")
	var previous_position = global_position
	match direction:
		DIR.NORTH:
			global_position += Vector2(0, -128)
		DIR.EAST:
			global_position += Vector2(128, 0)
		DIR.SOUTH:
			global_position += Vector2(0, 128)
		DIR.WEST:
			global_position += Vector2(-128, 0)	
	character_sprite.global_position = previous_position
	var move_sprite = create_tween()
	move_sprite.tween_property(character_sprite, "global_position", global_position, (30/current_speed))
	moving = true
	print("Moving!")

	get_tree().create_timer((30/current_speed)).timeout.connect(_on_move_timeout)
	move_on_cooldown = true
	get_tree().create_timer(current_move_cooldown).timeout.connect(_on_move_cooldown_timeout)
	emit_signal("move_signal", current_move_cooldown)

func turn(direction : int) -> void:
	if is_attacking:
		print("attacking, cannot turn")
		return
	if moving:
		print("moving, cannot turn")
		return
	match direction:
		DIR.NORTH:
			if rotation_degrees == 0:
				move(DIR.NORTH)
			else:
				rotation_degrees = 0
				facing_direction = 0
		DIR.EAST:
			if rotation_degrees == 90:
				move(DIR.EAST)
			else:
				rotation_degrees = 90
				facing_direction = 1
		DIR.SOUTH:
			if rotation_degrees == 180:
				move(DIR.SOUTH)
			else:
				rotation_degrees = 180
				facing_direction = 2
		DIR.WEST:
			if rotation_degrees == 270:
				move(DIR.WEST)
			else:
				rotation_degrees = 270
				facing_direction = 3
	print("direction: ", direction)
	#move_on_cooldown = true
	#get_tree().create_timer(0.1).timeout.connect(_on_move_cooldown_timeout)

func _on_move_timeout() -> void:
	moving = false
	character_sprite.play("idle")

func _on_target_timeout() -> void:
	print("Target cooldown ended")
	has_target = false

func _on_attack_cooldown_timeout() -> void:
	attack_on_cooldown = false
	print("Attack cooldown ended")

func _on_attack_timeout() -> void:
	strike_shape.disabled = true
	is_attacking = false
	attack_direction = -1
	character_sprite.play("idle")
	print("Attack area disabled")

func _on_attack_begin() -> void:
	strike_shape.disabled = false
	print("Attack area enabled")

func _on_block_timeout() -> void:
	block_direction = -1
	#character_sprite.play("idle")
	block_right_sprite.hide()
	block_left_sprite.hide()
	print("Block disabled")

func _on_block_cooldown_timeout() -> void:
	block_on_cooldown = false
	print("Block cooldown ended")

func _on_move_cooldown_timeout() -> void:
	move_on_cooldown = false
	#character_sprite.play("idle")
	print("Move cooldown ended")

func _on_kick_timeout() -> void:
	print("Kick ended")
	is_kicking = false
	character_sprite.play("idle")

func _on_kick_cooldown_timeout() -> void:
	kick_on_cooldown = false
	print("Kick cooldown ended")

func get_block_direction() -> int:
	if block_to_right:
		block_right_sprite.show()
		block_left_sprite.hide()
		return (facing_direction + 1) % 4
	else:
		block_right_sprite.hide()
		block_left_sprite.show()
		return (facing_direction - 1) % 4

func kicked(stun_duration : float) -> void:
	#apply duration to all actions
	print("Kicked! Stunned for ", stun_duration, " seconds")
	character_sprite.play("hit")
	attack_on_cooldown = true
	block_on_cooldown = true
	move_on_cooldown = true
	kick_on_cooldown = true
	get_tree().create_timer(stun_duration).timeout.connect(_on_kick_cooldown_timeout)
	emit_signal("kick_signal", stun_duration)
	get_tree().create_timer(stun_duration).timeout.connect(_on_attack_cooldown_timeout)
	emit_signal("attack_signal", stun_duration)
	get_tree().create_timer(stun_duration).timeout.connect(_on_block_cooldown_timeout)
	emit_signal("block_signal", stun_duration)
	get_tree().create_timer(stun_duration).timeout.connect(_on_move_cooldown_timeout)
	emit_signal("move_signal", stun_duration)

func hit() -> void:
	current_health -= 1
	emit_signal("health_signal", current_health, base_health)
	if current_health <= 0:
		die()
		
	else:
		print("Hit! Health: ", current_health)
		character_sprite.play("hit")

func die() -> void:
	add_to_group("dead")
	z_index = 0
	for child in get_children():
		child.queue_free()
	character_sprite = AnimatedSprite2D.new()
	character_sprite.sprite_frames = ResourceLoader.load("res://character/" + team + "/" + team + "_spriteframes.tres")
	add_child(character_sprite)
	character_sprite.play("die")
	remove_from_group(team)
	if is_player:
		is_player = false
		get_tree().create_timer(2.0).timeout.connect(get_parent().spawn_player)
	


func _on_attack_area_entered(area: Area2D) -> void:
	var _target = area.get_parent()
	if _target is CharacterBody2D:
		if is_kicking:
			print("Kicked!")
			_target.kicked(current_kick_stun_duration)
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Body"
			audio_stream_player_2d.play()
			return
		elif _target.attack_direction == attack_direction:
			print("Parried!")
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Metal Armour"
			audio_stream_player_2d.play()
		elif _target.block_direction == attack_direction:
			print("Blocked!")
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Wooden"
			audio_stream_player_2d.play()
		else:
			print("Hit!")
			_target.hit()
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Sword And Swipe"
			audio_stream_player_2d.play()
	else:
		print("Attack missed!")
