extends Node2D
class_name GameManager

@onready var match_manager_scene : PackedScene = preload("res://map/match_manager.tscn")
@onready var menu_scene : PackedScene = preload("res://ui/menu.tscn")
@onready var map_scene : PackedScene = preload("res://map/map.tscn")
@onready var loading_screen : PackedScene = preload("res://ui/loading_screen.tscn")
@onready var background : CanvasLayer = $Background
@onready var soundtrack_player: AudioStreamPlayer2D = $Background/SoundtrackPlayer
@onready var game_over_scene : PackedScene = preload("res://ui/game_over.tscn")

var game_over
var menu
var map
var match_manager
var loading_screen_instance
var loading_screen_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	loading_screen_instance = loading_screen.instantiate()
	background.add_child(loading_screen_instance)
	menu = menu_scene.instantiate()
	add_child(menu)
	SignalBus.reset_keybindings.connect(_on_reset_keybindings)
	SignalBus.start_game.connect(start_game)
	SignalBus.sfx_volume_slider_changed.connect(set_sfx_volume)
	SignalBus.music_volume_slider_changed.connect(set_music_volume)
	SignalBus.quit_game.connect(quit)
	SignalBus.change_pause.connect(_pause_unpause)
	SignalBus.next_layer.connect(next_layer)
	SignalBus.player_move.connect(_move_soundtrack)
	SignalBus.cue_game_over.connect(_on_game_over)
	loading_screen_instance.hide()

func next_layer() -> void:
	loading_screen_instance.show()
	background.layer = 5
	loading_screen_timer = 0.0
	set_physics_process(true)

func _on_game_over(_highest_level: int) -> void:
	loading_screen_instance.show()
	background.layer = 5
	loading_screen_timer = 0.0
	set_physics_process(true)
	if map:
		map.queue_free()
	if game_over:
		game_over.queue_free()
	menu.resume.visible = false
	game_over = game_over_scene.instantiate()
	add_child(game_over)

func start_game() -> void:
	loading_screen_instance.show()
	background.layer = 5
	if map:
		map.queue_free()
	if match_manager:
		match_manager.queue_free()
	map = map_scene.instantiate()
	add_child(map)
	match_manager = match_manager_scene.instantiate()
	add_child(match_manager)
	_pause_unpause()
	loading_screen_timer = 0.0
	set_physics_process(true)

func _on_loading_screen_timeout() -> void:
	loading_screen_instance.hide()
	background.layer = -1

func _physics_process(delta: float) -> void:
	if loading_screen_timer <= 1.5:
		loading_screen_timer += delta
		SignalBus.emit_signal("loading_screen_timer", loading_screen_timer)
	else:
		_on_loading_screen_timeout()
		loading_screen_timer = 0.0
		set_physics_process(false)

func set_sfx_volume(value:float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)

func set_music_volume(value:float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)

func _on_reset_keybindings() -> void:
	if menu:
		var resume : bool = menu.resume.visible
		menu.queue_free()
		menu = menu_scene.instantiate()
		add_child(menu)
		menu.resume.visible = resume
	else:
		printerr("No menu instance to reset.")

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		_pause_unpause()
			

func _pause_unpause() -> void:
	if menu.visible:
		get_tree().paused = false
		menu.hide()
		if map != null and match_manager != null:
			map.show()
			match_manager.show()
			SignalBus.emit_signal("hide_hud", false)
	else:	
		if map != null and match_manager != null and map.visible and match_manager.visible:
			map.hide()
			match_manager.hide()
			SignalBus.emit_signal("hide_hud", true)
		get_tree().paused = true
		menu.show()

func quit() -> void:
	get_tree().quit()

func _move_soundtrack(player_pos: Vector2) -> void:
	soundtrack_player.position = player_pos
