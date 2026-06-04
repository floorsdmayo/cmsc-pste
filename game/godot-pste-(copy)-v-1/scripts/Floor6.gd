extends FloorBase

func _ready() -> void:
	$CanvasLayer/StairsDownButton.pressed.connect(go_down)
	$CanvasLayer/StairsUpButton.pressed.connect(go_up)
	$CanvasLayer/BenchButton.pressed.connect(_on_bench)

func _on_bench() -> void:
	GameManager.rest_at_bench()
