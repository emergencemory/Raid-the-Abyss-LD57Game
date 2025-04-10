extends CanvasLayer
class_name Menu

@onready var resume: Button = $MenuDivider/TitleScreen/MainOptions/Resume
@onready var console_history: TextEdit = $MenuDivider/Controls/DevConsole/ConsoleHistory
@onready var console_input: LineEdit = $MenuDivider/Controls/DevConsole/ConsoleInput
@onready var dev_console: VBoxContainer = $MenuDivider/Controls/DevConsole

var expression = Expression.new()

func _ready() -> void:
	console_input.text_submitted.connect(_on_text_submitted)

func _on_start_pressed() -> void:
	SignalBus.start_game.emit()
	resume.show()

func _on_resume_pressed() -> void:
	self.hide()


func _on_volume_value_changed(value:float) -> void:
	SignalBus.volume_slider_changed.emit(value)

func _on_quit_pressed() -> void:
	SignalBus.quit_game.emit()

##DevConsole

func _on_text_submitted(command) -> void: #, variable_names = [], variable_values = []) -> void:
	var was_at_bottom : bool = console_history.scroll_vertical >= console_history.get_line_count() - console_history.get_visible_line_count() - 2
	var error = expression.parse(command)
	if error != OK:
		console_history.text += command + expression.get_error_text() + "\n"
		print(expression.get_error_text())
		scroll_to_bottom(was_at_bottom)
		return
	var result = expression.execute([], self)
	if not expression.has_execute_failed():
		console_history.text += command + str(result) + "\n"
		scroll_to_bottom(was_at_bottom)

func scroll_to_bottom(was_at_bottom: bool) -> void:
	if was_at_bottom:
		console_history.scroll_vertical = console_history.get_line_count() -2
		#print(str(console_history.get_first_visible_line()), " : ", str(console_history.get_line_count()), " : ", str(console_history.get_visible_line_count()))

func kill_ai():
	SignalBus.emit_signal("console_kill_ai")

func flush_map():
	SignalBus.emit_signal("console_flush_map")
