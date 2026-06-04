extends FloorBase

func _ready() -> void:
	$CanvasLayer/StairsDownButton.pressed.connect(go_down)
	$CanvasLayer/StairsUpButton.pressed.connect(go_up)

	$CanvasLayer/BenchButton.pressed.connect(_on_bench)
	$CanvasLayer/StairsUpButton.disabled = !GameManager.ss.is_adrenaline_active()
	GameManager.stamina_changed.connect(_on_stamina_changed)
	_update_button()
	
func _on_stamina_changed(_value: int) -> void:
	_update_button()

func _on_bench() -> void:
	GameManager.rest_at_bench()
