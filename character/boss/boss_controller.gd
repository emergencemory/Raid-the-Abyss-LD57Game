extends CharacterBody2D
class_name BossManager

const GAME_DATA : Script = preload("res://data/GameData.gd")

enum DIR {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

@onready var stun_particle: GPUParticles2D = $StunParticle
@onready var blood_particle: GPUParticles2D = $BloodParticle
@onready var spark_particle: GPUParticles2D = $SparkParticle
@onready var attack_from_right_sprite: Sprite2D = $AttackFromRightSprite
@onready var attack_from_left_sprite: Sprite2D = $AttackFromLeftSprite
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var strike_shape: CollisionShape2D = $CharacterSprite/HitBox/StrikeShape
@onready var character_sprite: AnimatedSprite2D = $CharacterSprite
@onready var shadow_sprite: AnimatedSprite2D = $CharacterSprite/ShadowSprite
@onready var ray_cast_2d: RayCast2D = $CharacterCollider/RayCast2D

var recursion_index: int = 0
var has_target: bool = false
var is_player: bool = false
var target: CharacterBody2D
var cooldown_time_target: float = 0.0
var team: String
var order_ticks : float = 0.0
var current_xp: float
var current_level: int
var current_xp_to_next_level: float
var base_xp_to_next_level_multiplier: float
var level_up_multiplier: float
var level_up_addition: int

var base_health: int
var current_health: int
var stun_on_cooldown: bool = false
var cooldown_time_stun: float = 0.0

var facing_direction: int = 0
var is_turning: bool = false
var moving: bool = false
var current_speed: float 
var current_move_cooldown: float 
var move_on_cooldown: bool = false
var cooldown_time_turn: float = 0.0
var cooldown_time_move: float = 0.0
var movement_time: float = 0.0 

var is_preparing_attack: bool = false
var attack_direction: int = -1
var swing_from_right: bool = false
var attack_windup: bool = false
var windup_time: float = 0.0

var is_attacking_from_right: bool = false
var current_attack_from_right_damage: int
var current_attack_from_right_speed: float
var current_attack_from_right_cooldown: float
var attack_from_right_on_cooldown: bool = false
var cooldown_time_attack_from_right: float = 0.0
var attack_from_right_area_time: float = 0.0

var is_attacking_from_left: bool = false
var current_attack_from_left_damage: int
var current_attack_from_left_speed: float
var current_attack_from_left_cooldown: float
var attack_from_left_on_cooldown: bool = false
var cooldown_time_attack_from_left: float = 0.0
var attack_from_left_area_time: float = 0.0

var is_stomping: bool = false
var current_stomp_damage: int
var current_stomp_speed: float
var current_stomp_stun_duration: float
var current_stomp_cooldown: float
var stomp_on_cooldown: bool = false
var cooldown_time_stomp: float = 0.0
var stomp_area_time: float = 0.0

var is_jumping: bool = false
var current_jump_damage: int
var current_jump_speed: float
var current_jump_cooldown: float
var jump_on_cooldown: bool = false
var cooldown_time_jump: float = 0.0
var jump_area_time: float = 0.0

signal attack_signal(value: float)
signal block_signal(value: float)
signal move_signal(value: float)
signal kick_signal(value: float)
signal killed_by_player(team: String)
signal killed_by_knight(team: String)
signal killed_by_orc(team: String)

func _ready() -> void:
	current_level = GAME_DATA.boss_data["base_level"]
	current_xp = GAME_DATA.boss_data["base_xp"]
	current_xp_to_next_level = GAME_DATA.boss_data["base_xp_to_next_level"]
	base_xp_to_next_level_multiplier = GAME_DATA.boss_data["base_xp_to_next_level_multiplier"]
	level_up_multiplier = GAME_DATA.boss_data["level_up_multiplier"]
	level_up_addition = GAME_DATA.boss_data["level_up_addition"]

	base_health = GAME_DATA.boss_data["base_health"]
	current_health = base_health
	current_speed = GAME_DATA.boss_data["base_speed"]
	current_move_cooldown = GAME_DATA.boss_data["move_cooldown"]

	current_attack_from_left_damage = GAME_DATA.boss_data["attack_from_left_damage"]
	current_attack_from_left_speed = GAME_DATA.boss_data["attack_from_left_speed"]
	current_attack_from_left_cooldown = GAME_DATA.boss_data["attack_from_left_cooldown"]

	current_attack_from_right_damage = GAME_DATA.boss_data["attack_from_right_damage"]
	current_attack_from_right_speed = GAME_DATA.boss_data["attack_from_right_speed"]
	current_attack_from_right_cooldown = GAME_DATA.boss_data["attack_from_right_cooldown"]
	
	current_stomp_stun_duration = GAME_DATA.boss_data["stomp_stun"]
	current_stomp_speed = GAME_DATA.boss_data["stomp_speed"]
	current_stomp_cooldown = GAME_DATA.boss_data["stomp_cooldown"]
	current_stomp_damage = GAME_DATA.boss_data["stomp_damage"]

	current_jump_cooldown = GAME_DATA.boss_data["jump_cooldown"]
	current_jump_damage = GAME_DATA.boss_data["jump_damage"]
	current_jump_speed = GAME_DATA.boss_data["jump_speed"]
	
	if is_player:
		SignalBus.emit_signal("health_signal", current_health, base_health, self)

func level_up():
	current_level += 1
	SignalBus.emit_signal("leveled_up", self, current_level)
	character_sprite.self_modulate = Color(3, 3, 1, 1)
	var level_tween = create_tween()
	level_tween.tween_property(character_sprite, "self_modulate", Color((1 + float(current_level)/10), (1 + float(current_level)/10), 1, 1), 0.5)
	
	current_xp_to_next_level = base_xp_to_next_level_multiplier * current_xp_to_next_level
	
	base_health += level_up_addition
	current_health = base_health
	current_move_cooldown = current_move_cooldown / level_up_multiplier

	current_attack_from_left_damage = (level_up_addition*current_level)/2
	current_attack_from_left_cooldown = current_attack_from_left_cooldown / level_up_multiplier
	
	current_attack_from_right_damage = (level_up_addition*current_level)/2
	current_attack_from_right_cooldown = current_attack_from_right_cooldown / level_up_multiplier

	current_stomp_damage = (level_up_addition*current_level)/2
	current_stomp_cooldown = current_stomp_cooldown / level_up_multiplier
	current_stomp_stun_duration = current_stomp_stun_duration * level_up_multiplier

	current_jump_damage = (level_up_addition*current_level)/2
	current_jump_cooldown = current_jump_cooldown / level_up_multiplier
	
	if is_player:
		SignalBus.emit_signal("request_reinforcements", team)

func _physics_process(delta) -> void:
	if is_in_group("dead"):
		set_physics_process(false)
		return
	if stun_on_cooldown:
		if cooldown_time_stun > 0:
			cooldown_time_stun -= delta
		else:
			stun_on_cooldown = false
			stun_particle.emitting = false
	if attack_from_left_on_cooldown:
		if cooldown_time_attack_from_left > 0:
			cooldown_time_attack_from_left -= delta
		else:
			_on_attack_from_left_cooldown_timeout()
	if attack_from_right_on_cooldown:
		if cooldown_time_attack_from_right > 0:
			cooldown_time_attack_from_right -= delta
		else:
			_on_attack_from_right_cooldown_timeout()
	if jump_on_cooldown:
		if cooldown_time_jump > 0:
			cooldown_time_jump -= delta
		else:
			_on_jump_cooldown_timeout()
	if is_turning:
		if cooldown_time_turn > 0:
			cooldown_time_turn -= delta
		else:
			is_turning = false
	if move_on_cooldown:	
		if cooldown_time_move > 0:
			cooldown_time_move -= delta
		else:
			_on_move_cooldown_timeout()
	if moving:
		if movement_time > 0:
			movement_time -= delta
		else:
			_on_move_timeout()
	if stomp_on_cooldown:
		if cooldown_time_stomp > 0:
			cooldown_time_stomp -= delta
		else:
			_on_kick_cooldown_timeout()
	if attack_windup:
		if windup_time > 0:
			windup_time -= delta
		else:
			_on_attack_begin()
	if is_attacking_from_left:
		if attack_from_left_area_time > 0:
			attack_from_left_area_time -= delta
		else:
			_on_attack_from_left_timeout()
	if is_attacking_from_right:
		if attack_from_right_area_time > 0:
			attack_from_right_area_time -= delta
		else:
			_on_attack_from_right_timeout()
	if is_jumping:
		if jump_area_time > 0:
			jump_area_time -= delta
		else:
			_on_jump_timeout()
	if is_stomping:
		if stomp_area_time > 0:
			stomp_area_time -= delta
		else:
			_on_stomp_timeout()
	if has_target:
		if cooldown_time_target > 0:
			cooldown_time_target -= delta
		else:
			_on_target_timeout()
	if current_xp >= current_xp_to_next_level:
		level_up()


func prepare_attack_from_left() -> void:
	if is_attacking_from_left or is_attacking_from_right or attack_windup or is_stomping or is_jumping or attack_from_left_on_cooldown:
		return
	else:	
		attack_from_right_sprite.hide()
		attack_from_left_sprite.show()
		attack_direction = ((facing_direction+4) - 1) % 4
		is_preparing_attack = true

func prepare_attack_from_right() -> void:
	if is_attacking_from_left or is_attacking_from_right or attack_windup or is_stomping or is_jumping or attack_from_right_on_cooldown:
		return
	else:
		attack_from_left_sprite.hide()
		attack_from_right_sprite.show()
		attack_direction = ((facing_direction+4) + 1) % 4
		is_preparing_attack = true
		

func attack_from_left() -> void:
	attack_from_left_sprite.hide()
	attack_from_right_sprite.hide()
	is_preparing_attack = false
	if attack_from_left_on_cooldown or is_attacking_from_left or is_attacking_from_right or moving or is_turning or is_stomping or is_jumping or attack_windup:
		return
	else:
		character_sprite.play("attack_from_left")
		shadow_sprite.play("attack_from_left")
		windup_time = current_attack_from_left_speed/2
		attack_windup = true
		cooldown_time_attack_from_left = current_attack_from_left_cooldown
		attack_from_left_on_cooldown = true
		if is_player:
			emit_signal("attack_signal", current_attack_from_left_cooldown)

func attack_from_right() -> void:
	attack_from_left_sprite.hide()
	attack_from_right_sprite.hide()
	is_preparing_attack = false
	if attack_from_right_on_cooldown or is_attacking_from_left or is_attacking_from_right or moving or is_turning or is_stomping or is_jumping or attack_windup:
		return
	else:
		character_sprite.play("attack_from_right")
		shadow_sprite.play("attack_from_right")
		windup_time = current_attack_from_right_speed/2
		attack_windup = true
		cooldown_time_attack_from_right = current_attack_from_right_cooldown
		attack_from_right_on_cooldown = true
		if is_player:
			emit_signal("attack_signal", current_attack_from_right_cooldown)



func jump() -> void:
	if jump_on_cooldown or not has_target or is_attacking_from_left or is_attacking_from_right or moving or is_turning or attack_windup or is_stomping:
		return
	var jump_target = target
	character_sprite.play("jump")
	shadow_sprite.play("jump")
	cooldown_time_jump = current_jump_cooldown
	jump_on_cooldown = true
	jump_area_time = current_jump_speed
	is_jumping = true
	if is_player:
		emit_signal("block_signal", current_jump_cooldown)

func stomp() -> void:
	if moving or is_attacking or is_turning or attack_windup or is_turning or is_kicking or kick_on_cooldown:
		return
	elif is_blocking:
		_on_block_timeout()
	cooldown_time_kick = current_kick_cooldown
	kick_on_cooldown = true
	cooldown_time_attack_area = current_attack_speed/2
	is_kicking = true
	strike_shape.set_deferred("disabled", false)
	character_sprite.play("stomp")
	shadow_sprite.play("stomp")
	if is_player:
		emit_signal("kick_signal", current_kick_cooldown)
	
func move(direction: int) -> void:
	if direction != facing_direction and recursion_index < 10:
		recursion_index += 1
		turn(direction)
		return
	ray_cast_2d.force_raycast_update()
	if ray_cast_2d.is_colliding() or move_on_cooldown or is_attacking or attack_windup or is_kicking or is_turning or moving:
		return
	elif is_blocking:
		_on_block_timeout()
	moving = true
	character_sprite.play("walk")
	shadow_sprite.play("walk")
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
	cooldown_time_moving = 30/current_speed
	cooldown_time_move = current_move_cooldown
	move_on_cooldown = true
	recursion_index = 0
	if is_player:
		emit_signal("move_signal", current_move_cooldown)
		SignalBus.emit_signal("player_move", position)

func turn(direction : int) -> void:
	if is_attacking or moving or attack_windup or is_kicking:
		return
	elif is_blocking:
		_on_block_timeout()
	match direction:
		DIR.NORTH:
			if rotation_degrees == 0 or rotation_degrees == 360 or facing_direction == 0:
				move(DIR.NORTH)
			else:
				var turn_tween = create_tween()
				if rotation_degrees == 90 or facing_direction == 1:
					turn_tween.tween_property(self, "rotation_degrees", 0, 0.15)
				if rotation_degrees == 270 or facing_direction == 3:
					turn_tween.tween_property(self, "rotation_degrees", 360, 0.15)
				else:
					if team == "knight":
						turn_tween.tween_property(self, "rotation_degrees", 0, 0.15)
					else:
						turn_tween.tween_property(self, "rotation_degrees", 360, 0.15)
				is_turning = true
				facing_direction = 0
				cooldown_time_turn = 0.15
		DIR.EAST:
			if rotation_degrees == 90:
				move(DIR.EAST)
			else:
				is_turning = true
				var turn_tween = create_tween()
				turn_tween.tween_property(self, "rotation_degrees", 90, 0.15)
				facing_direction = 1
				cooldown_time_turn = 0.15
		DIR.SOUTH:
			if rotation_degrees == 180:
				move(DIR.SOUTH)
			else:
				is_turning = true
				var turn_tween = create_tween()
				turn_tween.tween_property(self, "rotation_degrees", 180, 0.15)
				facing_direction = 2
				cooldown_time_turn = 0.15
		DIR.WEST:
			if rotation_degrees == 270:
				move(DIR.WEST)
			else:
				is_turning = true
				var turn_tween = create_tween()
				turn_tween.tween_property(self, "rotation_degrees", 270, 0.15)
				facing_direction = 3
				cooldown_time_turn = 0.15

func _on_move_timeout() -> void:
	moving = false
	character_sprite.play("idle")
	shadow_sprite.play("idle")

func _on_target_timeout() -> void:
	has_target = false

func _on_attack_cooldown_timeout() -> void:
	attack_on_cooldown = false

func _on_attack_timeout() -> void:
	strike_shape.set_deferred("disabled", true)
	is_attacking = false
	attack_direction = -1
	character_sprite.play("idle")
	shadow_sprite.play("idle")

func _on_attack_begin() -> void:
	strike_shape.set_deferred("disabled", false)
	attack_windup = false
	cooldown_time_attack_area = current_attack_speed/2
	is_attacking = true
	ray_cast_2d.force_raycast_update()
	if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider().is_in_group("wall"):
		print( str(self) + " hit wall!" )
		SignalBus.wall_hit.emit(self.position)

func _on_block_timeout() -> void:
	is_blocking = false
	block_direction = -1


func _on_block_cooldown_timeout() -> void:
	block_on_cooldown = false

func _on_move_cooldown_timeout() -> void:
	move_on_cooldown = false

func _on_kick_timeout() -> void:
	is_kicking = false
	strike_shape.set_deferred("disabled", true)
	character_sprite.play("idle")
	shadow_sprite.play("idle")

func _on_kick_cooldown_timeout() -> void:
	kick_on_cooldown = false

func get_block_direction() -> int:
	if block_to_right:
		var block_dir = ((facing_direction + 1) + 4) % 4
		return block_dir
	else:
		var block_dir =((facing_direction - 1)+4) % 4
		return block_dir

func kicked(kicker : CharacterBody2D, enemy_facing_dir : int) -> void:
	var stun_duration: float = kicker.current_kick_stun_duration
	stun_particle.emitting = true
	var log_string : String = "Kicked! Stunned for " + str(stun_duration) + " seconds"
	character_sprite.play("hit")
	shadow_sprite.play("hit")
	_on_block_timeout()
	_on_attack_timeout()
	attack_windup = false
	is_turning = true
	cooldown_time_turn += stun_duration
	stun_on_cooldown = true
	cooldown_time_stun = stun_duration
	attack_on_cooldown = true
	cooldown_time_attack += stun_duration
	block_on_cooldown = true
	cooldown_time_block += stun_duration
	move_on_cooldown = true
	cooldown_time_move += stun_duration
	kick_on_cooldown = true
	cooldown_time_kick += stun_duration
	if is_player:
		emit_signal("kick_signal", stun_duration)
		emit_signal("attack_signal", stun_duration)
		emit_signal("block_signal", stun_duration)
		emit_signal("move_signal", stun_duration)
	var _old_rotation = rotation_degrees
	if not moving:
		match enemy_facing_dir:
			DIR.NORTH:
				rotation_degrees = 0
				ray_cast_2d.force_raycast_update()
				if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider().is_in_group("cliff"):
					global_position += Vector2(0, -128)
					log_string = str(self) + " is falling off cliff!"
					falling = true
					killed(kicker)
					die()
				elif not ray_cast_2d.is_colliding():
					global_position += Vector2(0, -128)
				rotation_degrees = _old_rotation
				character_sprite.global_position = global_position
			DIR.EAST:
				rotation_degrees = 90
				ray_cast_2d.force_raycast_update()
				if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider().is_in_group("cliff"):
					global_position += Vector2(128, 0)
					log_string = str(self) + " is falling off cliff!"
					falling = true
					killed(kicker)
					die()	
				elif not ray_cast_2d.is_colliding():
					global_position += Vector2(128, 0)
				rotation_degrees = _old_rotation
				character_sprite.global_position = global_position
			DIR.SOUTH:
				rotation_degrees = 180
				ray_cast_2d.force_raycast_update()
				if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider().is_in_group("cliff"):
					global_position += Vector2(0, 128)
					log_string = str(self) + " is falling off cliff!"
					falling = true
					killed(kicker)
					die()
				elif not ray_cast_2d.is_colliding():
					global_position += Vector2(0, 128)
				rotation_degrees = _old_rotation
				character_sprite.global_position = global_position
			DIR.WEST:
				rotation_degrees = 270
				ray_cast_2d.force_raycast_update()
				if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider().is_in_group("cliff"):
					global_position += Vector2(-128, 0)
					log_string = str(self) + " is falling off cliff!"
					falling = true
					killed(kicker)
					die()
				elif not ray_cast_2d.is_colliding():
					global_position += Vector2(-128, 0)
				rotation_degrees = _old_rotation
				character_sprite.global_position = global_position
	SignalBus.combat_log_entry.emit(log_string)

func killed(attacker : CharacterBody2D) -> void:
	if attacker != null:
		attacker.current_xp += current_level*100
	if attacker.is_player and not is_player:
		emit_signal("killed_by_player", team)
		SignalBus.combat_log_entry.emit("Player killed " + str(self.team))		
	if attacker.team == "knight" and not attacker.is_player:
		emit_signal("killed_by_knight", team)
		SignalBus.combat_log_entry.emit(str(attacker.team) + " killed " + str(self.team))
	elif attacker.team == "orc" and not is_player:
		emit_signal("killed_by_orc", team)
		SignalBus.combat_log_entry.emit(str(attacker.team) + " killed " + str(self.team))
	elif is_player:
		SignalBus.combat_log_entry.emit("You were killed by " + str(attacker.team))

func hit(attacker:CharacterBody2D, glancing_blow : bool) -> void:
	if glancing_blow:
		current_health -= attacker.current_attack_damage/2
	else:
		current_health -= attacker.current_attack_damage
	blood_particle.restart()
	blood_particle.emitting = true
	var flash_tween = create_tween()
	character_sprite.self_modulate = Color(3, 3, 3, 1)
	flash_tween.tween_property(character_sprite, "self_modulate", Color(1, 1, 1, 1), 0.1)
	SignalBus.emit_signal("health_signal", current_health, base_health, self)
	if current_health <= 0:
		killed(attacker)
		die()
	else:
		var log_string : String
		if not is_player:
			log_string = str(self.team) + " hit by " + str(attacker.team) + " for " + str(attacker.current_attack_damage) + " damage!"
		else:
			log_string = "Player hit by " + str(attacker.team) + " for " + str(attacker.current_attack_damage) + " damage!"
		SignalBus.combat_log_entry.emit(log_string)
		cooldown_time_health_regen = current_health_regen
		character_sprite.play("hit")
		shadow_sprite.play("hit")

func die() -> void:
	add_to_group("dead")
	z_index = 0
	for child in get_children():
		if not child.name == "BloodParticle" and not child == player_camera:
			child.queue_free()
		else:
			get_tree().create_timer(10.0).timeout.connect(child.queue_free)
	character_sprite = AnimatedSprite2D.new()
	character_sprite.sprite_frames = ResourceLoader.load("res://character/" + team + "/" + team + "_spriteframes.tres")
	add_child(character_sprite)
	character_sprite.play("die")
	var new_tween = create_tween()
	new_tween.tween_property(character_sprite, "self_modulate", Color(1.5, 1.5, 1.5, 0.8), 5.0)
	remove_from_group(team)
	if is_player:
		is_player = false
		get_tree().create_timer(2.0).timeout.connect(get_parent().spawn_player)
	
func _on_health_regen_timeout() -> void:
	current_health += 1
	if current_health > base_health:
		current_health = base_health
	cooldown_time_health_regen = current_health_regen
	SignalBus.emit_signal("health_signal", current_health, base_health, self)

func _on_attack_area_entered(area: Area2D) -> void:
	var _target = area.get_parent()
	var log_string : String
	if _target is CharacterBody2D:
		if is_kicking:
			_target.kicked(self, facing_direction)
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Body"
			audio_stream_player_2d.play()
			strike_shape.set_deferred("disabled" , true)
			return
		elif _target.block_direction == attack_direction:
			log_string = "Player: " + str(_target.is_player) + " " + str(_target.team) + " blocked Player: " + str(is_player) + " " + str(self.team) + " attack from direction: " + str(attack_direction)
			SignalBus.combat_log_entry.emit(log_string)
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Wooden"
			audio_stream_player_2d.play()
			spark_particle.emitting = true
		elif _target.attack_direction == attack_direction:
			log_string = "Player: " + str(_target.is_player) + " " + str(_target.team) + " parried Player: " + str(is_player) + " " + str(self.team) + " attack from direction: " + str(attack_direction)
			SignalBus.combat_log_entry.emit(log_string)
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Metal Armour"
			audio_stream_player_2d.play()
			spark_particle.emitting = true
			_target.hit(self, true)
		else:
			_target.hit(self, false)
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Sword And Swipe"
			audio_stream_player_2d.play()
