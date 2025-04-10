extends Node2D
class_name GameManager

const MATCH_MGR : Script = preload("res://map/match_manager.gd")

@onready var menu_scene : PackedScene = preload("res://ui/menu.tscn")
@onready var map_scene : PackedScene = preload("res://map/map.tscn")

var menu
var map
var match_manager

#TODO console commands to kill all and nuke tilemap

func _ready() -> void:
	menu = menu_scene.instantiate()
	add_child(menu)
	SignalBus.reset_keybindings.connect(_on_reset_keybindings)
	SignalBus.start_game.connect(start_game)
	SignalBus.volume_slider_changed.connect(set_volume)
	SignalBus.quit_game.connect(quit)

func start_game() -> void:
	if map:
		map.queue_free()
	if match_manager:
		match_manager.queue_free()
	map = map_scene.instantiate()
	add_child(map)
	match_manager = MATCH_MGR.new()
	add_child(match_manager)
	menu.hide()


func set_volume(value:float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)
	print(str(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))))

func _on_reset_keybindings() -> void:
	if menu:
		menu.queue_free()
		menu = menu_scene.instantiate()
		add_child(menu)
		print("Keybindings reset to default.")
	else:
		print("No menu instance to reset.")

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if menu.visible:
			menu.hide()
		else:
			menu.show()

func quit() -> void:
	get_tree().quit()
