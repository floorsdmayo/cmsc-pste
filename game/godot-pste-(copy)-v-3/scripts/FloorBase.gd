class_name FloorBase
extends Node2D

@export var floor_number: int = 1
@export var stairs_down_button: Button

func _ready() -> void:
	GameManager.stamina_changed.connect(_on_stamina_changed)
	_update_button()

func _update_button() -> void:
	if not has_node("CanvasLayer/StairsDownButton"):
		return
	var btn = $CanvasLayer/StairsDownButton
	var stamina = GameManager.ss.get_stamina()
	var can_afford = stamina >= 8
	btn.text = "Go Down (%d/8 stamina)" % stamina
	btn.modulate = Color(1, 1, 1) if can_afford else Color(1, 0.4, 0.4)

func _on_stamina_changed(_new_value: int) -> void:
	_update_button()

func go_down() -> void:
	if floor_number <= 0:
		return
	if GameManager.try_go_down(floor_number):
		GameManager.current_floor = floor_number - 1
		GameManager.change_room("res://scenes/rooms/Floor%d.tscn" % (floor_number - 1))

func go_up() -> void:
	if floor_number == 6 and not GameManager.ss.is_adrenaline_active():
		return
	GameManager.go_up()
	GameManager.current_floor = floor_number + 1
	GameManager.change_room("res://scenes/rooms/Floor%d.tscn" % (floor_number + 1))
