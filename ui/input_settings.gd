extends VBoxContainer
class_name InputSettings


@onready var input_button_scene : PackedScene = preload("res://ui/input_button.tscn")

var is_remapping :bool = false
var action_to_remap = null
var remapping_button = null

var input_actions : Dictionary = {
	"move up": "W",
	"move down": "S",
	"move left": "A",
	"move right": "D",
	"attack": "mouse_1",
	"block": "mouse_2",
	"kick": "E",
	"menu": "Escape",
	"console": "QuoteLeft"
}


func _ready() -> void:
	_load_keybindings()
	_create_action_list()

#browser-saving
#func save_keybinding(action: String, event: String) -> void:
	#pass
	#JavaScript.eval("localStorage.setItem(action, event);", [action, event])

func _load_keybindings() -> void:
	for action in input_actions.keys():
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		var key_name :String = input_actions[action]
		var input_event : InputEvent
		if key_name.begins_with("mouse_"):
			input_event = InputEventMouseButton.new()
			input_event.button_index = int(key_name.split("_")[1])
		else:
			input_event = InputEventKey.new()
			input_event.keycode = OS.find_keycode_from_string(key_name)
		InputMap.action_add_event(action, input_event)
		print(str(action), " : ", str(input_event))

func _create_action_list() -> void:
	for item in self.get_children():
		item.queue_free()
	
	for action in input_actions.keys():
		var button : Button = input_button_scene.instantiate()
		var action_label : Label = button.find_child("LabelAction")
		var input_label : Label = button.find_child("LabelInput")
		
		action_label.text = action
		
		var events : Array = InputMap.action_get_events(action)
		print(str(action), " : " ,str(events))
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" (Physical)")
		else: 
			input_label.text = ""
			
		self.add_child(button)
		button.pressed.connect(_on_input_button_pressed.bind(button, action))

func _on_input_button_pressed(button : Button, action : String) -> void:
	if !is_remapping:
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		button.find_child("LabelInput").text = "Press key to bind..."
	pass

func _input(event) -> void:
	if is_remapping:
		if (
			event is InputEventKey or
			(event is InputEventMouseButton && event.pressed)
		):
			if event is InputEventMouseButton && event.double_click:
				event.double_click = false
				
			InputMap.action_erase_events(action_to_remap)
			
			#logic to remove duplicates
			for action in input_actions:
				if InputMap.action_has_event(action, event):
					InputMap.action_erase_event(action, event)
					var buttons_with_action = self.get_children().filter(func(button):
						return button.find_child("LabelAction").text == input_actions[action]
					)
					for button in buttons_with_action:
						button.find_child("LabelInput").text = ""
						
			InputMap.action_add_event(action_to_remap, event)
			_update_action_list(remapping_button, event)
			
			is_remapping = false
			action_to_remap = null
			remapping_button = null
			
			accept_event()

func _update_action_list(button, event) -> void:
	button.find_child("LabelInput").text = event.as_text().trim_suffix(" (Physical)")


func _on_reset_button_pressed() -> void:
	SignalBus.emit_signal("reset_keybindings")
