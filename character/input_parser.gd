extends Control
class_name InputParser

@onready var hud_scene : PackedScene = preload("res://ui/hud.tscn")

var touch_input: bool = false
var player: CharacterManager
var speed: float = 50.0
var held_directions: Dictionary = { 
	"up": false, 
	"down": false, 
	"left": false, 
	"right": false,
	"attack": false
	 }
var hud : CanvasLayer
var marker : Marker2D


func _ready() -> void:
	marker = Marker2D.new()
	add_child(marker)
	SignalBus.reset_input.connect(_on_reset_input)
	SignalBus.joystick_vector_left.connect(touch_move)
	SignalBus.joystick_vector_right.connect(touch_prep_attack)
	SignalBus.release_attack.connect(touch_release_attack)
	SignalBus.touch_block_left.connect(touch_block_left)
	SignalBus.touch_block_right.connect(touch_block_right)
	SignalBus.touch_kick_pressed.connect(touch_kick_pressed)

func touch_move(vector: Vector2) -> void:
	if abs(vector.x) > abs(vector.y):
		if vector.x < 0.0:
			held_directions["left"] = true
			held_directions["right"] = false
			held_directions["up"] = false
			held_directions["down"] = false
		else:
			held_directions["left"] = false
			held_directions["right"] = true
			held_directions["up"] = false
			held_directions["down"] = false
	elif vector.y > 0.0:
		held_directions["up"] = false
		held_directions["down"] = true
		held_directions["left"] = false
		held_directions["right"] = false
	else:
		held_directions["up"] = true
		held_directions["down"] = false
		held_directions["left"] = false
		held_directions["right"] = false

func touch_block_left() -> void:
	if player == null or player.is_queued_for_deletion() or player.is_in_group("dead"):
		return
	player.block_to_right = false
	player.block()

func touch_block_right() -> void:
	if player == null or player.is_queued_for_deletion() or player.is_in_group("dead"):
		return
	player.block_to_right = true
	player.block()

func touch_kick_pressed() -> void:
	if player == null or player.is_queued_for_deletion() or player.is_in_group("dead"):
		return
	player.kick()

func touch_prep_attack(vector: Vector2) -> void:
	if player == null or player.is_queued_for_deletion() or player.is_in_group("dead"):
		return
	match player.facing_direction:
		player.DIR.NORTH:
			player.swing_from_right = vector.x > 0.0
		player.DIR.SOUTH:
			player.swing_from_right = vector.x < 0.0
		player.DIR.WEST:
			player.swing_from_right = vector.y < 0.0
		player.DIR.EAST:
			player.swing_from_right = vector.y > 0.0
	held_directions["attack"] = true
	player.prepare_attack()

func touch_release_attack() -> void:
	if player == null or player.is_queued_for_deletion() or player.is_in_group("dead"):
		return
	held_directions["attack"] = false
	player.attack()


func _on_reset_input() -> void:
	for key in held_directions.keys():
		held_directions[key] = false

func _input(event: InputEvent) -> void:
	## Player control inputs
	if player == null or player.is_queued_for_deletion() or player.is_in_group("dead") or touch_input:
		return
	if event.is_action_pressed("move up"):
		player.turn(player.DIR.NORTH)
		held_directions["up"] = true
	if event.is_action_pressed("move down"):
		player.turn(player.DIR.SOUTH)
		held_directions["down"] = true
	if event.is_action_pressed("move left"):
		player.turn(player.DIR.WEST)
		held_directions["left"] = true
	if event.is_action_pressed("move right"):
		player.turn(player.DIR.EAST)
		held_directions["right"] = true
	if event.is_action_released("move up"):
		held_directions["up"] = false
	if event.is_action_released("move down"):
		held_directions["down"] = false
	if event.is_action_released("move left"):
		held_directions["left"] = false
	if event.is_action_released("move right"):
		held_directions["right"] = false
	if event.is_action_pressed("kick"):
		player.kick()
	if event.is_action_pressed("block"):
		player.block_to_right = calc_relative_mouse_pos()
		player.block()
	if event.is_action_pressed("attack"):
		player.swing_from_right = calc_relative_mouse_pos()
		held_directions["attack"] = true
		player.prepare_attack()
	if event.is_action_released("attack"):
		held_directions["attack"] = false
		player.attack()
	if event.is_action_pressed("zoom in"):
		if player.is_queued_for_deletion() or player.is_in_group("dead") or player.player_camera == null or player.player_camera.zoom <= Vector2(0.1, 0.1):
			return
		else:
			player.player_camera.zoom -= Vector2(0.05, 0.05)
	if event.is_action_pressed("zoom out"):
		if player.is_queued_for_deletion() or player.is_in_group("dead") or player.player_camera == null or player.player_camera.zoom >= Vector2(5.0, 5.0):
			return
		else:
			player.player_camera.zoom += Vector2(0.05, 0.05)

func calc_relative_mouse_pos() -> bool:
	## Calculate the mouse position relative to the player
	marker.global_position = player.global_position
	marker.look_at(get_global_mouse_position())
	var mouse_angle = wrapf(marker.global_rotation_degrees - 90, 0, 359)
	# Get the player's facing angle in degrees
	var facing_angle = player.rotation_degrees
	var relative_angle = wrapf(mouse_angle - facing_angle, 0, 359)
	# Determine if the mouse is to the left or right
	if relative_angle < 180:
		return false  # Mouse is to the left
	else:
		return true  # Mouse is to the right

func _physics_process(_delta: float) -> void:
	## Held key movement logic
	if player == null or player.is_queued_for_deletion() or player.is_in_group("dead"):
		return
	if held_directions["up"]:
		if player.facing_direction == player.DIR.NORTH:
			player.move(player.DIR.NORTH)
		else:
			player.turn(player.DIR.NORTH)
	if held_directions["down"]:
		if player.facing_direction == player.DIR.SOUTH:
			player.move(player.DIR.SOUTH)
		else:
			player.turn(player.DIR.SOUTH)
	if held_directions["left"]:
		if player.facing_direction == player.DIR.WEST:
			player.move(player.DIR.WEST)
		else:
			player.turn(player.DIR.WEST)
	if held_directions["right"]:
		if player.facing_direction == player.DIR.EAST:
			player.move(player.DIR.EAST)
		else:
			player.turn(player.DIR.EAST)
	if held_directions["attack"]:
		player.swing_from_right = calc_relative_mouse_pos()

func _on_touchscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		touch_input = true
	else:
		touch_input = false