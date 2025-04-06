extends Control
class_name InputParser

var player: CharacterManager
var speed: float = 50.0
var held_directions: Dictionary = { "up": false, "down": false, "left": false, "right": false }

func _input(event: InputEvent) -> void:
	# Handle movement inputs
	if event.is_action_pressed("move up"):
		held_directions["up"] = true
		update_direction()
	elif event.is_action_pressed("move down"):
		held_directions["down"] = true
		update_direction()
	elif event.is_action_pressed("move left"):
		held_directions["left"] = true
		update_direction()
	elif event.is_action_pressed("move right"):
		held_directions["right"] = true
		update_direction()
	elif event.is_action_released("move up"):
		held_directions["up"] = false
		update_direction()
	elif event.is_action_released("move down"):
		held_directions["down"] = false
		update_direction()
	elif event.is_action_released("move left"):
		held_directions["left"] = false
		update_direction()
	elif event.is_action_released("move right"):
		held_directions["right"] = false
		update_direction()

	# Handle block input
	if event.is_action_pressed("block"):
		update_block_offset()
		player.update_animations()
	if event.is_action_pressed("attack"):
		update_parry_direction()
		player.update_animations()
	if event.is_action_released("attack"):
		player.attack()

func _physics_process(delta: float) -> void:
	player.global_position += player.velocity * speed * delta

func update_direction() -> void:
	if held_directions["up"]:
		player.velocity = Vector2(0, -1)
		speed = 50
	elif held_directions["down"]:
		player.velocity = Vector2(0, 1)
		speed = 50
	elif held_directions["left"]:
		player.velocity = Vector2(-1, 0)
		speed = 50
	elif held_directions["right"]:
		player.velocity = Vector2(1, 0)
		speed = 50
	else:
		speed = 0
	player.update_directions()
	player.update_animations()

func update_block_offset() -> void:
	if player.velocity == Vector2.ZERO:
		return  # No movement, no facing direction

	# Calculate the facing direction based on velocity
	var facing_direction = player.velocity.normalized()

	# Calculate the mouse position relative to the player
	var mouse_position = get_global_mouse_position() - player.global_position

	# Rotate the facing direction by 45° counterclockwise to get the dividing line
	var dividing_line = facing_direction.rotated(-PI / 4)

	# Determine if the mouse is above or below the dividing line
	var cross_product = dividing_line.cross(mouse_position)

	# If the cross product is positive, the mouse is above the line (offset = 1)
	# If the cross product is negative or zero, the mouse is below the line (offset = 0)
	if cross_product > 0:
		player.block_offset = 0
	else:
		player.block_offset = 1

func update_parry_direction() -> void:
	# Calculate the mouse position relative to the player
	var mouse_position = get_global_mouse_position() - player.global_position
	var mouse_angle = mouse_position.angle()

    # Update the player's parry direction based on the mouse angle
	player.parry_direction = int(angle_to_direction(mouse_angle).angle() / (PI / 4)) % 8
	
func angle_to_direction(angle: float) -> Vector2:
		# Converts an angle in radians to a normalized direction vector
	return Vector2(cos(angle), sin(angle))