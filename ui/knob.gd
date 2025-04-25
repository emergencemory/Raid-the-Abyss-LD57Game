extends Sprite2D
class_name JoystickKnob

@export var max_extent: float = 70.0
@export var dead_zone: float = 35.0
@onready var joystick_base: Sprite2D = $'../JoystickBase'

var pressing: bool = false
var stick : String = "left"

func _ready() -> void:
	max_extent *= joystick_base.scale.x
	dead_zone *= joystick_base.scale.x

func _process(delta: float) -> void:
	if pressing:
		var mouse_pos = get_global_mouse_position()
		if mouse_pos.distance_to(joystick_base.global_position) <= max_extent:
			global_position = mouse_pos
		else:
			var angle = joystick_base.global_position.angle_to_point(mouse_pos)
			global_position.x = joystick_base.global_position.x + cos(angle) * max_extent
			global_position.y = joystick_base.global_position.y + sin(angle) * max_extent
		var knob_vector: Vector2 = get_vector()
		if knob_vector != Vector2.ZERO:
			SignalBus.emit_signal("joystick_vector_" + stick, knob_vector)
	elif global_position != joystick_base.global_position:
		global_position = lerp(global_position, joystick_base.global_position, delta * 50)
		#SignalBus.emit_signal("joystick_vector_" + stick, Vector2.ZERO)
	else:
		#SignalBus.emit_signal("joystick_vector_" + stick, Vector2.ZERO)
		#SignalBus.emit_signal("reset_input")
		set_process(false)

func _on_button_button_down() -> void:
	pressing = true
	set_process(true)

func _on_button_button_up() -> void:
	pressing = false
	if stick == "right":
		SignalBus.emit_signal("release_attack")
	else:
		SignalBus.emit_signal("reset_input")

func get_vector() -> Vector2:
	var knob_vector: Vector2 = Vector2.ZERO
	if abs(global_position.x - joystick_base.global_position.x) >= dead_zone:
		knob_vector.x = (global_position.x - joystick_base.global_position.x)/max_extent
	if abs(global_position.y - joystick_base.global_position.y) >= dead_zone:
		knob_vector.y = (global_position.y - joystick_base.global_position.y)/max_extent
	return knob_vector
