extends Node

# ── signals (re-emitted from C++ so the rest of the game doesn't care) ────────
signal stamina_changed(new_value: int)
signal hearts_changed(new_value: int)
signal minigame_completed(minigame_id: String, success: bool)

# ── C++ system (Autoload named "PSTEStamina" in Project Settings) ───────────
@onready var ss = get_node("/root/PSTEStamina")

# dialogue
func show_dialogue(key: String) -> void:
	var raw: Array = Dialogues.DIALOGUES.get(key, [])
	if raw.is_empty():
		push_warning("GameManager: no dialogue found for key '%s'" % key)
		return
	var db = get_tree().get_first_node_in_group("dialogue_box")
	if db == null:
		push_warning("GameManager: no node in group 'dialogue_box' found")
		return
	var lines: Array[String] = []
	for item in raw:
		lines.append(str(item))

	await db.start(lines)

		
# ── game state ────────────────────────────────────────────────────────────────
var current_floor: int = 6
var elevator_unlocked: bool = false
var secret_key: bool = false
var inventory: Array[String] = []
var game_flags: Dictionary = {}

func _ready() -> void:
	# forward C++ signals outward
	ss.stamina_changed.connect(func(v): stamina_changed.emit(v))
	ss.hearts_changed.connect(func(v):  hearts_changed.emit(v))

	ss.player_died.connect(_on_player_died)
	ss.player_exhausted.connect(_on_player_exhausted)

	game_flags["floor6_unlocked"] = true

# ── traversal ─────────────────────────────────────────────────────────────────

func try_go_down(from_floor: int) -> bool:
	return ss.try_go_down(from_floor)   # C++ handles cost + exhaustion signal

func go_up() -> void:
	ss.go_up()  # free, no-op in C++ — just here for symmetry

# ── stamina / heart shortcuts ─────────────────────────────────────────────────

func gain_stamina(amount: int) -> void:   ss.gain_stamina(amount)
func lose_heart() -> void:                ss.lose_heart()
func gain_heart() -> void:                ss.gain_heart()
func rest_at_bench() -> void:             ss.rest()

# ── minigame ──────────────────────────────────────────────────────────────────

func launch_minigame(scene_path: String) -> void:
	var container = get_tree().get_first_node_in_group("room_container")
	container.hide()
	if container.get_child_count() > 0:
		for child in container.get_child(0).get_children():
			if child is CanvasLayer:
				child.hide()
	var mg   = load(scene_path).instantiate()
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	get_tree().root.add_child(canvas)
	canvas.add_child(mg)
	mg.completed.connect(_on_minigame_done.bind(mg, canvas))

func _on_minigame_done(success: bool, mg: Node, canvas: CanvasLayer) -> void:
	var container = get_tree().get_first_node_in_group("room_container")
	container.show()
	if container.get_child_count() > 0:
		for child in container.get_child(0).get_children():
			if child is CanvasLayer:
				child.show()

	minigame_completed.emit(mg.minigame_id, success)

	if success:
		ss.gain_heart()
		ss.on_minigame_cleared(mg.minigame_id)
		# floor 1 secret condition check
		if mg.minigame_id == "floor1_minigame" and mg.get("secret_condition_met"):
			ss.trigger_adrenaline()
	else:
		ss.lose_heart()

	canvas.queue_free()
	
# ── internal signal handlers ──────────────────────────────────────────────────

func _on_player_died() -> void:
	_do_respawn()

func _on_player_exhausted() -> void:
	# feint — reset position only
	GameManager.ss.respawn()
	current_floor = 6
	change_room("res://scenes/rooms/Floor6.tscn")
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_exhaustion_message"):
		hud.show_exhaustion_message("You collapse from exhaustion...")

func _do_respawn() -> void:
	ss.respawn()
	current_floor = 6
	change_room("res://scenes/rooms/Floor6.tscn")

# ── room management ───────────────────────────────────────────────────────────

func change_room(scene_path: String) -> void:
	var container = get_tree().get_first_node_in_group("room_container")
	if container.get_child_count() > 0:
		container.get_child(0).queue_free()
	container.add_child(load(scene_path).instantiate())

# ── inventory / flags ─────────────────────────────────────────────────────────

func add_to_inventory(item: String) -> void:
	if item not in inventory: inventory.append(item)

func set_flag(key: String, value: Variant) -> void:  game_flags[key] = value
func get_flag(key: String, default: Variant = false) -> Variant:
	return game_flags.get(key, default)
