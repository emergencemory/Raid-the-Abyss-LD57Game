extends CanvasLayer

class_name GameOver

@onready var display_rank_c: Control = $DisplayRankC
@onready var display_rank_b: Control = $DisplayRankB
@onready var display_rank_a: Control = $DisplayRankA
@onready var display_rank_s: Control = $DisplayRankS
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var narrative: Label = $MarginContainer/VBoxContainer/Narrative
@onready var level: Label = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer2/Level
@onready var kills: Label = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer2/Kills
@onready var deaths: Label = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/VBoxContainer2/Deaths
@onready var knights_killed: Label = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer/KnightsKilled
@onready var knight_icon: Control = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer/KnightGrid/KnightIcon
@onready var orcs_killed: Label = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer3/VBoxContainer3/OrcsKilled
@onready var boss_icon: Control = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer3/VBoxContainer3/EnemyGrid/BossIcon
@onready var orc_icon: Control = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer3/VBoxContainer3/EnemyGrid/OrcIcon
@onready var knight_grid: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer/KnightGrid
@onready var enemy_grid: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer3/VBoxContainer3/EnemyGrid

var rank_c_narrative: String = "Your raid hurt more than it helped, the enemy retaliation was swift and brutal."
var rank_b_narrative: String = "You fought bravely, but the foe's attacks continue unabaited."
var rank_a_narrative: String = "Your raid severely weakened the enemy's defenses,\n in time the abyss will be cleared."
var rank_s_narrative: String = "You led the raid that cleansed the abyss forever,\n the people of this nation owe you a debt."
var rank: String = "C"

func _ready() -> void:
	SignalBus.game_over.connect(_on_game_over)

func _on_game_over(highest_level: int, deepest_layer: int, player_kills: int, player_deaths: int, enemy_deaths: int, allied_deaths: int) -> void:
	score_label.text = "Game Over\n You cleared " + str(deepest_layer) + " Layers\n Your rank: " + _get_rank( deepest_layer,  player_deaths, enemy_deaths, allied_deaths)
	match rank:
		"C":
			narrative.text = rank_c_narrative
			display_rank_c.visible = true
			display_rank_b.visible = false
			display_rank_a.visible = false
			display_rank_s.visible = false
		"B":
			narrative.text = rank_b_narrative
			display_rank_c.visible = false
			display_rank_b.visible = true
			display_rank_a.visible = false
			display_rank_s.visible = false
		"A":
			narrative.text = rank_a_narrative
			display_rank_c.visible = false
			display_rank_b.visible = false
			display_rank_a.visible = true
			display_rank_s.visible = false
		"S":
			narrative.text = rank_s_narrative
			display_rank_c.visible = false
			display_rank_b.visible = false
			display_rank_a.visible = false
			display_rank_s.visible = true
	level.text = "Highest Level\n"+ str(highest_level)
	kills.text = "Your Kills\n"+ str(player_kills)
	deaths.text = "Your Deaths\n"+ str(player_deaths)
	knights_killed.text = "Fallen Allies\n"+ str(allied_deaths)
	orcs_killed.text = "Defeated Enemies\n"+ str(enemy_deaths)
	for i in range(0, allied_deaths -1):
		var knight_icon_instance = knight_icon.duplicate()
		knight_icon_instance.visible = true
		knight_grid.add_child(knight_icon_instance)
	for i in range(0, enemy_deaths -1):
		var orc_icon_instance = orc_icon.duplicate()
		orc_icon_instance.visible = true
		enemy_grid.add_child(orc_icon_instance)
	for i in range(0, deepest_layer -1):
		var boss_icon_instance = boss_icon.duplicate()
		boss_icon_instance.visible = true
		enemy_grid.add_child(boss_icon_instance)



func _get_rank( deepest_layer: int, player_deaths: int, enemy_deaths: int, allied_deaths: int) -> String:
	if deepest_layer == 1:
		rank = "C"
		return "C"
	#elif allied_deaths > enemy_deaths:
		#rank = "B"
		#return "B"
	elif deepest_layer < 3 or player_deaths > deepest_layer*2:
		rank = "A"
		return "A"
	else:
		rank = "S"
		return "S"




func _on_hide() -> void:
	self.visible = false
	SignalBus.emit_signal("change_pause")