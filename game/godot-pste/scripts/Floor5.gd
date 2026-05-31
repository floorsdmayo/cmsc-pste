extends FloorBase

func _ready() -> void:
	$CanvasLayer/StairsDownButton.pressed.connect(go_down)
	$CanvasLayer/StairsUpButton.pressed.connect(go_up)
	$CanvasLayer/WireFixerButton.pressed.connect(_launch_wirefixer)
	$CanvasLayer/BenchButton.pressed.connect(_on_bench)
	GameManager.minigame_completed.connect(_on_minigame_done)
	
	# lock stairs up by default
	$CanvasLayer/StairsUpButton.disabled = !GameManager.get_flag("floor6_unlocked")

func _on_bench() -> void:
	GameManager.rest_at_bench()

func _launch_wirefixer() -> void:
	GameManager.launch_minigame("res://scenes/minigames/WireFixerGame.tscn")

func _on_minigame_done(id: String, success: bool) -> void:
	if id == "wirefixer" and success:
		GameManager.gain_stamina(3)
		$CanvasLayer/WireFixerButton.disabled = true
	# unlock stairs if flag was set while on this floor
	$CanvasLayer/StairsUpButton.disabled = !GameManager.get_flag("floor6_unlocked")
