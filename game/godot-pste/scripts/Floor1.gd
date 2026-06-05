extends FloorBase

func _ready() -> void:
	await GameManager.show_dialogue("floor1_intro")

	$CanvasLayer/StairsUpButton.pressed.connect(go_up)
	$CanvasLayer/FindTheDButton.pressed.connect(_launch_find)
	GameManager.minigame_completed.connect(_on_minigame_done)

	$CanvasLayer/FindTheDButton.disabled = GameManager.ss.is_minigame_cleared("find_the_difference")
func _launch_find() -> void:
	GameManager.launch_minigame("res://scenes/minigames/FindTheDifferenceGame.tscn")

func _on_minigame_done(id: String, success: bool) -> void:
	if id == "find_the_difference":
		$CanvasLayer/FindTheDButton.disabled = GameManager.ss.is_minigame_cleared("find_the_difference")
		if success:
			if GameManager.ss.is_adrenaline_active():
				_start_secret_ending()
			else:
				_start_default_ending()
				
func _start_default_ending() -> void:
	$CanvasLayer/StairsUpButton.hide()
	$CanvasLayer/FindTheDButton.hide()

	await GameManager.show_dialogue("ending_default_intro")
	GameManager.launch_minigame("res://scenes/minigames/RunAwayGame.tscn")
	await GameManager.minigame_completed
	await GameManager.show_dialogue("ending_default_outro")
	# go to credits or title screen here

func _start_secret_ending() -> void:
	# Block all navigation
	$CanvasLayer/StairsUpButton.hide()
	$CanvasLayer/FindTheDButton.hide()
	
	await GameManager.show_dialogue("ending_secret_intro")
	GameManager.launch_minigame("res://scenes/minigames/SnakeGame.tscn")
	await GameManager.minigame_completed
	await GameManager.show_dialogue("ending_secret_outro")
	# go to credits or title screen here
