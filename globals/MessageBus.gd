extends Node
class_name MessageBus

signal reset_keybindings
signal start_game
signal volume_slider_changed(value:float)
signal quit_game
signal combat_log_entry(log_entry: String)
signal health_signal(value: int, base_value: int, character : CharacterBody2D)