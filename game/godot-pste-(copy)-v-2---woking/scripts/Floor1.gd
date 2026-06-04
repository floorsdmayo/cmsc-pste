extends FloorBase

func _ready() -> void:
	$CanvasLayer/StairsUpButton.pressed.connect(go_up)
	$CanvasLayer/FindTheDButton.pressed.connect(_launch_find)
	GameManager.minigame_completed.connect(_on_minigame_done)

	$CanvasLayer/FindTheDButton.disabled = GameManager.ss.is_minigame_cleared("find")
func _launch_find() -> void:
	GameManager.launch_minigame("res://scenes/minigames/FindTheDifference.tscn")

func _on_minigame_done(id: String, success: bool) -> void:
	if id == "find":
		$CanvasLayer/FindTheDButton.disabled = GameManager.ss.is_minigame_cleared("find")

#func _start_default_ending() -> void:
	# trigger dialogic timeline then go to floor 0
#	var timeline = Dialogic.start("default_ending_dialogue")
#	timeline.timeline_ended.connect(_go_to_gate)

#func _start_secret_ending() -> void:
	# trigger dialogic timeline then go to floor 7
#	GameManager.set_flag("elevator_to_7_unlocked", true)
#	var timeline = Dialogic.start("secret_ending_dialogue")
#	timeline.timeline_ended.connect(_go_to_floor7)
