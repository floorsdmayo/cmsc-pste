extends Control

const minigame_id = "find_the_difference"
signal completed(success: bool)

@export var total_differences: int = 5
@export var fast_time_threshold: float = 30.0   # seconds — beats this → unlock secret floor

# --- State ---
var found_differences: Array[int] = []
var elapsed_time: float = 0.0
var game_active: bool = false

# --- Node refs ---
@onready var status_label = $MarginContainer/VBox/StatusLabel
@onready var timer_label  = $MarginContainer/VBox/TimerLabel
@onready var left_image   = $MarginContainer/VBox/HBox/LeftImage
@onready var right_image  = $MarginContainer/VBox/HBox/RightImage

# -------------------------------------------------------
func _ready() -> void:
		# Each image gets roughly half the screen width, full height minus UI space
	var img_width = 560
	var img_height = 540

	left_image.custom_minimum_size = Vector2(img_width, img_height)
	right_image.custom_minimum_size = Vector2(img_width, img_height)

	# STRETCH_KEEP_ASPECT_COVERED = crops/zooms to fill, no black bars
	left_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	right_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	# Clip content that goes outside the rect
	left_image.clip_contents = true
	right_image.clip_contents = true

#	get_tree().get_first_node_in_group("room_container").hide()

	# Connect all hotspot clicks
	for spot in get_tree().get_nodes_in_group("difference_hotspot"):
		spot.input_event.connect(_on_hotspot_clicked.bind(spot))

	_update_status()
	game_active = true

# -------------------------------------------------------
func _process(delta: float) -> void:
	if not game_active:
		return
	elapsed_time += delta
	timer_label.text = "Time: %.1fs" % elapsed_time

# -------------------------------------------------------
func _on_hotspot_clicked(viewport, event: InputEvent, shape_idx: int, hotspot: Node) -> void:
	if not game_active:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var diff_id: int = hotspot.get_meta("diff_id", -1)
	if diff_id == -1:
		push_warning("Hotspot missing 'diff_id' metadata: " + hotspot.name)
		return

	if diff_id in found_differences:
		return 

	_mark_found(diff_id)

func _unhandled_input(event: InputEvent) -> void:
	# A click that hit neither image hotspot = wrong guess → lose a heart
	if not game_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Only penalise if the click is inside one of the two images
		var left_rect  = Rect2(left_image.global_position,  left_image.size)
		var right_rect = Rect2(right_image.global_position, right_image.size)
		if left_rect.has_point(event.global_position) or right_rect.has_point(event.global_position):
			_wrong_guess()

# -------------------------------------------------------
func _mark_found(diff_id: int) -> void:
	found_differences.append(diff_id)

	# Draw a red circle marker on both sides
	_place_marker(diff_id, left_image)
	_place_marker(diff_id, right_image)

	_update_status()

	if found_differences.size() >= total_differences:
		_on_win()

func _place_marker(diff_id: int, parent: Node) -> void:
	# Find the matching hotspot under this image to get its position
	for spot in get_tree().get_nodes_in_group("difference_hotspot"):
		if spot.get_meta("diff_id", -1) == diff_id and spot.get_parent() == parent:
			var marker = ColorRect.new()
			marker.color = Color(1, 0, 0, 0.55)
			marker.size = Vector2(40, 40)
			# Centre over the hotspot's collision shape (approximate)
			marker.position = spot.position - marker.size * 0.5
			parent.add_child(marker)
			return

func _wrong_guess() -> void:
	status_label.text = "Wrong! ❌  (-1 heart)"
	# Tell the global player stats to remove a heart (adjust to your singleton name)
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").lose_heart()
	# Brief red flash
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.3).timeout
	modulate = Color(1, 1, 1)
	_update_status()

func _update_status() -> void:
	status_label.text = "Found: %d / %d" % [found_differences.size(), total_differences]

# -------------------------------------------------------
func _on_win() -> void:
	game_active = false
	var fast = elapsed_time <= fast_time_threshold
	status_label.text = "All differences found! 🎉" + (" (Fast clear!)" if fast else "")

	# Optionally set a flag so Floor 7 secret boss unlocks
	if fast and has_node("/root/GameManager"):
		get_node("/root/GameManager").set("secret_boss_unlocked", true)

	await get_tree().create_timer(1.5).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(true)

func _on_lose_or_give_up() -> void:
	game_active = false
	status_label.text = "Gave up..."
	await get_tree().create_timer(0.8).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(false)
