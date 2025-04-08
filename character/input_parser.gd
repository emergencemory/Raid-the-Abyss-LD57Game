extends Control
class_name InputParser

var player: CharacterManager
var speed: float = 50.0
var held_directions: Dictionary = { "up": false, "down": false, "left": false, "right": false }
@onready var hud_scene : PackedScene = preload("res://ui/hud.tscn")
var hud : CanvasLayer
var marker : Marker2D


func _ready() -> void:
	# Initialize the input parser
	
	marker = Marker2D.new()
	add_child(marker)
	# Connect signals or set up any necessary state here

func _input(event: InputEvent) -> void:
	# Handle movement inputs
	if event.is_action_pressed("move up"):
		player.turn(player.DIR.NORTH)
	elif event.is_action_pressed("move down"):
		player.turn(player.DIR.SOUTH)
	elif event.is_action_pressed("move left"):
		player.turn(player.DIR.WEST)
	elif event.is_action_pressed("move right"):
		player.turn(player.DIR.EAST)
	if event.is_action_pressed("kick"):
		player.kick()
	if event.is_action_pressed("block"):
		player.block_to_right = calc_relative_mouse_pos()
		player.block()
	if event.is_action_pressed("attack"):
		player.swing_from_right = calc_relative_mouse_pos()
		player.prepare_attack()
	if event.is_action_released("attack"):
		player.attack()

func calc_relative_mouse_pos() -> bool:
	# Calculate the mouse position relative to the player
	marker.global_position = player.global_position
	marker.look_at(get_global_mouse_position())
	var mouse_angle = wrapf(marker.global_rotation_degrees - 90, 0, 359)
	#print("Mouse angle: ", mouse_angle)
	# Get the player's facing angle in degrees
	var facing_angle = player.rotation_degrees
	#print("Facing angle: ", facing_angle)# Calculate the relative angle
	var relative_angle = wrapf(mouse_angle - facing_angle, 0, 359)
	#print("Relative angle: ", relative_angle)
	# Determine if the mouse is to the left or right
	if relative_angle < 180:
		#print("Mouse is to the left")
		return false  # Mouse is to the left
	else:
		#print("Mouse is to the right")
		return true  # Mouse is to the right
