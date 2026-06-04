extends FloorBase

func _ready() -> void:
	await GameManager.show_dialogue("floor4_intro")

	$CanvasLayer/StairsDownButton.pressed.connect(go_down)
	$CanvasLayer/StairsUpButton.pressed.connect(go_up)
	$CanvasLayer/MemoryButton.pressed.connect(_launch_memory)
	GameManager.minigame_completed.connect(_on_minigame_done)
	$CanvasLayer/MemoryButton.disabled = GameManager.ss.is_minigame_cleared("memory")
	GameManager.stamina_changed.connect(_on_stamina_changed)
	_update_button()

func _on_stamina_changed(_value: int) -> void:
	_update_button()

func _launch_memory() -> void:
	GameManager.launch_minigame("res://scenes/minigames/memory.tscn")

func _on_minigame_done(id: String, success: bool) -> void:
	if id == "memory":
		$CanvasLayer/MemoryButton.disabled = GameManager.ss.is_minigame_cleared("memory")
	if success:
		await GameManager.show_dialogue("floor4_post")

func _update_button() -> void:
	if not has_node("CanvasLayer/StairsDownButton"):
		return
	var btn = $CanvasLayer/StairsDownButton
	var stamina = GameManager.ss.get_stamina()
	var can_afford = stamina >= 8
	btn.text = "Go Down (%d/8 stamina)" % stamina
	btn.modulate = Color(1, 1, 1) if can_afford else Color(1, 0.4, 0.4)
