extends RefCounted
class_name GameDataResource

const character_data: Dictionary = {
    "base_health": 2,
    "attack_damage": 1,
    "attack_cooldown": 1.0,
	"attack_speed": 1.0,
    "block_duration": 1.5,
    "block_cooldown": 1.0,
    "speed": 30.0,
    "move_cooldown": 1.0,
    "kick_stun": 0.7,
    "kick_cooldown": 10.0,
	"health_regen": 10.0,
	"base_level": 1,
	"base_xp": 0,
	"base_xp_to_next_level": 100,
	"base_xp_to_next_level_multiplier": 1.5,
	"level_up_multiplier": 1.2,
	"level_up_addition": 1
}

const boss_data: Dictionary = {
	"base_health": 20,
	"base_speed": 13.0,
	"move_cooldown": 2.3,
	"attack_from_right_damage": 10,
	"attack_from_right_cooldown": 10.0,
	"attack_from_right_speed": 1.0,
	"attack_from_left_damage": 5,
	"attack_from_left_cooldown": 1.0,
	"attack_from_left_speed": 1.0,
	"stomp_damage": 5,
	"stomp_cooldown": 17.0,
	"stomp_speed": 1.0,
	"stomp_stun_duration": 1.0,
	"jump_damage": 5,
	"jump_cooldown": 26.0,
	"jump_speed": 1.0,
	"base_level": 1,
	"base_xp": 0,
	"base_xp_to_next_level": 5000,
	"base_xp_to_next_level_multiplier": 1.5,
	"level_up_multiplier": 1.5,
	"level_up_addition": 20
}