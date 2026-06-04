extends Control

const minigame_id = "find"
signal completed(success: bool)

@export var total_differences: int = 4

var found_differences: Array[int] = []
var elapsed_time: float = 0.0
var game_active: bool = false

@onready var status_label = $MarginContainer/VBox/StatusLabel
@onready var timer_label  = $MarginContainer/VBox/TimerLabel
@onready var left_image   = $MarginContainer/VBox/HBox/LeftImage
@onready var right_image  = $MarginContainer/VBox/HBox/RightImage

func _ready() -> void:
	left_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	left_image.clip_contents = true
	right_image.clip_contents = true
	left_image.custom_minimum_size = Vector2(560, 540)
	right_image.custom_minimum_size = Vector2(560, 540)
	#get_tree().get_first_node_in_group("room_container").hide()
	_update_status()
	game_active = true

func _process(delta: float) -> void:
	if not game_active:
		return
	elapsed_time += delta
	timer_label.text = "Time: %.1fs" % elapsed_time

func _input(event: InputEvent) -> void:
	if not game_active:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var right_rect = Rect2(right_image.global_position, right_image.size)
	if not right_rect.has_point(event.global_position):
		return

	var clicked = false
	for spot in get_tree().get_nodes_in_group("difference_hotspot"):
		if spot == null or not is_instance_valid(spot):
			continue
		if spot.get_parent() != right_image:
			continue

		if _point_in_area2d(spot, event.global_position):
			clicked = true
			var diff_id: int = spot.get_meta("diff_id", -1)
			if diff_id != -1 and diff_id not in found_differences:
				_mark_found(diff_id)

	if not clicked:
		_wrong_guess()

func _point_in_area2d(area: Area2D, global_point: Vector2) -> bool:
	for child in area.get_children():
		if not child is CollisionShape2D:
			continue
		var shape = child.shape
		if shape == null:
			continue
		var local_point = child.global_transform.affine_inverse() * global_point
		if shape is RectangleShape2D:
			var half = (shape as RectangleShape2D).size * 0.5
			if abs(local_point.x) <= half.x and abs(local_point.y) <= half.y:
				return true
		elif shape is CircleShape2D:
			if local_point.length() <= (shape as CircleShape2D).radius:
				return true
		elif shape is CapsuleShape2D:
			var cap = shape as CapsuleShape2D
			var half_h = max(cap.height * 0.5 - cap.radius, 0.0)
			var closest = Vector2(0, clamp(local_point.y, -half_h, half_h))
			if (local_point - closest).length() <= cap.radius:
				return true
	return false

func _mark_found(diff_id: int) -> void:
	found_differences.append(diff_id)
	_place_marker(diff_id, left_image)
	_place_marker(diff_id, right_image)
	_flash_correct()
	_update_status()
	if found_differences.size() >= total_differences:
		_on_win()

func _place_marker(diff_id: int, parent: TextureRect) -> void:
	for spot in get_tree().get_nodes_in_group("difference_hotspot"):
		if spot == null or not is_instance_valid(spot):
			continue
		if spot.get_meta("diff_id", -1) != diff_id:
			continue
		if spot.get_parent() != parent:
			continue

		# Persistent checkmark dot that stays after pulse fades
		var dot = ColorRect.new()
		dot.color = Color(0.2, 1.0, 0.4, 0.85)
		dot.size = Vector2(16, 16)
		dot.position = spot.position - dot.size * 0.5
		parent.add_child(dot)

		# Pulse ring — grows and fades out
		var ring = Panel.new()
		ring.self_modulate = Color(0.2, 1.0, 0.4, 0.9)
		ring.size = Vector2(20, 20)
		ring.pivot_offset = Vector2(10, 10)
		ring.position = spot.position - ring.size * 0.5

		# Style it as a circle outline using a StyleBoxFlat
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = Color(0.2, 1.0, 0.4, 0.9)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.corner_radius_top_left = 999
		style.corner_radius_top_right = 999
		style.corner_radius_bottom_left = 999
		style.corner_radius_bottom_right = 999
		ring.add_theme_stylebox_override("panel", style)
		parent.add_child(ring)

		# Animate: scale up and fade out simultaneously
		var tween = create_tween().set_parallel(true)
		tween.tween_property(ring, "scale", Vector2(4.5, 4.5), 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(ring, "self_modulate", Color(0.2, 1.0, 0.4, 0.0), 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(0.6).timeout
		ring.queue_free()
		return

func _flash_correct() -> void:
	modulate = Color(0.6, 1.0, 0.6)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.35)

func _wrong_guess() -> void:
	status_label.text = "Wrong! ❌  (-1 heart)"
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").lose_heart()
	modulate = Color(1, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.3)
	await get_tree().create_timer(0.3).timeout
	_update_status()

func _update_status() -> void:
	status_label.text = "Found: %d / %d" % [found_differences.size(), total_differences]

func _on_win() -> void:
	game_active = false
	var first_was_diff3 = found_differences.size() > 0 and found_differences[0] == 3
	var fast = elapsed_time <= 6.7
	var secret_met = first_was_diff3 and fast
	
	status_label.text = "All differences found! 🎉"
	if secret_met:
		status_label.text += " (Something stirs...)"
	
	if has_node("/root/GameManager"):
		if secret_met:
			get_node("/root/GameManager").ss.trigger_adrenaline()
	
	await get_tree().create_timer(1.5).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(true)

func _on_lose_or_give_up() -> void:
	game_active = false
	status_label.text = "Gave up..."
	await get_tree().create_timer(0.8).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(false)
