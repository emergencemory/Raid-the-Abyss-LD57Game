extends Node2D
class_name GameManager

#TODO MENU : Start, SoundSettings, Quit
#TODO TRES : GameData
#TODO CHARACTER : Move, Attack, Damaged, Die
#TODO AI : Move, Attack, Retreat
#TODO ANIMATION : Bones for weapon, small sprite for the rest in 4 directions
#TODO COMBAT : 
#TODO TILEMAP : FastNoiseLite generate chunks, wall on left, drop on right, darker as move top, lighter as move bottom
#TODO MINIMAP : Blip moves around circular abyss

@onready var menu_scene : PackedScene = preload("res://ui/menu.tscn")
var menu

func _ready() -> void:
	menu = menu_scene.instantiate()
	add_child(menu)
	SignalBus.reset_keybindings.connect(_on_reset_keybindings)
	SignalBus.start_game.connect(start_game)
	SignalBus.volume_slider_changed.connect(set_volume)
	SignalBus.quit_game.connect(quit)


func start_game() -> void:
	pass
	#spawn ai manager
	#spawn input manager
	#spawn match manager
	#spawn tilemap
	#spawn minimap
	#spawn player
	#connect signals

func set_volume(value:float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)
	print(str(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))))
	#volume_slider

func _on_reset_keybindings() -> void:
	if menu:
		menu.queue_free()
		menu = menu_scene.instantiate()
		add_child(menu)
		print("Keybindings reset to default.")
	else:
		print("No menu instance to reset.")

func quit() -> void:
	get_tree().quit()