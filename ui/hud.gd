extends CanvasLayer
class_name Hud

#TODO streamline to reduce repetition
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

var attack_cooldown: float = 0.0
var block_cooldown: float = 0.0
var move_cooldown: float = 0.0
var kick_cooldown: float = 0.0

func _on_health_changed(value: int, base_value: int) -> void:
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
		#print("attack cooldown progress: ", attack.value)
	if block.value < 170:
		block.value += (delta / block_cooldown) * 100
		#print("block cooldown progress: ", block.value)
	if move.value < 100:
		move.value += (delta / move_cooldown) * 100
		#print("move cooldown progress: ", move.value)e
	if kick.value < 100:
		kick.value += (delta / kick_cooldown) * 100
		#print("kick cooldown progress: ", kick.value, " / ", kick_cooldown)
	elif attack.value >= 100 and block.value >= 170 and move.value >= 100 and kick.value >= 100:
		#print("Cooldowns complete")
		set_physics_process(false)
		
func _on_update_player_hud(_layer:int, current_orcs:int, your_kills:int, your_deaths:int, current_knights:int, knight_kills:int, knight_deaths:int) -> void:
	stage_label.text = "Layer : " + str(_layer)
	enemies.text = "Current Orcs : " + str(current_orcs)
	kills.text = "Your Kills : " + str(your_kills)
	deaths.text = "Your Deaths : " + str(your_deaths)
	allies.text = "Current Knights : " + str(current_knights)
	allied_kills.text = "Knight Kills : " + str(knight_kills)
	allies_killed.text = "Knight Deaths : " + str(knight_deaths)