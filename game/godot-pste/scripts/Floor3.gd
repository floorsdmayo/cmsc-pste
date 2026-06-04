extends FloorBase

func _ready() -> void:
	await GameManager.show_dialogue("floor3_intro")
	$CanvasLayer/StairsDownButton.pressed.connect(go_down)
	$CanvasLayer/StairsUpButton.pressed.connect(go_up)
	$CanvasLayer/LockpickerButton.pressed.connect(_launch_lockpicker)
	GameManager.minigame_completed.connect(_on_minigame_done)
	$CanvasLayer/LockpickerButton.disabled = GameManager.ss.is_minigame_cleared("lockpicker")
	GameManager.stamina_changed.connect(_on_stamina_changed)
	_update_button()

func _on_stamina_changed(_value: int) -> void:
	_update_button()

func _launch_lockpicker() -> void:
	GameManager.launch_minigame("res://scenes/minigames/lockpicker.tscn")

func _on_minigame_done(id: String, success: bool) -> void:
	if id == "lockpicker":
		$CanvasLayer/MemoryButton.disabled = GameManager.ss.is_minigame_cleared("lockpicker")
	if success:
		await GameManager.show_dialogue("floor3_post")

func _update_button() -> void:
	if not has_node("CanvasLayer/StairsDownButton"):
		return
	var btn = $CanvasLayer/StairsDownButton
	var stamina = GameManager.ss.get_stamina()
	var can_afford = stamina >= 8
	btn.text = "Go Down (%d/8 stamina)" % stamina
	btn.modulate = Color(1, 1, 1) if can_afford else Color(1, 0.4, 0.4)
