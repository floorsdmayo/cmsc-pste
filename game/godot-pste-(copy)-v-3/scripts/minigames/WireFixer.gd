extends Control
const minigame_id = "wirefixer"
signal completed(success: bool)

var wire_logic
var left_buttons: Array = []
var right_buttons: Array = []
var selected_left: int = -1
var wire_layers: Dictionary = {}

const ASSET_DIR   = "res://assets/minigames/wirefixer/"
const BG_IMAGE    = ASSET_DIR + "background.png"
const WIRE_RED    = ASSET_DIR + "wire_red.png"
const WIRE_BLUE   = ASSET_DIR + "wire_blue.png"
const WIRE_GREEN  = ASSET_DIR + "wire_green.png"
const WIRE_YELLOW = ASSET_DIR + "wire_yellow.png"
const FONT_PATH   = ASSET_DIR + "font.ttf"
const SFX_CORRECT = ASSET_DIR + "sfx_correct.mp3"
const SFX_WRONG   = ASSET_DIR + "sfx_wrong.mp3"

var wire_texture_paths = {
	"red":    WIRE_RED,
	"blue":   WIRE_BLUE,
	"green":  WIRE_GREEN,
	"yellow": WIRE_YELLOW
}

var wire_colors = {
	"red":    Color(0.95, 0.18, 0.18),
	"blue":   Color(0.18, 0.45, 1.00),
	"green":  Color(0.10, 0.82, 0.20),
	"yellow": Color(1.00, 0.88, 0.10)
}

const LEFT_ORDER  = ["yellow", "red", "blue", "green"]
const RIGHT_ORDER = ["blue", "yellow", "green", "red"]

const LEFT_POSITIONS = [
	Vector2(315, 342),
	Vector2(315, 438),
	Vector2(315, 525),
	Vector2(315, 258),
]

const RIGHT_POSITIONS = [
	Vector2(858, 285),
	Vector2(858, 358),
	Vector2(858, 435),
	Vector2(858, 510),
]

const BTN_SIZE = Vector2(110, 60)

# Countdown box center position (the dark box at top)
const TIMER_POSITION = Vector2(583, 140)
const TIME_LIMIT = 60.0

var time_left: float = TIME_LIMIT
var timer_active: bool = false
var loaded_font = null
var sfx_correct: AudioStreamPlayer = null
var sfx_wrong: AudioStreamPlayer = null
var _flash_rect: ColorRect
var _timer_label: Label

func _ready() -> void:
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.hide()

	wire_logic = WireFixer.new()
	add_child(wire_logic)
	wire_logic.setup(4)
	wire_logic.wire_connected.connect(_on_wire_connected)
	wire_logic.wire_wrong.connect(_on_wire_wrong)
	wire_logic.puzzle_complete.connect(_on_puzzle_complete)

	_load_assets()
	_setup_background()
	_build_timer_label()
	_build_invisible_buttons()
	_build_give_up_button()
	_build_flash_overlay()
	timer_active = true

func _load_assets() -> void:
	if ResourceLoader.exists(FONT_PATH):
		loaded_font = load(FONT_PATH)
	if ResourceLoader.exists(SFX_CORRECT):
		sfx_correct = AudioStreamPlayer.new()
		sfx_correct.stream = load(SFX_CORRECT)
		add_child(sfx_correct)
	if ResourceLoader.exists(SFX_WRONG):
		sfx_wrong = AudioStreamPlayer.new()
		sfx_wrong.stream = load(SFX_WRONG)
		add_child(sfx_wrong)

func _setup_background() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(BG_IMAGE):
		var bg = TextureRect.new()
		bg.texture = load(BG_IMAGE)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.z_index = 0
		add_child(bg)
	else:
		var bg = ColorRect.new()
		bg.color = Color(0.08, 0.08, 0.10)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.z_index = 0
		add_child(bg)

	for color_name in ["red", "blue", "green", "yellow"]:
		if ResourceLoader.exists(wire_texture_paths[color_name]):
			var layer = TextureRect.new()
			layer.name = "Wire_" + color_name
			layer.texture = load(wire_texture_paths[color_name])
			layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			layer.stretch_mode = TextureRect.STRETCH_SCALE
			layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.modulate = Color(1, 1, 1, 0)
			layer.z_index = 1
			add_child(layer)
			wire_layers[color_name] = layer

func _build_timer_label() -> void:
	_timer_label = Label.new()
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 48)
	_timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
	if loaded_font:
		_timer_label.add_theme_font_override("font", loaded_font)
	_timer_label.z_index = 15
	_timer_label.text = str(int(TIME_LIMIT))
	# Size matches the dark box
	_timer_label.custom_minimum_size = Vector2(300, 80)
	# Position centered on the dark box
	var vp_size = get_viewport().get_visible_rect().size
	var scale = vp_size / Vector2(1152, 648)
	var pos = TIMER_POSITION * scale
	_timer_label.set_position(pos - Vector2(150, 40))
	add_child(_timer_label)

func _build_invisible_buttons() -> void:
	var vp_size = get_viewport().get_visible_rect().size

	for i in 4:
		# LEFT button
		var lb = Button.new()
		lb.text = ""
		lb.flat = true
		lb.custom_minimum_size = BTN_SIZE
		var clear = StyleBoxFlat.new()
		clear.bg_color = Color(0, 0, 0, 0)
		lb.add_theme_stylebox_override("normal",   clear)
		lb.add_theme_stylebox_override("hover",    _make_glow_style(wire_colors[LEFT_ORDER[i]], 0.25))
		lb.add_theme_stylebox_override("pressed",  _make_glow_style(wire_colors[LEFT_ORDER[i]], 0.45))
		lb.add_theme_stylebox_override("disabled", clear)
		lb.z_index = 10
		add_child(lb)
		_place_button(lb, LEFT_POSITIONS[i], vp_size)
		lb.pressed.connect(_on_left_pressed.bind(i))
		left_buttons.append(lb)

		# RIGHT button
		var right_color_index = wire_logic.get_right_order(i)
		var right_color_name = wire_logic.get_color(right_color_index)
		var rb = Button.new()
		rb.text = ""
		rb.flat = true
		rb.custom_minimum_size = BTN_SIZE
		var clear2 = StyleBoxFlat.new()
		clear2.bg_color = Color(0, 0, 0, 0)
		rb.add_theme_stylebox_override("normal",  clear2)
		rb.add_theme_stylebox_override("hover",   _make_glow_style(wire_colors[right_color_name], 0.25))
		rb.add_theme_stylebox_override("pressed", _make_glow_style(wire_colors[right_color_name], 0.45))
		rb.z_index = 10
		add_child(rb)
		_place_button(rb, RIGHT_POSITIONS[i], vp_size)
		rb.pressed.connect(_on_right_pressed.bind(i))
		right_buttons.append(rb)

func _place_button(btn: Button, center: Vector2, vp_size: Vector2) -> void:
	var scale = vp_size / Vector2(1152, 648)
	var scaled_center = center * scale
	var scaled_size = BTN_SIZE * scale
	btn.set_position(scaled_center - scaled_size * 0.5)
	btn.set_size(scaled_size)

func _make_glow_style(color: Color, alpha: float) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(color.r, color.g, color.b, alpha)
	s.corner_radius_top_left     = 8
	s.corner_radius_top_right    = 8
	s.corner_radius_bottom_left  = 8
	s.corner_radius_bottom_right = 8
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.border_color = Color(color.r, color.g, color.b, alpha + 0.3)
	return s

func _build_flash_overlay() -> void:
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 0, 0, 0)
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.z_index = 20
	add_child(_flash_rect)

func _build_give_up_button() -> void:
	var btn = Button.new()
	btn.text = "✕ Give Up"
	btn.custom_minimum_size = Vector2(140, 44)
	btn.z_index = 15

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.55, 0.08, 0.08, 0.88)
	normal_style.corner_radius_top_left     = 6
	normal_style.corner_radius_top_right    = 6
	normal_style.corner_radius_bottom_left  = 6
	normal_style.corner_radius_bottom_right = 6
	normal_style.border_width_left   = 1
	normal_style.border_width_right  = 1
	normal_style.border_width_top    = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(1.0, 0.3, 0.3, 0.7)
	normal_style.shadow_color = Color(0, 0, 0, 0.5)
	normal_style.shadow_size  = 4

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.75, 0.10, 0.10, 0.95)
	hover_style.border_color = Color(1.0, 0.5, 0.5, 0.9)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.35, 0.05, 0.05, 1.0)

	btn.add_theme_stylebox_override("normal",  normal_style)
	btn.add_theme_stylebox_override("hover",   hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 16)
	if loaded_font:
		btn.add_theme_font_override("font", loaded_font)
	btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn.set_position(Vector2(16, 16))
	add_child(btn)
	btn.pressed.connect(_on_give_up)

func _process(delta: float) -> void:
	if not timer_active:
		return
	time_left -= delta
	var seconds = int(ceil(time_left))
	_timer_label.text = str(seconds)
	if time_left <= 10:
		_timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	elif time_left <= 20:
		_timer_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	else:
		_timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
	if time_left <= 0:
		timer_active = false
		_show_result("FAIL")
		await get_tree().create_timer(1.5).timeout
		_on_give_up()

func _show_result(text: String) -> void:
	timer_active = false
	if text == "DONE":
		_timer_label.text = "DONE"
		_timer_label.add_theme_color_override("font_color", Color(0.1, 0.9, 0.2))
	else:
		_timer_label.text = "FAIL"
		_timer_label.add_theme_color_override("font_color", Color(1, 0.1, 0.1))

func _on_left_pressed(index: int) -> void:
	if left_buttons[index].disabled:
		return
	selected_left = index
	wire_logic.set_selected_left(index)
	for i in left_buttons.size():
		if not left_buttons[i].disabled:
			left_buttons[i].add_theme_stylebox_override("normal", StyleBoxFlat.new())
	left_buttons[index].add_theme_stylebox_override(
		"normal", _make_glow_style(wire_colors[LEFT_ORDER[index]], 0.45)
	)

func _on_right_pressed(index: int) -> void:
	if selected_left == -1:
		return
	var success = wire_logic.try_connect(selected_left, index)
	if not success:
		_flash_wrong(index)
	_clear_left_highlights()
	selected_left = -1
	wire_logic.set_selected_left(-1)

func _clear_left_highlights() -> void:
	var clear = StyleBoxFlat.new()
	clear.bg_color = Color(0, 0, 0, 0)
	for i in left_buttons.size():
		if not left_buttons[i].disabled:
			left_buttons[i].add_theme_stylebox_override("normal", clear)

func _flash_wrong(right_index: int) -> void:
	if sfx_wrong:
		sfx_wrong.play()
	var tween = create_tween()
	tween.tween_property(_flash_rect, "color", Color(1, 0, 0, 0.35), 0.05)
	tween.tween_property(_flash_rect, "color", Color(1, 0, 0, 0.00), 0.25)
	var rb = right_buttons[right_index]
	var red_style = _make_glow_style(Color(1, 0.1, 0.1), 0.70)
	rb.add_theme_stylebox_override("normal", red_style)
	await get_tree().create_timer(0.35).timeout
	rb.add_theme_stylebox_override("normal", StyleBoxFlat.new())

func _on_wire_connected(left_index: int) -> void:
	if sfx_correct:
		sfx_correct.play()
	var color_name = wire_logic.get_color(left_index)
	left_buttons[left_index].disabled = true
	left_buttons[left_index].add_theme_stylebox_override(
		"normal", _make_glow_style(Color(0.2, 1.0, 0.3), 0.50)
	)
	if color_name in wire_layers:
		var tween = create_tween()
		tween.tween_property(wire_layers[color_name], "modulate", Color(1, 1, 1, 1), 0.4)

func _on_wire_wrong(_left_index: int) -> void:
	pass

func _on_puzzle_complete() -> void:
	_show_result("DONE")
	await get_tree().create_timer(1.5).timeout
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.show()
	completed.emit(true)

func _on_give_up() -> void:
	_show_result("FAIL")
	await get_tree().create_timer(1.0).timeout
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.show()
	completed.emit(false)
