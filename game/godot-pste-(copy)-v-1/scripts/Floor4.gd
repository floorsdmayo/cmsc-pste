extends FloorBase

func _ready() -> void:
	$CanvasLayer/StairsDownButton.pressed.connect(go_down)
	$CanvasLayer/StairsUpButton.pressed.connect(go_up)
	$CanvasLayer/MemoryButton.pressed.connect(_launch_memory)
	GameManager.minigame_completed.connect(_on_minigame_done)

func _launch_memory() -> void:
	GameManager.launch_minigame("res://scenes/minigames/memory.tscn")

func _on_minigame_done(id: String, success: bool) -> void:
	if id == "memory" and success:
		GameManager.gain_stamina(3)
		$CanvasLayer/MemoryButton.disabled = true
