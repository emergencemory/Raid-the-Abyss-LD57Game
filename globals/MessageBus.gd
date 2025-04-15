extends Node
class_name MessageBus

signal reset_keybindings
signal start_game
signal volume_slider_changed(value:float)
signal quit_game
signal combat_log_entry(log_entry: String)
signal health_signal(value: int, base_value: int, character : CharacterBody2D)
signal player_move(player_pos)
signal leveled_up(character : CharacterBody2D, level: int)
signal request_reinforcements(team: String)
signal console_kill_ai
signal console_flush_map
signal wall_hit(char_pos : Vector2)
signal shake_screen()
signal shockwave(char_pos : Vector2)
signal boss_health_signal(value: int, base_value: int, character : CharacterBody2D)
signal reset_input
signal boss_killed