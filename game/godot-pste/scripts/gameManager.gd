extends Node

# signals
signal stamina_changed(new_value: int)
signal hearts_changed(new_value: int)
signal minigame_completed(minigame_id: String, success: bool)

# stats
var stamina: int = 10
var max_stamina: int = 10
var hearts: int = 3
var max_hearts: int = 3

# gamestates
var current_floor: int = 6
var elevator_unlocked: bool = false
var secret_key: bool = false
var inventory: Array[String] = []
var game_flags: Dictionary = {}

# stamina cost (set for maximum ragebait, you can't directly run down from stairs)
var stair_costs: Dictionary = {
	6: 1,
	5: 2,
	4: 2,
	3: 3,
	2: 3,
	1: 4
}

func use_stairs(from_floor: int) -> bool:
	var cost = stair_costs.get(from_floor, 1)
	if stamina >= cost:
		stamina -= cost
		stamina_changed.emit(stamina)
		return true
	else:
		# not enough stamina
		return false

func gain_stamina(amount: int) -> void:
	stamina = min(stamina + amount, max_stamina)
	stamina_changed.emit(stamina)

func lose_heart() -> void:
	hearts -= 1
	hearts_changed.emit(hearts)
	if hearts <= 0 or stamina <= 0:
		respawn()

func gain_heart() -> void:
	hearts = min(hearts + 1, max_hearts)
	hearts_changed.emit(hearts)

func rest_at_bench() -> void:
	stamina = max_stamina
	hearts = max_hearts
	stamina_changed.emit(stamina)
	hearts_changed.emit(hearts)

func respawn() -> void:
	stamina = max_stamina
	hearts = max_hearts
	current_floor = 6
	stamina_changed.emit(stamina)
	hearts_changed.emit(hearts)
	change_room("res://scenes/rooms/Floor6.tscn")

func change_room(scene_path: String) -> void:
	var container = get_tree().get_first_node_in_group("room_container")
	if container.get_child_count() > 0:
		container.get_child(0).queue_free()
	var new_room = load(scene_path).instantiate()
	container.add_child(new_room)

func launch_minigame(scene_path: String) -> void:
	var mg = load(scene_path).instantiate()
	get_tree().root.add_child(mg)
	mg.completed.connect(_on_minigame_done.bind(mg))

func _on_minigame_done(success: bool, mg: Node) -> void:
	minigame_completed.emit(mg.minigame_id, success)
	if success:
		gain_heart()
	else:
		lose_heart()
	mg.queue_free()

func add_to_inventory(item: String) -> void:
	if item not in inventory:
		inventory.append(item)

func set_flag(key: String, value: Variant) -> void:
	game_flags[key] = value

func get_flag(key: String, default: Variant = false) -> Variant:
	return game_flags.get(key, default)
