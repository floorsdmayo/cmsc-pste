extends FloorBase

func _ready() -> void:
	$CanvasLayer/StairsDownButton.pressed.connect(go_down)
	$CanvasLayer/StairsUpButton.pressed.connect(go_up)
	$CanvasLayer/JigsawButton.pressed.connect(_launch_jigsaw)
	GameManager.minigame_completed.connect(_on_minigame_done)
	$CanvasLayer/JigsawButton.disabled = GameManager.ss.is_minigame_cleared("jigsaw")
	GameManager.stamina_changed.connect(_on_stamina_changed)
	_update_button()

func _on_stamina_changed(_value: int) -> void:
	_update_button()

func _launch_jigsaw() -> void:
	GameManager.launch_minigame("res://scenes/minigames/jigsaw.tscn")

func _on_minigame_done(id: String, success: bool) -> void:
	if id == "jigsaw":
		$CanvasLayer/JigsawButton.disabled = GameManager.ss.is_minigame_cleared("jigsaw")

func _update_button() -> void:
	if not has_node("CanvasLayer/StairsDownButton"):
		return
	var btn = $CanvasLayer/StairsDownButton
	var stamina = GameManager.ss.get_stamina()
	var can_afford = stamina >= 8
	btn.text = "Go Down (%d/8 stamina)" % stamina
	btn.modulate = Color(1, 1, 1) if can_afford else Color(1, 0.4, 0.4)
