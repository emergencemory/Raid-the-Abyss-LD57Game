extends CanvasLayer
class_name Menu

@onready var resume: Button = $MenuDivider/TitleScreen/GameControls/Resume

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_start_pressed() -> void:
	SignalBus.start_game.emit()
	resume.show()

func _on_resume_pressed() -> void:
	SignalBus.emit_signal("change_pause")



func _on_sfx_volume_value_changed(value:float) -> void:
	SignalBus.sfx_volume_slider_changed.emit(value)

func _on_music_volume_value_changed(value:float) -> void:
	SignalBus.music_volume_slider_changed.emit(value)

func _on_quit_pressed() -> void:
	SignalBus.quit_game.emit()
