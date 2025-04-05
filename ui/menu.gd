extends CanvasLayer
class_name Menu

func _on_start_pressed() -> void:
	SignalBus.start_game.emit()


func _on_volume_value_changed(value:float) -> void:
	SignalBus.volume_slider_changed.emit(value)

func _on_quit_pressed() -> void:
	SignalBus.quit_game.emit()
