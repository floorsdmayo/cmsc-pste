extends FloorBase

func _ready() -> void:
	await GameManager.show_dialogue("floor5_intro")

	$CanvasLayer/StairsDownButton.pressed.connect(go_down)
	$CanvasLayer/StairsUpButton.pressed.connect(go_up)
	$CanvasLayer/WireFixerButton.pressed.connect(_launch_wirefixer)

	GameManager.minigame_completed.connect(_on_minigame_done)
	$CanvasLayer/WireFixerButton.disabled = GameManager.ss.is_minigame_cleared("wirefixer")
	GameManager.stamina_changed.connect(_on_stamina_changed)
	_update_button()
	
func _on_stamina_changed(_value: int) -> void:
	_update_button()

func _launch_wirefixer() -> void:
	GameManager.launch_minigame("res://scenes/minigames/WireFixerGame.tscn")

func _on_minigame_done(id: String, success: bool) -> void:
	if id == "wirefixer":
		$CanvasLayer/WireFixerButton.disabled = GameManager.ss.is_minigame_cleared("wirefixer")
	if success:
		await GameManager.show_dialogue("floor5_post")
