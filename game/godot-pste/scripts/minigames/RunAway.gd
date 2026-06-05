extends Control

const minigame_id = "run_away"
signal completed(success: bool)

const TOTAL_ROUNDS = 10
const ROUND_CONFIG = [
	[0.30, 0.35, 0.65],
	[0.50, 0.10, 0.30],
	[0.40, 0.60, 0.90],
	[0.70, 0.45, 0.55],
	[0.45, 0.05, 0.35],
	[0.80, 0.65, 0.75],
	[0.55, 0.30, 0.55],
	[0.90, 0.70, 0.80],
	[0.60, 0.15, 0.45],
	[0.95, 0.42, 0.52],
]

var current_round: int = 0
var indicator_pos: float = 0.0
var indicator_dir: float = 1.0
var indicator_speed: float = 0.30
var safe_start: float = 0.35
var safe_end: float = 0.65
var waiting_for_input: bool = true

var tunnel_canvas: Control
var bar_container: Control
var safe_zone: ColorRect
var indicator: ColorRect
var step_nodes: Array = []
var result_label: Label
var instruction_label: Label
var flash_overlay: ColorRect

var heartbeat_player: AudioStreamPlayer
var hit_player: AudioStreamPlayer
var miss_player: AudioStreamPlayer
var heartbeat_timer: float = 0.0
var heartbeat_interval: float = 0.8
var beat_phase: int = 0

func _ready() -> void:
	get_tree().get_first_node_in_group("room_container").hide()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_audio()
	_build_ui()
	await get_tree().process_frame
	await get_tree().process_frame
	_load_round()

# ── audio ─────────────────────────────────────────────────────────────────────

func _build_audio() -> void:
	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.stream = _make_heartbeat_thud(80.0, 0.12)
	heartbeat_player.volume_db = -4
	add_child(heartbeat_player)

	hit_player = AudioStreamPlayer.new()
	hit_player.stream = _make_beep(660.0, 0.06)
	hit_player.volume_db = -6
	add_child(hit_player)

	miss_player = AudioStreamPlayer.new()
	miss_player.stream = _make_beep(120.0, 0.2)
	miss_player.volume_db = -4
	add_child(miss_player)

func _make_heartbeat_thud(freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t = float(i) / samples
		var env = exp(-t * 18.0)
		var wave = sin(float(i) / sample_rate * freq * TAU) * env
		if i < int(sample_rate * 0.015):
			wave += (1.0 - float(i) / (sample_rate * 0.015)) * 0.4
		var val = int(clamp(wave * 28000, -32768, 32767))
		data[i * 2] = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	return stream

func _make_beep(freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t = float(i) / sample_rate
		var env = 1.0 - float(i) / samples
		var val = int(clamp(sin(t * freq * TAU) * env * 20000, -32768, 32767))
		data[i * 2] = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	return stream

# ── ui ────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	tunnel_canvas = Control.new()
	tunnel_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tunnel_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tunnel_canvas)
	tunnel_canvas.draw.connect(_draw_tunnel.bind(tunnel_canvas))

	flash_overlay = ColorRect.new()
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_overlay.color = Color(1, 1, 1, 0.0)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.custom_minimum_size = Vector2(680, 0)
	center.add_child(vbox)

	instruction_label = Label.new()
	instruction_label.text = "PRESS SPACE — stay in the light"
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 15)
	instruction_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	vbox.add_child(instruction_label)

	bar_container = Control.new()
	bar_container.custom_minimum_size = Vector2(680, 52)
	vbox.add_child(bar_container)

	var bar_bg = ColorRect.new()
	bar_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_bg.color = Color(0.05, 0.05, 0.06)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_container.add_child(bar_bg)

	var bar_border = Panel.new()
	bar_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bstyle = StyleBoxFlat.new()
	bstyle.bg_color = Color(0, 0, 0, 0)
	bstyle.border_color = Color(0.2, 0.18, 0.14)
	bstyle.set_border_width_all(1)
	bar_border.add_theme_stylebox_override("panel", bstyle)
	bar_container.add_child(bar_border)

	safe_zone = ColorRect.new()
	safe_zone.color = Color(0.95, 0.85, 0.3, 0.35)
	safe_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_container.add_child(safe_zone)

	var sz_panel = Panel.new()
	sz_panel.name = "SafeBorder"
	sz_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var szstyle = StyleBoxFlat.new()
	szstyle.bg_color = Color(0, 0, 0, 0)
	szstyle.border_color = Color(1.0, 0.9, 0.4, 0.8)
	szstyle.set_border_width_all(2)
	sz_panel.add_theme_stylebox_override("panel", szstyle)
	bar_container.add_child(sz_panel)

	indicator = ColorRect.new()
	indicator.color = Color(1.0, 1.0, 1.0)
	indicator.custom_minimum_size = Vector2(6, 0)
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicator.z_index = 2
	bar_container.add_child(indicator)

	var steps_row = HBoxContainer.new()
	steps_row.alignment = BoxContainer.ALIGNMENT_CENTER
	steps_row.add_theme_constant_override("separation", 10)
	vbox.add_child(steps_row)

	for i in TOTAL_ROUNDS:
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(16, 16)
		dot.color = Color(0.1, 0.1, 0.12)
		step_nodes.append(dot)
		steps_row.add_child(dot)

	result_label = Label.new()
	result_label.text = ""
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 16)
	result_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	vbox.add_child(result_label)

func _draw_tunnel(canvas: Control) -> void:
	var progress = float(current_round) / TOTAL_ROUNDS
	var cx = canvas.size.x * 0.5
	var cy = canvas.size.y * 0.5
	var max_radius = max(canvas.size.x, canvas.size.y) * 0.85
	const RING_COUNT = 12

	for i in RING_COUNT:
		var t = float(i) / RING_COUNT
		var radius = max_radius * (1.0 - t) * (1.0 - progress * 0.5)
		if radius < 4:
			continue
		var brightness = t * 0.02 + progress * 0.06
		var warm = progress * 0.10
		var ring_color = Color(brightness + warm, brightness + warm * 0.5, brightness)
		var thickness = max_radius * 0.06
		canvas.draw_arc(Vector2(cx, cy), radius, 0, TAU, 48, ring_color, thickness, false)

	# gate light — only visible after round 2
	var glow_alpha = max(0.0, (progress - 0.2)) * 0.7
	var glow_radius = progress * max_radius * 0.35 + 8
	for g in 4:
		var gr = glow_radius * (1.0 + g * 0.5)
		var ga = glow_alpha * (1.0 - float(g) / 4.0) * 0.4
		canvas.draw_circle(Vector2(cx, cy), gr, Color(1.0, 0.92, 0.6, ga))
	canvas.draw_circle(Vector2(cx, cy), glow_radius * 0.3, Color(1.0, 0.95, 0.8, glow_alpha))

# ── logic ─────────────────────────────────────────────────────────────────────

func _load_round() -> void:
	if current_round < ROUND_CONFIG.size():
		var cfg = ROUND_CONFIG[current_round]
		indicator_speed = cfg[0]
		safe_start = cfg[1]
		safe_end = cfg[2]
	indicator_pos = 0.0
	indicator_dir = 1.0
	waiting_for_input = true
	heartbeat_interval = max(0.3, 0.8 - float(current_round) * 0.05)
	tunnel_canvas.queue_redraw()
	_update_bar()

func _process(delta: float) -> void:
	heartbeat_timer += delta
	if heartbeat_timer >= heartbeat_interval:
		heartbeat_timer = 0.0
		if beat_phase == 0:
			heartbeat_player.volume_db = -4
			heartbeat_player.play()
			beat_phase = 1
			await get_tree().create_timer(heartbeat_interval * 0.22).timeout
			heartbeat_player.volume_db = -8
			heartbeat_player.play()
			beat_phase = 0

	if not waiting_for_input:
		if flash_overlay.color.a > 0:
			flash_overlay.color.a = max(0.0, flash_overlay.color.a - delta * 6.0)
		return

	indicator_pos += indicator_dir * indicator_speed * delta
	if indicator_pos >= 1.0:
		indicator_pos = 1.0
		indicator_dir = -1.0
	elif indicator_pos <= 0.0:
		indicator_pos = 0.0
		indicator_dir = 1.0

	if flash_overlay.color.a > 0:
		flash_overlay.color.a = max(0.0, flash_overlay.color.a - delta * 6.0)

	_update_bar()

func _update_bar() -> void:
	if not is_instance_valid(bar_container):
		return
	var w = bar_container.size.x
	var h = bar_container.size.y
	if w < 10:
		return

	indicator.size = Vector2(6, h)
	indicator.position.x = indicator_pos * w - 3
	safe_zone.position = Vector2(safe_start * w, 0)
	safe_zone.size = Vector2((safe_end - safe_start) * w, h)
	var sb = bar_container.get_node_or_null("SafeBorder")
	if sb:
		sb.position = Vector2(safe_start * w, 0)
		sb.size = Vector2((safe_end - safe_start) * w, h)

func _input(event: InputEvent) -> void:
	if not waiting_for_input:
		return
	if event.is_action_pressed("ui_accept"):
		_on_press()

func _on_press() -> void:
	waiting_for_input = false
	var in_zone = indicator_pos >= safe_start and indicator_pos <= safe_end
	if in_zone:
		_on_hit()
	else:
		_on_miss()

func _on_hit() -> void:
	hit_player.play()
	flash_overlay.color = Color(1.0, 0.95, 0.6, 0.15)
	step_nodes[current_round].color = Color(1.0, 0.9, 0.4)
	current_round += 1
	tunnel_canvas.queue_redraw()
	if current_round >= TOTAL_ROUNDS:
		_on_win()
		return
	result_label.text = "%d / %d" % [current_round, TOTAL_ROUNDS]
	var cfg = ROUND_CONFIG[current_round]
	indicator_speed = cfg[0]
	safe_start = cfg[1]
	safe_end = cfg[2]
	heartbeat_interval = max(0.3, 0.8 - float(current_round) * 0.05)
	waiting_for_input = true

func _on_miss() -> void:
	miss_player.play()
	flash_overlay.color = Color(0.8, 0.0, 0.0, 0.4)
	step_nodes[current_round].color = Color(0.6, 0.1, 0.1)
	result_label.text = "CAUGHT."
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").lose_heart()
	await get_tree().create_timer(1.5).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(false)

func _on_win() -> void:
	hit_player.play()
	flash_overlay.color = Color(1.0, 0.95, 0.7, 0.6)
	result_label.text = "YOU MADE IT."
	current_round = TOTAL_ROUNDS
	tunnel_canvas.queue_redraw()
	await get_tree().create_timer(2.0).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(true)
