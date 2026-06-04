extends FloorBase

func _ready() -> void:
	$CanvasLayer/StairsDownButton.pressed.connect(go_down)
	$CanvasLayer/StairsUpButton.pressed.connect(go_up)
	$CanvasLayer/JigsawButton.pressed.connect(_launch_jigsaw)
	GameManager.minigame_completed.connect(_on_minigame_done)

func _launch_jigsaw() -> void:
	GameManager.launch_minigame("res://scenes/minigames/jigsaw.tscn")

func _on_minigame_done(id: String, success: bool) -> void:
	if id == "jigsaw" and success:
		GameManager.gain_stamina(3)
		$CanvasLayer/JigsawButton.disabled = true
