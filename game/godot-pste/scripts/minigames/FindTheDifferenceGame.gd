extends Control

const minigame_id = "find_the_difference"
signal completed(success: bool)

@export var total_differences: int = 4
@export var fast_time_threshold: float = 30.0

var found_differences: Array[int] = []
var elapsed_time: float = 0.0
var game_active: bool = false

# ─── Asset auto-detection paths ───────────────────────────────────────────────
const FONT_SEARCH_PATHS := [
	"res://assets/minigames/findthedifference/",
	"res://assets/fonts/",
	"res://fonts/",
	"res://ui/fonts/",
]
const SOUND_SEARCH_PATHS := [
	"res://assets/minigames/findthedifference/",
	"res://assets/sounds/",
	"res://assets/audio/",
	"res://sounds/",
	"res://audio/",
]
const FONT_EXTENSIONS   := ["ttf", "otf", "woff", "tres"]
const SOUND_EXTENSIONS  := ["wav", "ogg", "mp3"]

var _sfx_correct:    AudioStreamPlayer = null
var _sfx_wrong:      AudioStreamPlayer = null
var _sfx_win:        AudioStreamPlayer = null

# ─── Node refs ────────────────────────────────────────────────────────────────
@onready var status_label = $MarginContainer/VBox/StatusLabel
@onready var timer_label  = $MarginContainer/VBox/TimerLabel
@onready var left_image   = $MarginContainer/VBox/HBox/LeftImage
@onready var right_image  = $MarginContainer/VBox/HBox/RightImage

# ─── Bottom bar (built in code so no scene edits needed) ─────────────────────
var _bottom_bar:   HBoxContainer = null
var _give_up_btn:  Button        = null


# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	left_image.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	left_image.clip_contents  = true
	right_image.clip_contents = true
	left_image.custom_minimum_size  = Vector2(560, 540)
	right_image.custom_minimum_size = Vector2(560, 540)

	_build_bottom_bar()
	_apply_font_if_available()
	_load_sounds_if_available()
	_style_labels()
	_update_status()
	game_active = true


# ──────────────────────────────────────────────────────────────────────────────
#  Bottom bar: [🔍 Found X/Y] ──── [⏱ 0.0 s] ──── [Give Up]
#  Reparents the existing labels into a new HBox placed under the image HBox.
# ──────────────────────────────────────────────────────────────────────────────
func _build_bottom_bar() -> void:
	# The VBox that owns everything
	var vbox = $MarginContainer/VBox

	# Remove labels from wherever they currently live so we can re-parent them
	status_label.get_parent().remove_child(status_label)
	timer_label.get_parent().remove_child(timer_label)

	# Build the bar
	_bottom_bar = HBoxContainer.new()
	_bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_bottom_bar.add_theme_constant_override("separation", 32)
	_bottom_bar.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(_bottom_bar)

	# Status label — left anchor inside bar
	_bottom_bar.add_child(status_label)

	# Spacer pushes timer to centre
	var spacer_l = Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bottom_bar.add_child(spacer_l)

	# Timer label — centre
	_bottom_bar.add_child(timer_label)

	# Spacer pushes Give Up to right
	var spacer_r = Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bottom_bar.add_child(spacer_r)

	# Give Up button — right anchor
	_give_up_btn = Button.new()
	_give_up_btn.text = "Give Up"
	_give_up_btn.custom_minimum_size = Vector2(110, 34)
	_give_up_btn.pressed.connect(_on_lose_or_give_up)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color            = Color(0.55, 0.10, 0.10, 0.90)
	btn_style.border_color        = Color(0.85, 0.25, 0.25, 1.0)
	btn_style.border_width_left   = 2
	btn_style.border_width_right  = 2
	btn_style.border_width_top    = 2
	btn_style.border_width_bottom = 2
	btn_style.corner_radius_top_left     = 6
	btn_style.corner_radius_top_right    = 6
	btn_style.corner_radius_bottom_left  = 6
	btn_style.corner_radius_bottom_right = 6
	_give_up_btn.add_theme_stylebox_override("normal", btn_style)

	var btn_hover = btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.75, 0.15, 0.15, 1.0)
	_give_up_btn.add_theme_stylebox_override("hover", btn_hover)

	_give_up_btn.add_theme_color_override("font_color", Color(1.0, 0.82, 0.82))
	_give_up_btn.add_theme_font_size_override("font_size", 16)
	_bottom_bar.add_child(_give_up_btn)


# ══════════════════════════════════════════════════════════════════════════════
#  ASSET AUTO-DETECTION
# ══════════════════════════════════════════════════════════════════════════════

# Scans FONT_SEARCH_PATHS for the first font file found and applies it to both
# UI labels. Drop any .ttf / .otf into one of those folders — done.
func _apply_font_if_available() -> void:
	var font_path := _find_first_asset(FONT_SEARCH_PATHS, FONT_EXTENSIONS)
	if font_path.is_empty():
		return
	var font := load(font_path) as Font
	if font == null:
		push_warning("FindMinigame: could not load font at %s" % font_path)
		return
	print("FindMinigame: using font → %s" % font_path)
	for label in [status_label, timer_label]:
		label.add_theme_font_override("font", font)
	if _give_up_btn:
		_give_up_btn.add_theme_font_override("font", font)


# Scans SOUND_SEARCH_PATHS and wires up sfx by filename keyword.
#   correct / found  →  _sfx_correct
#   wrong  / miss    →  _sfx_wrong
#   win    / clear   →  _sfx_win
# Any unmatched files are still loaded as generic players.
func _load_sounds_if_available() -> void:
	var dir := DirAccess.open("res://")
	if dir == null:
		return

	for base_path in SOUND_SEARCH_PATHS:
		var base: String = base_path
		var d := DirAccess.open(base)
		if d == null:
			continue
		d.list_dir_begin()
		var fname := d.get_next()
		while fname != "":
			if not d.current_is_dir():
				var ext := fname.get_extension().to_lower()
				if ext in SOUND_EXTENSIONS:
					var full: String = base + fname
					var stream := load(full) as AudioStream
					if stream:
						print("FindMinigame: loaded sound → %s" % full)
						_wire_sound(fname.to_lower(), stream)
			fname = d.get_next()
		d.list_dir_end()


func _wire_sound(fname: String, stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)

	if "correct" in fname or "found" in fname:
		_sfx_correct = player
	elif "wrong" in fname or "miss" in fname:
		_sfx_wrong = player
	elif "win" in fname or "clear" in fname or "complete" in fname:
		_sfx_win = player
	# else: loaded and available but not specifically slotted


func _find_first_asset(paths: Array, extensions: Array) -> String:
	for base in paths:
		var base_str: String = base
		var d := DirAccess.open(base_str)
		if d == null:
			continue
		d.list_dir_begin()
		var fname := d.get_next()
		while fname != "":
			if not d.current_is_dir() and fname.get_extension().to_lower() in extensions:
				d.list_dir_end()
				return base_str + fname
			fname = d.get_next()
		d.list_dir_end()
	return ""


# ══════════════════════════════════════════════════════════════════════════════
#  UI TEXT STYLING
# ══════════════════════════════════════════════════════════════════════════════

func _style_labels() -> void:
	# Status label  ─  larger, bold-weight, soft white
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color",        Color(0.95, 0.95, 0.95))
	status_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	status_label.add_theme_constant_override("shadow_offset_x", 1)
	status_label.add_theme_constant_override("shadow_offset_y", 1)

	# Timer label  ─  slightly smaller, muted cream, right-aligned feel
	timer_label.add_theme_font_size_override("font_size", 18)
	timer_label.add_theme_color_override("font_color",        Color(0.85, 0.82, 0.70))
	timer_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.45))
	timer_label.add_theme_constant_override("shadow_offset_x", 1)
	timer_label.add_theme_constant_override("shadow_offset_y", 1)


# ══════════════════════════════════════════════════════════════════════════════
#  GAME LOOP
# ══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not game_active:
		return
	elapsed_time += delta
	timer_label.text = "⏱  %.1f s" % elapsed_time


func _input(event: InputEvent) -> void:
	if not game_active:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var right_rect := Rect2(right_image.global_position, right_image.size)
	if not right_rect.has_point(event.global_position):
		return

	var clicked := false
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


# ══════════════════════════════════════════════════════════════════════════════
#  COLLISION HELPER  (untouched)
# ══════════════════════════════════════════════════════════════════════════════

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


# ══════════════════════════════════════════════════════════════════════════════
#  GAME EVENTS
# ══════════════════════════════════════════════════════════════════════════════

func _mark_found(diff_id: int) -> void:
	found_differences.append(diff_id)
	_place_marker(diff_id, left_image)
	_place_marker(diff_id, right_image)
	_flash_correct()
	if _sfx_correct:
		_sfx_correct.play()
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

		# Persistent checkmark dot
		var dot := ColorRect.new()
		dot.color    = Color(0.2, 1.0, 0.4, 0.85)
		dot.size     = Vector2(16, 16)
		dot.position = spot.position - dot.size * 0.5
		parent.add_child(dot)

		# Pulse ring
		var ring := Panel.new()
		ring.self_modulate = Color(0.2, 1.0, 0.4, 0.9)
		ring.size          = Vector2(20, 20)
		ring.pivot_offset  = Vector2(10, 10)
		ring.position      = spot.position - ring.size * 0.5

		var style := StyleBoxFlat.new()
		style.bg_color                  = Color(0, 0, 0, 0)
		style.border_color              = Color(0.2, 1.0, 0.4, 0.9)
		style.border_width_left         = 3
		style.border_width_right        = 3
		style.border_width_top          = 3
		style.border_width_bottom       = 3
		style.corner_radius_top_left    = 999
		style.corner_radius_top_right   = 999
		style.corner_radius_bottom_left = 999
		style.corner_radius_bottom_right= 999
		ring.add_theme_stylebox_override("panel", style)
		parent.add_child(ring)

		var tween := create_tween().set_parallel(true)
		tween.tween_property(ring, "scale",        Vector2(4.5, 4.5),          0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(ring, "self_modulate", Color(0.2, 1.0, 0.4, 0.0), 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(0.6).timeout
		ring.queue_free()
		return


func _flash_correct() -> void:
	modulate = Color(0.6, 1.0, 0.6)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.35)


func _wrong_guess() -> void:
	status_label.text = "✗  Wrong!  (−1 heart)"
	if _sfx_wrong:
		_sfx_wrong.play()
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").lose_heart()
	modulate = Color(1, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.3)
	await get_tree().create_timer(0.3).timeout
	_update_status()


func _update_status() -> void:
	var remaining := total_differences - found_differences.size()
	if remaining == 0:
		status_label.text = "✔  All found!"
	else:
		status_label.text = "🔍  Found  %d / %d" % [found_differences.size(), total_differences]


func _on_win() -> void:
	game_active = false
	var first_was_diff3 := found_differences.size() > 0 and found_differences[0] == 3
	var fast            := elapsed_time <= 6.7
	var secret_met      := first_was_diff3 and fast

	status_label.text = "✔  All differences found!  🎉"
	if secret_met:
		status_label.text += "\n✨  Something stirs..."

	if _sfx_win:
		_sfx_win.play()

	if has_node("/root/GameManager"):
		if secret_met:
			get_node("/root/GameManager").ss.trigger_adrenaline()

	await get_tree().create_timer(1.5).timeout
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.show()
	completed.emit(true)


func _on_lose_or_give_up() -> void:
	game_active = false
	status_label.text = "…  Gave up."
	await get_tree().create_timer(0.8).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(false)
