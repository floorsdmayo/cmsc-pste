extends FloorBase

func _ready() -> void:
	$CanvasLayer/StairsDownButton.pressed.connect(go_down)
	$CanvasLayer/SnakeButton.pressed.connect(_launch_snake)
	GameManager.minigame_completed.connect(_on_minigame_done)

	
func _launch_snake() -> void:
	GameManager.launch_minigame("res://scenes/minigames/SnakeGame.tscn")

func _on_minigame_done(id: String, success: bool) -> void:
	if id == "snake" and success:
		GameManager.set_flag("boss_defeated", true)
		$CanvasLayer/SnakeButton.disabled = true
		
