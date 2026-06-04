class_name FloorBase
extends Node2D

@export var floor_number: int = 1

func go_down() -> void:
	if floor_number <= 1:
		return
	if GameManager.try_go_down(floor_number):
		GameManager.current_floor = floor_number - 1
		GameManager.change_room("res://scenes/rooms/Floor%d.tscn" % (floor_number - 1))

func go_up() -> void:
	GameManager.go_up()
	GameManager.current_floor = floor_number + 1
	GameManager.change_room("res://scenes/rooms/Floor%d.tscn" % (floor_number + 1))
