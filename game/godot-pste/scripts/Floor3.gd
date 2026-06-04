extends FloorBase

func _ready() -> void:
	$CanvasLayer/StairsDownButton.pressed.connect(go_down)
	$CanvasLayer/StairsUpButton.pressed.connect(go_up)

	$CanvasLayer/LockpickerButton.pressed.connect(_launch_lockpicker)
	GameManager.minigame_completed.connect(_on_minigame_done)

func _launch_lockpicker() -> void:
	GameManager.launch_minigame("res://scenes/minigames/lockpicker.tscn")

func _on_minigame_done(id: String, success: bool) -> void:
	if id == "lockpicker" and success:
		GameManager.gain_stamina(3)
		$CanvasLayer/LockpickerButton.disabled = true

func _on_bench() -> void:
	GameManager.rest_at_bench()
