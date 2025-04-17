extends NinePatchRect

@onready var loading_progress: TextureProgressBar = $ControlContainer/LoadingProgress

func _ready() -> void:
	SignalBus.loading_screen_timer.connect(_on_loading_screen_timer)

func _on_loading_screen_timer(loading_screen_timer: float) -> void:
	loading_progress.value = loading_screen_timer
