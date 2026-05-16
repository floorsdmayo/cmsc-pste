class_name FloorBase
extends Node2D

@export var floor_number: int = 1
@export var stair_cost: int = 1

func go_down() -> void:
	if GameManager.use_stairs(floor_number):
		GameManager.current_floor = floor_number - 1
		GameManager.change_room("res://scenes/rooms/Floor%d.tscn" % (floor_number - 1))
	else:
		print("Not enough stamina!")

func go_up() -> void:
	if GameManager.use_stairs(floor_number):
		GameManager.current_floor = floor_number + 1
		GameManager.change_room("res://scenes/rooms/Floor%d.tscn" % (floor_number + 1))
	else:
		print("Not enough stamina!")
