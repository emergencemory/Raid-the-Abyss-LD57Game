extends CanvasLayer
class_name Hud

@onready var minimap_camera: Camera2D = $MinimapContainer/SubViewport/Camera2D
@onready var health: TextureProgressBar = $StatusAnchor/Status/Health
@onready var attack: TextureProgressBar = $StatusAnchor/Status/Attack
@onready var block: TextureProgressBar = $StatusAnchor/Status/Block
@onready var move: TextureProgressBar = $StatusAnchor/Status/VBoxContainer/Move
@onready var kick: TextureProgressBar = $StatusAnchor/Status/VBoxContainer/Kick
@onready var stage_label: Label = $Progress/StageLabel
@onready var enemies: Label = $Progress/Enemies
@onready var kills: Label = $Progress/Kills
@onready var deaths: Label = $Progress/Deaths
@onready var allies: Label = $Progress/Allies
@onready var allied_kills: Label = $Progress/AlliedKills
@onready var allies_killed: Label = $Progress/AlliesKilled
@onready var _log: TextEdit = $CombatLog/Log
@onready var sub_viewport: SubViewport = $MinimapContainer/SubViewport
@onready var level: Label = $Progress/Level
@onready var check_box: CheckBox = $CombatLog/LabelContainer/CheckBox
@onready var cues_audio_level_up: AudioStreamPlayer2D = $CuesAudio1
@onready var cues_audio_layer_up: AudioStreamPlayer2D = $CuesAudio2
@onready var console_input: LineEdit = $DevConsole/ConsoleInput
@onready var console_history: TextEdit = $DevConsole/ConsoleHistory

var layer_level: int = 0
var attack_cooldown: float = 0.0
var block_cooldown: float = 0.0
var move_cooldown: float = 0.0
var kick_cooldown: float = 0.0
var auto_scroll: bool = true
var expression = Expression.new()

func _ready() -> void:
	console_input.text_submitted.connect(_on_text_submitted)
	SignalBus.combat_log_entry.connect(_on_combat_log_entry)
	SignalBus.leveled_up.connect(_on_level_up)
	check_box.toggled.connect(_on_check_box_toggled)
	SignalBus.player_move.connect(_move_minimap_camera)
	sub_viewport.world_2d = get_parent().get_world_2d()
	

func _move_minimap_camera(player_pos: Vector2) -> void:
	if minimap_camera != null:
		minimap_camera.position = player_pos
		minimap_camera.zoom = Vector2(0.05, 0.05)
		sub_viewport.size = Vector2(256, 128)
	else:
		printerr("Minimap camera is null")

func _on_level_up(character: CharacterBody2D, _level: int) -> void:
	_log.text += character.name + " leveled up to level " + str(_level) + "\n"
	if character.is_player:
		_on_health_changed(character.current_health, character.base_health, character)
		level.text = "Character Level : " + str(_level)
		cues_audio_level_up.play()

func _on_check_box_toggled() -> void:
	if check_box.toggled_on:
		auto_scroll = true
		_log.scroll_vertical = _log.get_line_count()
	else:
		auto_scroll = false

func _on_combat_log_entry(log_entry: String) -> void:
	_log.text += log_entry + "\n"
	if auto_scroll:
		_log.scroll_vertical = _log.get_line_count()

func _on_health_changed(value: int, base_value: int, character : CharacterBody2D) -> void:
	if character.is_player:
		health.max_value = base_value
		health.value = value

func _on_attack_cooldown_started(value: float) -> void:
	attack.value = 0
	attack_cooldown = value
	set_physics_process(true)

func _on_block_cooldown_started(value: float) -> void:
	block.value = 70
	block_cooldown = value
	set_physics_process(true)

func _on_move_cooldown_started(value: float) -> void:
	move.value = 0
	move_cooldown = value
	set_physics_process(true)

func _on_kick_cooldown_started(value: float) -> void:
	kick.value = 0
	kick_cooldown = value
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if attack.value < 100:
		attack.value += (delta / attack_cooldown) * 100
	if block.value < 170:
		block.value += (delta / block_cooldown) * 100
	if move.value < 100:
		move.value += (delta / move_cooldown) * 100
	if kick.value < 100:
		kick.value += (delta / kick_cooldown) * 100
	elif attack.value >= 100 and block.value >= 170 and move.value >= 100 and kick.value >= 100:
		set_physics_process(false)
		
func _on_update_player_hud(_layer:int, current_orcs:int, your_kills:int, your_deaths:int, current_knights:int, knight_kills:int, knight_deaths:int) -> void:
	stage_label.text = "Layer : " + str(_layer)
	if _layer != layer_level:
		layer_level = _layer
		cues_audio_layer_up.play()
	enemies.text = "Current Orcs : " + str(current_orcs)
	kills.text = "Your Kills : " + str(your_kills)
	deaths.text = "Your Deaths : " + str(your_deaths)
	allies.text = "Current Knights : " + str(current_knights)
	allied_kills.text = "Knight Kills : " + str(knight_kills)
	allies_killed.text = "Knight Deaths : " + str(knight_deaths)

##DevConsole

func _on_text_submitted(command) -> void:
	var was_at_bottom : bool = console_history.scroll_vertical >= console_history.get_line_count() - console_history.get_visible_line_count() - 2
	var error = expression.parse(command)
	if error != OK:
		console_history.text += command + expression.get_error_text() + "\n"
		scroll_to_bottom(was_at_bottom)
		return
	var result = expression.execute([], self)
	if not expression.has_execute_failed():
		console_history.text += command + str(result) + "\n"
		scroll_to_bottom(was_at_bottom)

func scroll_to_bottom(was_at_bottom: bool) -> void:
	if was_at_bottom:
		console_history.scroll_vertical = console_history.get_line_count() -2

func kill_ai():
	SignalBus.emit_signal("console_kill_ai")

func flush_map():
	SignalBus.emit_signal("console_flush_map")
