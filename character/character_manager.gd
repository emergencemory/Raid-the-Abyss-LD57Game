extends CharacterBody2D
class_name CharacterManager

enum DIR {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

@onready var stun_particle: GPUParticles2D = $StunParticle
@onready var blood_particle: GPUParticles2D = $BloodParticle
@onready var spark_particle: GPUParticles2D = $SparkParticle
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
var is_preparing_attack: bool = false
var attack_charge: float = 0.0
var base_health_regen: float
var current_health_regen: float
var is_turning: bool = false
var attack_windup: bool = false
var cooldown_time_attack: float = 0.0
var cooldown_time_block: float = 0.0
var cooldown_time_turn: float = 0.0
var cooldown_time_move: float = 0.0
var cooldown_time_moving: float = 0.0 
var cooldown_time_kick: float = 0.0
var cooldown_time_health_regen: float = 0.0
var cooldown_time_attack_area: float = 0.0
var cooldown_time_block_area: float = 0.0
var cooldown_time_attack_windup: float = 0.0
var cooldown_time_target: float = 0.0
var is_blocking: bool = false
var stun_on_cooldown: bool = false
var cooldown_time_stun: float = 0.0
var order_ticks : float = 0.0
var player_camera: Camera2D

signal attack_signal(value: float)
signal block_signal(value: float)
signal move_signal(value: float)
signal kick_signal(value: float)
signal killed_by_player(team: String)
signal killed_by_knight(team: String)
signal killed_by_orc(team: String)

#TODO team shader
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
	current_health_regen = base_health_regen
	if is_player:
		SignalBus.emit_signal("health_signal", current_health, base_health, self)

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
	if attack_on_cooldown:
		if cooldown_time_attack > 0:
			cooldown_time_attack -= delta
		else:
			_on_attack_cooldown_timeout()
	if block_on_cooldown:
		if cooldown_time_block > 0:
			cooldown_time_block -= delta
		else:
			_on_block_cooldown_timeout()
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
		if cooldown_time_moving > 0:
			cooldown_time_moving -= delta
		else:
			_on_move_timeout()
	if kick_on_cooldown:
		if cooldown_time_kick > 0:
			cooldown_time_kick -= delta
		else:
			_on_kick_cooldown_timeout()
	if current_health < base_health:
		if cooldown_time_health_regen > 0:
			cooldown_time_health_regen -= delta
		else:
			_on_health_regen_timeout()
	if attack_windup:
		if cooldown_time_attack_windup > 0:
			cooldown_time_attack_windup -= delta
		else:
			_on_attack_begin()
	if is_attacking:
		if cooldown_time_attack_area > 0:
			cooldown_time_attack_area -= delta
		else:
			_on_attack_timeout()
	if is_kicking:
		if cooldown_time_attack_area > 0:
			cooldown_time_attack_area -= delta
		else:
			_on_kick_timeout()
	if is_blocking:
		if cooldown_time_block_area > 0:
			cooldown_time_block_area -= delta
		else:
			_on_block_timeout()
	if has_target:
		if cooldown_time_target > 0:
			cooldown_time_target -= delta
		else:
			_on_target_timeout()
	#if cooldown_time_attack <= 0 and cooldown_time_block <= 0 and cooldown_time_turn <= 0 and cooldown_time_move <= 0 and cooldown_time_kick <= 0 and cooldown_time_health_regen <= 0 and cooldown_time_attack_area <= 0 and cooldown_time_block_area <= 0:
		#print("Cooldowns complete")
		#set_physics_process(false)

func prepare_attack() -> void:
	if is_attacking or attack_windup or is_kicking or attack_on_cooldown:# or is_blocking:
		return
	if swing_from_right:
		attack_from_right_sprite.show()
		attack_from_left_sprite.hide()
		attack_direction = (facing_direction + 1) % 4
	else:
		attack_from_right_sprite.hide()
		attack_from_left_sprite.show()
		attack_direction = (facing_direction - 1) % 4
	is_preparing_attack = true


func attack() -> void:
	attack_from_left_sprite.hide()
	attack_from_right_sprite.hide()
	is_preparing_attack = false
	if attack_on_cooldown or is_attacking or is_blocking or moving or is_turning or is_kicking or attack_windup:
		return
	if swing_from_right:
		character_sprite.play("attack_from_right")
	else:
		character_sprite.play("attack_from_left")
	cooldown_time_attack_windup = current_attack_speed/2
	attack_windup = true
	cooldown_time_attack = current_attack_cooldown
	attack_on_cooldown = true
	set_physics_process(true)
	emit_signal("attack_signal", current_attack_cooldown)

func block() -> void:
	if block_on_cooldown or is_attacking or moving or is_turning or attack_windup or is_kicking or is_blocking:
		return
	block_direction = get_block_direction()
	character_sprite.play("block")
	cooldown_time_block = current_block_cooldown
	block_on_cooldown = true
	cooldown_time_block_area = current_block_duration
	is_blocking = true
	set_physics_process(true)
	emit_signal("block_signal", current_block_cooldown)

func kick() -> void:
	if moving or is_attacking or is_turning or is_blocking or attack_windup or is_turning or is_kicking or kick_on_cooldown:
		return
	cooldown_time_kick = current_kick_cooldown
	kick_on_cooldown = true
	cooldown_time_attack_area = current_attack_speed/2
	is_kicking = true
	strike_shape.set_deferred("disabled", false)
	character_sprite.play("kick")
	emit_signal("kick_signal", current_kick_cooldown)
	set_physics_process(true)
	
func move(direction: int) -> void:
	if direction != facing_direction:
		turn(direction)
		return
	ray_cast_2d.force_raycast_update()
	if ray_cast_2d.is_colliding() or move_on_cooldown or is_attacking or attack_windup or is_kicking or is_blocking or is_turning or moving:
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
	cooldown_time_moving = 30/current_speed
	moving = true
	cooldown_time_move = current_move_cooldown
	move_on_cooldown = true
	if is_player:
		emit_signal("move_signal", current_move_cooldown)
		SignalBus.emit_signal("player_move", position)
	set_physics_process(true)

func turn(direction : int) -> void:
	if is_attacking or moving or is_blocking or attack_windup or is_kicking:
		return
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
				set_physics_process(true)
		DIR.EAST:
			if rotation_degrees == 90:
				move(DIR.EAST)
			else:
				is_turning = true
				var turn_tween = create_tween()
				turn_tween.tween_property(self, "rotation_degrees", 90, 0.15)
				facing_direction = 1
				cooldown_time_turn = 0.15
				set_physics_process(true)
		DIR.SOUTH:
			if rotation_degrees == 180:
				move(DIR.SOUTH)
			else:
				is_turning = true
				var turn_tween = create_tween()
				turn_tween.tween_property(self, "rotation_degrees", 180, 0.15)
				facing_direction = 2
				cooldown_time_turn = 0.15
				set_physics_process(true)
		DIR.WEST:
			if rotation_degrees == 270:
				move(DIR.WEST)
			else:
				is_turning = true
				var turn_tween = create_tween()
				turn_tween.tween_property(self, "rotation_degrees", 270, 0.15)
				facing_direction = 3
				cooldown_time_turn = 0.15
				set_physics_process(true)

func _on_move_timeout() -> void:
	moving = false
	character_sprite.play("idle")

func _on_target_timeout() -> void:
	has_target = false

func _on_attack_cooldown_timeout() -> void:
	attack_on_cooldown = false

func _on_attack_timeout() -> void:
	strike_shape.set_deferred("disabled", true)
	is_attacking = false
	attack_direction = -1
	character_sprite.play("idle")

func _on_attack_begin() -> void:
	strike_shape.set_deferred("disabled", false)
	attack_windup = false
	cooldown_time_attack_area = current_attack_speed/2
	is_attacking = true
	set_physics_process(true)


func _on_block_timeout() -> void:
	is_blocking = false
	block_direction = -1
	block_right_sprite.hide()
	block_left_sprite.hide()

func _on_block_cooldown_timeout() -> void:
	block_on_cooldown = false


func _on_move_cooldown_timeout() -> void:
	move_on_cooldown = false

func _on_kick_timeout() -> void:
	is_kicking = false
	strike_shape.set_deferred("disabled", true)
	character_sprite.play("idle")

func _on_kick_cooldown_timeout() -> void:
	kick_on_cooldown = false

func get_block_direction() -> int:
	if block_to_right:
		block_right_sprite.show()
		block_left_sprite.hide()
		return (facing_direction + 1) % 4
	else:
		block_right_sprite.hide()
		block_left_sprite.show()
		return (facing_direction - 1) % 4


func kicked(stun_duration : float, enemy_facing_dir : int) -> void:
	#apply duration to all actions
	stun_particle.emitting = true
	print("Kicked! Stunned for ", stun_duration, " seconds")
	var kicked_label := Label.new()
	kicked_label.text = "Kicked! Stunned for " + str(stun_duration) + " seconds"
	SignalBus.combat_log_entry.emit(kicked_label.text)
	add_child(kicked_label)
	get_tree().create_timer(1.0).timeout.connect(kicked_label.queue_free)
	character_sprite.play("hit")
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
	emit_signal("kick_signal", stun_duration)
	emit_signal("attack_signal", stun_duration)
	emit_signal("block_signal", stun_duration)
	emit_signal("move_signal", stun_duration)
	var _old_rotation = rotation_degrees
	match enemy_facing_dir:
		DIR.NORTH:
			rotation_degrees = 0
			ray_cast_2d.force_raycast_update()
			if not ray_cast_2d.is_colliding():
				global_position += Vector2(0, -128)
			rotation_degrees = _old_rotation
		DIR.EAST:
			rotation_degrees = 90
			ray_cast_2d.force_raycast_update()
			if not ray_cast_2d.is_colliding():
				global_position += Vector2(128, 0)
			rotation_degrees = _old_rotation
		DIR.SOUTH:
			rotation_degrees = 180
			ray_cast_2d.force_raycast_update()
			if not ray_cast_2d.is_colliding():
				global_position += Vector2(0, 128)
			rotation_degrees = _old_rotation
		DIR.WEST:
			rotation_degrees = 270
			ray_cast_2d.force_raycast_update()
			if not ray_cast_2d.is_colliding():
				global_position += Vector2(-128, 0)
			rotation_degrees = _old_rotation
	set_physics_process(true)

func hit(attacker:CharacterBody2D) -> void:
	current_health -= 1
	blood_particle.restart()
	blood_particle.emitting = true
	var flash_tween = create_tween()
	character_sprite.self_modulate = Color(3, 3, 3, 1)
	flash_tween.tween_property(character_sprite, "self_modulate", Color(1, 1, 1, 1), 0.1)
	SignalBus.emit_signal("health_signal", current_health, base_health, self)
	if current_health <= 0:
		if attacker.is_player and not is_player:
			emit_signal("killed_by_player", team)
			SignalBus.combat_log_entry.emit("Player killed " + str(self.team))		
		if attacker.team == "knight" and not is_player:
			emit_signal("killed_by_knight", team)
			SignalBus.combat_log_entry.emit(str(attacker.team) + " killed " + str(self.team))
		elif attacker.team == "orc" and not is_player:
			emit_signal("killed_by_orc", team)
			SignalBus.combat_log_entry.emit(str(attacker.team) + " killed " + str(self.team))
		elif is_player:
			SignalBus.combat_log_entry.emit("You were killed by " + str(attacker.team))
		die()
		
	else:
		print("Hit! Health: ", current_health)
		var hit_label := Label.new()
		if not is_player:
			hit_label.text = str(self.team) + " hit by " + str(attacker.team) + " for " + str(attacker.current_attack_damage) + " damage!"
		else:
			hit_label.text = "Player hit by " + str(attacker.team) + " for " + str(attacker.current_attack_damage) + " damage!"
		SignalBus.combat_log_entry.emit(hit_label.text)
		add_child(hit_label)
		get_tree().create_timer(1.0).timeout.connect(hit_label.queue_free)
		cooldown_time_health_regen = current_health_regen
		set_physics_process(true)
		character_sprite.play("hit")

func die() -> void:
	add_to_group("dead")
	z_index = 0
	for child in get_children():
		if not child.name == "BloodParticle" or child == player_camera:
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
	if _target is CharacterBody2D:
		if is_kicking:
			print("Kicked!")
			_target.kicked(current_kick_stun_duration, facing_direction)
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Body"
			audio_stream_player_2d.play()
			strike_shape.set_deferred("disabled" , true)
			return
		elif _target.attack_direction == attack_direction:
			print("Parried!" + str(_target.attack_direction) + " " + str(attack_direction))
			var parry_label := Label.new()
			parry_label.text = "Player: " + str(_target.is_player) + " " + str(_target.team) + " parried Player: " + str(is_player) + " " + str(self.team) + " attack from direction: " + str(attack_direction)
			SignalBus.combat_log_entry.emit(parry_label.text)
			add_child(parry_label)
			get_tree().create_timer(1.0).timeout.connect(parry_label.queue_free)
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Metal Armour"
			audio_stream_player_2d.play()
			spark_particle.emitting = true
		elif _target.block_direction == attack_direction:
			print("Blocked!" + str(_target.block_direction) + " " + str(attack_direction))
			var block_label := Label.new()
			block_label.text = "Player: " + str(_target.is_player) + " " + str(_target.team) + " blocked Player: " + str(is_player) + " " + str(self.team) + " attack from direction: " + str(attack_direction)
			SignalBus.combat_log_entry.emit(block_label.text)
			add_child(block_label)
			get_tree().create_timer(1.0).timeout.connect(block_label.queue_free)
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Wooden"
			audio_stream_player_2d.play()
			spark_particle.emitting = true
		else:
			print("Hit!")
			_target.hit(self)
			audio_stream_player_2d["parameters/switch_to_clip"] = "Impact Sword And Swipe"
			audio_stream_player_2d.play()
	else:
		var missed_label := Label.new()
		missed_label.text = str(self) + "Missed!"
		SignalBus.combat_log_entry.emit(missed_label.text)
		add_child(missed_label)
		get_tree().create_timer(1.0).timeout.connect(missed_label.queue_free)
		print("Attack missed!")
