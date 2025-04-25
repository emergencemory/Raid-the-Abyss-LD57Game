extends CanvasLayer
class_name Hud

@export var touchscreen_toggled: bool = false

@onready var minimap_camera: Camera2D = $PanelContainer/TopRightMargin/MinimapContainer/SubViewport/Camera2D
@onready var hide_map: Button = $TopLeftMargin/TopHUD/HideMap
@onready var sub_viewport: SubViewport = $PanelContainer/TopRightMargin/MinimapContainer/SubViewport
@onready var minimap_container: SubViewportContainer = $PanelContainer/TopRightMargin/MinimapContainer
@onready var nine_patch_rect: NinePatchRect = $PanelContainer/NinePatchRect
@onready var top_right_margin: MarginContainer = $PanelContainer/TopRightMargin
@onready var health: TextureProgressBar = $StatusAnchor/Status/Health
@onready var attack: TextureProgressBar = $StatusAnchor/Status/Attack
@onready var block: TextureProgressBar = $StatusAnchor/Status/Block
@onready var move: TextureProgressBar = $StatusAnchor/Status/VBoxContainer/Move
@onready var kick: TextureProgressBar = $StatusAnchor/Status/VBoxContainer/Kick
@onready var stage_label: Label = $TopLeftMargin/TopHUD/DemonSword/LayerWaveCount
@onready var enemies: Label = $TopLeftMargin/TopHUD/RoundShield/OrcsAlive
@onready var kills: Label = $StatusAnchor/Status/Attack/PlayerKills
@onready var deaths: Label = $StatusAnchor/Status/Block/PlayerDeaths
@onready var allies: Label = $TopLeftMargin/TopHUD/ShieldIcon/KnightsAlive
@onready var allied_kills: Label = $TopLeftMargin/TopHUD/SwordIcon/KnightKills
@onready var allies_killed: Label = $TopLeftMargin/TopHUD/AxeIcon/OrcKills
@onready var _log: TextEdit = $CombatLog/Log
@onready var log_label: Button = $CombatLog/LabelContainer/LogLabel
@onready var level: Label = $StatusAnchor/Status/Health/Level
@onready var check_box: CheckBox = $CombatLog/LabelContainer/CheckBox
@onready var cues_audio_level_up: AudioStreamPlayer2D = $CuesAudio1
@onready var cues_audio_layer_up: AudioStreamPlayer2D = $CuesAudio2
@onready var console_input: LineEdit = $DevConsole/ConsoleInput
@onready var console_history: TextEdit = $DevConsole/ConsoleHistory
@onready var dev_console: VBoxContainer = $DevConsole
@onready var touchscreen_left: MarginContainer = $TouchscreenLeft
@onready var touchscreen_right: MarginContainer = $TouchscreenRight

var layer_level: int = 0
var highest_level: int = 0
var attack_cooldown: float = 0.0
var block_cooldown: float = 0.0
var move_cooldown: float = 0.0
var kick_cooldown: float = 0.0
var auto_scroll: bool = true
var expression = Expression.new()


func _ready() -> void:
	#self.hide()
	console_input.text_submitted.connect(_on_text_submitted)
	SignalBus.combat_log_entry.connect(_on_combat_log_entry)
	SignalBus.leveled_up.connect(_on_level_up)
	check_box.toggled.connect(_on_check_box_toggled)
	SignalBus.player_move.connect(_move_minimap_camera)
	sub_viewport.world_2d = get_parent().get_world_2d()
	SignalBus.hide_hud.connect(_pause_unpause)
	SignalBus.boss_killed.connect(_on_layer_cleared)
	_on_touchscreen_toggled(touchscreen_toggled)

func _pause_unpause(pause:bool) -> void:
	if pause:
		self.hide()
	else:
		self.show()

func _move_minimap_camera(player_pos: Vector2) -> void:
	if minimap_camera != null:
		minimap_camera.position = player_pos
		minimap_camera.zoom = Vector2(0.05, 0.05)
		sub_viewport.size = Vector2(256, 128)
	else:
		printerr("Minimap camera is null")
	cues_audio_layer_up.position = player_pos
	cues_audio_level_up.position = player_pos

func _on_hide_minimap() -> void:
	if top_right_margin.visible:
		hide_map.text = "Show Minimap"
		top_right_margin.hide()
		nine_patch_rect.hide()
		minimap_container.hide()
	else:
		hide_map.text = "Hide Minimap"
		top_right_margin.show()
		nine_patch_rect.show()
		minimap_container.show()

func _on_touchscreen_toggled(toggled_on: bool) -> void:
	touchscreen_left.visible = toggled_on
	touchscreen_right.visible = toggled_on

func _on_level_up(character: CharacterBody2D, _level: int) -> void:
	_log.text += character.team + " leveled up to level " + str(_level) + "\n"
	if character.is_player:
		_on_health_changed(character.current_health, character.base_health, character)
		level.text = "Lvl: " + str(_level)
		cues_audio_level_up.play()
		if highest_level < _level:
			highest_level = _level

func _on_check_box_toggled(toggled_on:bool) -> void:
	if toggled_on:
		auto_scroll = true
		_log.scroll_vertical = _log.get_line_count()
	else:
		auto_scroll = false

func _on_hide_log() -> void:
	if _log.visible:
		log_label.text = "Show Log"
		_log.hide()
		check_box.hide()
	else:
		log_label.text = "Hide Log"
		_log.show()
		check_box.show()
		if auto_scroll:
			_log.scroll_vertical = _log.get_line_count()

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
	if advance_button.visible:
		dialogue_box.modulate.r = sin(dialogue_modulate)
		dialogue_modulate += delta*3
	elif attack.value >= 100 and block.value >= 170 and move.value >= 100 and kick.value >= 100 and not advance_button.visible:
		set_physics_process(false)
		
func _on_update_player_hud(_layer:int, _wave: int, current_orcs:int, your_kills:int, your_deaths:int, current_knights:int, knight_kills:int, knight_deaths:int) -> void:
	stage_label.text = "Layer : " + str(_layer) + "  Wave : " + str(_wave)
	if _layer != layer_level:
		layer_level = _layer
		cues_audio_layer_up.volume_db = -0.5
		cues_audio_layer_up.play()
		var audio_tween = create_tween()
		audio_tween.tween_property(cues_audio_layer_up, "volume_db", -8.0, 1.5)
	enemies.text = str(current_orcs)
	kills.text = "Kills: " + str(your_kills)
	deaths.text = "Deaths : " + str(your_deaths)
	allies.text = str(current_knights)
	allied_kills.text = str(knight_kills)
	allies_killed.text = str(knight_deaths)

##DevConsole
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("console"):
		if dev_console.visible:
			dev_console.hide()
			console_input.release_focus()
		else:
			show()
			dev_console.show()
			console_input.grab_focus()

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

##DialogueBox
@onready var dialogue_container: PanelContainer = $DialogueContainer
@onready var hide_button: Button = $DialogueContainer/HideButton
@onready var round_shield: NinePatchRect = $DialogueContainer/RoundShield
@onready var dialogue_box: MarginContainer = $DialogueContainer/DialogueBox
@onready var forward_button: Button = $DialogueContainer/DialogueBox/VBoxContainer/HBoxContainer/ForwardButton
@onready var back_button: Button = $DialogueContainer/DialogueBox/VBoxContainer/HBoxContainer/BackButton
@onready var retreat_button: Button = $DialogueContainer/DialogueBox/VBoxContainer/HBoxContainer/RetreatButton
@onready var advance_button: Button = $DialogueContainer/DialogueBox/VBoxContainer/HBoxContainer/AdvanceButton
@onready var stay_button: Button = $DialogueContainer/DialogueBox/VBoxContainer/HBoxContainer/StayButton
@onready var _text: Label = $DialogueContainer/DialogueBox/VBoxContainer/Text

var dialogue_modulate: float = 0.0
var dialogue: Array = [
	"To move, Push a direction key (WASD default) to turn your character to face that direction.",
	"Holding or pushing the same direction key as your facing direction moves your character",
	"Block (rtclick default) stops attacks from your right or left, depending on mouse position",
	"Left click prepares an attack from the side of your character your mouse is on",
	"Release left click to attack enemies for 1/2 your level of dmg or break through walls",
	"Holding attack parries attacks from that side of your character for partial damage",
	"Kick (E default) will momentarily stun the enemy in front of you, or knock them off a cliff"
]
var current_dialogue: int = 0
var layer_clear_text : String = "The guardian of this layer is defeated, should we continue the raid?"
var endless_text : String = "Grind until you would like to continue deeper or return to the surface"
var advance_text : String = "More dangerous enemies await"

func _on_next_button_pressed()-> void:
	current_dialogue += 1
	if current_dialogue >= dialogue.size():
		current_dialogue = 0
	_text.text = dialogue[current_dialogue]
	#cyce through dialogue

func _on_previous_button_pressed()-> void:
	current_dialogue -= 1
	if current_dialogue < 0:
		current_dialogue = dialogue.size() - 1
	_text.text = dialogue[current_dialogue]
	#cyce through dialogue

func _on_layer_cleared()-> void:
	dialogue_container.set_anchors_preset(dialogue_container.LayoutPreset.PRESET_CENTER_BOTTOM, true)
	dialogue_box.show()
	round_shield.show()
	hide_button.text = "Hide Dialogue Box"
	if layer_level >= 3:
		_text.text = "You are victorious! Return to the surface for your score (game_over)"
	else:
		_text.text = layer_clear_text
	forward_button.hide()
	back_button.hide()
	advance_button.show()
	retreat_button.show()
	stay_button.show()
	set_physics_process(true)
	dialogue_container.set_anchors_preset(dialogue_container.LayoutPreset.PRESET_CENTER, true)

func _on_hide_button_pressed()-> void:
	if dialogue_box.visible:
		dialogue_box.hide()
		hide_button.text = "Show Dialogue Box"
		round_shield.hide()
		dialogue_container.set_anchors_preset(dialogue_container.LayoutPreset.PRESET_CENTER_BOTTOM, true)
	else:
		dialogue_box.show()
		hide_button.text = "Hide Dialogue Box"
		round_shield.show()
	#hide dialogue or show

func _on_retreat_button_pressed()-> void:
	dialogue_container.set_anchors_preset(dialogue_container.LayoutPreset.PRESET_CENTER_BOTTOM, true)
	SignalBus.emit_signal("player_move", Vector2.ZERO)
	SignalBus.emit_signal("cue_game_over", highest_level)
	#game over

func _on_advance_button_pressed()-> void:
	dialogue_container.set_anchors_preset(dialogue_container.LayoutPreset.PRESET_CENTER_BOTTOM, true)
	forward_button.show()
	back_button.show()
	advance_button.hide()
	stay_button.hide()
	_text.text = advance_text
	SignalBus.emit_signal("next_layer")
	dialogue_box.modulate.r = 1.0
	#advance to next layer

func _on_endless_button_pressed()-> void:
	stay_button.hide()
	_text.text = endless_text
	dialogue_container.set_anchors_preset(dialogue_container.LayoutPreset.PRESET_CENTER_BOTTOM, true)
	#SignalBus.emit_signal("endless_mode")
	#endless mode
