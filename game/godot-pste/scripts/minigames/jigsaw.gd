extends Control
const minigame_id = "jigsaw"
signal completed(success: bool)

const GRID_SIZE = 4
const TOTAL_PIECES = 16
const TIME_LIMIT = 120

const ASSET_DIR = "res://assets/minigames/jigsaw/"
const BG_IMAGE = ASSET_DIR + "background.png"
const PIECE_IMAGE = ASSET_DIR + "puzzle_image.png"
const PIECE_NORMAL = ASSET_DIR + "piece_normal.png"
const PIECE_SELECTED = ASSET_DIR + "piece_selected.png"
const PIECE_CORRECT = ASSET_DIR + "piece_correct.png"
const FONT_PATH = ASSET_DIR + "font.ttf"

# Sound paths
const SFX_SWAP = ASSET_DIR + "swoosh.mp3"
const SFX_CORRECT = ASSET_DIR + "sfx_correct.mp3"
const SFX_WIN = ASSET_DIR + "success.wav"
const SFX_WRONG = ASSET_DIR + "wrong.mp3"
const SFX_TICK = ASSET_DIR + "tick.wav"

var sfx_swap: AudioStreamPlayer
var sfx_correct: AudioStreamPlayer
var sfx_win: AudioStreamPlayer
var sfx_wrong: AudioStreamPlayer
var sfx_tick: AudioStreamPlayer
var tick_played: bool = false
var matched_pieces: Array = []


const COLOR_BG = Color(0.08, 0.1, 0.08)
const COLOR_PIECE_DEFAULT = Color(0.15, 0.25, 0.15)
const COLOR_PIECE_SELECTED = Color(1.0, 0.85, 0.0)
const COLOR_PIECE_CORRECT = Color(0.2, 0.85, 0.3)
const COLOR_PIECE_WRONG = Color(1.0, 0.4, 0.4)

var pieces: Array = []
var piece_buttons: Array = []
var selected_index: int = -1
var time_left: float = TIME_LIMIT
var timer_active: bool = false
var moves: int = 0
var loaded_font = null
var puzzle_texture = null
var grid_node: GridContainer = null

# Caching the left inner panel to prevent "Node not found" errors
var left_panel_container: VBoxContainer = null 

func _setup_audio() -> void:
	sfx_swap = _make_audio(SFX_SWAP)
	sfx_correct = _make_audio(SFX_CORRECT)
	sfx_win = _make_audio(SFX_WIN)
	sfx_wrong = _make_audio(SFX_WRONG)
	sfx_tick = _make_audio(SFX_TICK)

func _make_audio(path: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	add_child(player)
	if ResourceLoader.exists(path):
		player.stream = load(path)
	return player

func _play(player: AudioStreamPlayer) -> void:
	if player and player.stream:
		player.play()
		
func _ready() -> void:
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.hide()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Load assets first
	if ResourceLoader.exists(FONT_PATH):
		loaded_font = load(FONT_PATH)
	if ResourceLoader.exists(PIECE_IMAGE):
		puzzle_texture = load(PIECE_IMAGE)

	# Setup background
	if ResourceLoader.exists(BG_IMAGE):
		var bg = TextureRect.new()
		bg.texture = load(BG_IMAGE)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.z_index = -1
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		move_child(bg, 0)
	else:
		var bg = ColorRect.new()
		bg.color = COLOR_BG
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.z_index = -1
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		move_child(bg, 0)

	# Grab grid from tscn before building new layout
	grid_node = get_node_or_null("UI/Grid") as GridContainer

	# Hide old UI — we'll build a new layout
	var old_ui = get_node_or_null("UI")
	if old_ui:
		old_ui.visible = false

	_build_layout()
	_setup_pieces()
	_setup_audio()

	_get_left().get_node("GiveUpButton").pressed.connect(_on_give_up_pressed)
	_get_left().get_node("MessageLabel").text = "Arrange the\npieces in order\n1 to 16!"
	_get_left().get_node("MovesLabel").text = "Moves: 0"
	timer_active = true

func _build_layout() -> void:
	# Main HBox
	var hbox = HBoxContainer.new()
	hbox.name = "MainLayout"
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	add_child(hbox)

	# ── Left panel ──────────────────────────────────────────────────────────
	var left = VBoxContainer.new()
	left.name = "Left"
	left.custom_minimum_size = Vector2(300, 0)
	left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 24)
	hbox.add_child(left)

	# Add left padding
	var left_margin = MarginContainer.new()
	left_margin.name = "MarginContainer"
	left_margin.add_theme_constant_override("margin_left", 30)
	left_margin.add_theme_constant_override("margin_right", 20)
	left_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(left_margin)

	var left_inner = VBoxContainer.new()
	left_inner.name = "VBoxContainer"
	left_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	left_inner.add_theme_constant_override("separation", 24)
	left_margin.add_child(left_inner)
	
	# Store the direct reference securely
	left_panel_container = left_inner

	# Title
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "JIGSAW\nPUZZLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	if loaded_font:
		title.add_theme_font_override("font", loaded_font)
	left_inner.add_child(title)

	# Message
	var msg = Label.new()
	msg.name = "MessageLabel"
	msg.text = ""
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg.custom_minimum_size = Vector2(240, 80)
	msg.add_theme_font_size_override("font_size", 18)
	msg.add_theme_color_override("font_color", Color(1, 1, 1))
	if loaded_font:
		msg.add_theme_font_override("font", loaded_font)
	left_inner.add_child(msg)

	# Timer
	var timer_lbl = Label.new()
	timer_lbl.name = "TimerLabel"
	timer_lbl.text = "⏱ Time: 120s"
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_lbl.add_theme_font_size_override("font_size", 22)
	timer_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	if loaded_font:
		timer_lbl.add_theme_font_override("font", loaded_font)
	left_inner.add_child(timer_lbl)

	# Moves
	var moves_lbl = Label.new()
	moves_lbl.name = "MovesLabel"
	moves_lbl.text = "Moves: 0"
	moves_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_lbl.add_theme_font_size_override("font_size", 20)
	moves_lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
	if loaded_font:
		moves_lbl.add_theme_font_override("font", loaded_font)
	left_inner.add_child(moves_lbl)

	# Give Up button
	var give_up = Button.new()
	give_up.name = "GiveUpButton"
	give_up.text = "✖  Give Up"
	give_up.custom_minimum_size = Vector2(180, 50)
	give_up.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var ns = StyleBoxFlat.new()
	ns.bg_color = Color(0.55, 0.08, 0.08, 0.88)
	ns.corner_radius_top_left = 6
	ns.corner_radius_top_right = 6
	ns.corner_radius_bottom_left = 6
	ns.corner_radius_bottom_right = 6
	ns.border_width_left = 1
	ns.border_width_right = 1
	ns.border_width_top = 1
	ns.border_width_bottom = 1
	ns.border_color = Color(1.0, 0.3, 0.3, 0.7)
	ns.shadow_color = Color(0, 0, 0, 0.5)
	ns.shadow_size = 4
	var hs = ns.duplicate()
	hs.bg_color = Color(0.75, 0.10, 0.10, 0.95)
	hs.border_color = Color(1.0, 0.5, 0.5, 0.9)
	var ps = ns.duplicate()
	ps.bg_color = Color(0.35, 0.05, 0.05, 1.0)
	give_up.add_theme_stylebox_override("normal", ns)
	give_up.add_theme_stylebox_override("hover", hs)
	give_up.add_theme_stylebox_override("pressed", ps)
	give_up.add_theme_color_override("font_color", Color(1, 1, 1))
	give_up.add_theme_font_size_override("font_size", 16)
	if loaded_font:
		give_up.add_theme_font_override("font", loaded_font)
	left_inner.add_child(give_up)

	# ── Right panel ──────────────────────────────────────────────────────────
	var right = CenterContainer.new()
	right.name = "Right"
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(right)

	# Move grid into right panel
	if grid_node:
		grid_node.reparent(right)
		grid_node.visible = true
		grid_node.columns = GRID_SIZE
		grid_node.custom_minimum_size = Vector2(560, 560)

func _setup_pieces() -> void:
	pieces.clear()
	matched_pieces.clear()
	piece_buttons.clear()
	selected_index = -1
	moves = 0

	for i in TOTAL_PIECES:
		pieces.append(i + 1)
	var shuffled = false
	while not shuffled:
		pieces.shuffle()
		shuffled = true
		for i in TOTAL_PIECES:
			if pieces[i] == i + 1:
				shuffled = false
				break

	for i in TOTAL_PIECES:
		var btn = grid_node.get_child(i)
		btn.custom_minimum_size = Vector2(135, 130)
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_font_size_override("font_size", 24)
		if loaded_font:
			btn.add_theme_font_override("font", loaded_font)

		if puzzle_texture:
			var atlas = AtlasTexture.new()
			atlas.atlas = puzzle_texture
			var piece_w = puzzle_texture.get_width() / GRID_SIZE
			var piece_h = puzzle_texture.get_height() / GRID_SIZE
			var correct_pos = pieces[i] - 1
			var col = correct_pos % GRID_SIZE
			var row = correct_pos / GRID_SIZE
			atlas.region = Rect2(col * piece_w, row * piece_h, piece_w, piece_h)
			var icon_rect = TextureRect.new()
			icon_rect.texture = atlas
			icon_rect.stretch_mode = TextureRect.STRETCH_SCALE
			icon_rect.custom_minimum_size = Vector2(130, 120)
			btn.add_child(icon_rect)
			btn.text = ""
		else:
			btn.text = str(pieces[i])

		_style_piece(btn, "default")
		piece_buttons.append(btn)
		btn.pressed.connect(_on_piece_pressed.bind(i))

func _style_piece(btn: Button, state: String) -> void:
	match state:
		"default":
			if ResourceLoader.exists(PIECE_NORMAL):
				var style = StyleBoxTexture.new()
				style.texture = load(PIECE_NORMAL)
				btn.add_theme_stylebox_override("normal", style)
			else:
				var style = StyleBoxFlat.new()
				style.bg_color = COLOR_PIECE_DEFAULT
				style.corner_radius_top_left = 6
				style.corner_radius_top_right = 6
				style.corner_radius_bottom_left = 6
				style.corner_radius_bottom_right = 6
				style.border_width_top = 2
				style.border_width_bottom = 2
				style.border_width_left = 2
				style.border_width_right = 2
				style.border_color = Color(0.3, 0.5, 0.3)
				btn.add_theme_stylebox_override("normal", style)
		"selected":
			if ResourceLoader.exists(PIECE_SELECTED):
				var style = StyleBoxTexture.new()
				style.texture = load(PIECE_SELECTED)
				btn.add_theme_stylebox_override("normal", style)
			else:
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.3, 0.3, 0.05)
				style.corner_radius_top_left = 6
				style.corner_radius_top_right = 6
				style.corner_radius_bottom_left = 6
				style.corner_radius_bottom_right = 6
				style.border_width_top = 3
				style.border_width_bottom = 3
				style.border_width_left = 3
				style.border_width_right = 3
				style.border_color = COLOR_PIECE_SELECTED
				btn.add_theme_stylebox_override("normal", style)
		"correct":
			if ResourceLoader.exists(PIECE_CORRECT):
				var style = StyleBoxTexture.new()
				style.texture = load(PIECE_CORRECT)
				btn.add_theme_stylebox_override("normal", style)
			else:
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.1, 0.3, 0.1)
				style.corner_radius_top_left = 6
				style.corner_radius_top_right = 6
				style.corner_radius_bottom_left = 6
				style.corner_radius_bottom_right = 6
				style.border_width_top = 2
				style.border_width_bottom = 2
				style.border_width_left = 2
				style.border_width_right = 2
				style.border_color = COLOR_PIECE_CORRECT
				btn.add_theme_stylebox_override("normal", style)

func _process(delta: float) -> void:
	if not timer_active:
		return
	time_left -= delta
	_update_timer_label()
	if time_left <= 0:
		time_left = 0
		timer_active = false
		_on_time_up()

func _update_timer_label() -> void:
	var seconds = int(ceil(time_left))
	var timer_lbl = _get_left().get_node_or_null("TimerLabel")
	if timer_lbl:
		timer_lbl.text = "Time: " + str(seconds) + "s"
		if time_left <= 20 and not tick_played:
			tick_played = true
			_play(sfx_tick)
		if time_left <= 20:
			timer_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		elif time_left <= 40:
			timer_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		else:
			timer_lbl.add_theme_color_override("font_color", Color(1, 1, 1))

func _get_left() -> VBoxContainer:
	# Returns the cached direct reference to avoid deep hierarchy pathing errors
	return left_panel_container

func _on_piece_pressed(index: int) -> void:
	
	if not timer_active:
		return
	if selected_index == -1:
		selected_index = index
		piece_buttons[index].modulate = COLOR_PIECE_SELECTED
		_style_piece(piece_buttons[index], "selected")
		_get_left().get_node("MessageLabel").text = "🔀 Now pick where to swap it!"
	else:
		var temp = pieces[selected_index]
		pieces[selected_index] = pieces[index]
		pieces[index] = temp

		if puzzle_texture:
			var btn_a = piece_buttons[selected_index]
			var btn_b = piece_buttons[index]
			var icon_a = btn_a.get_child(0) if btn_a.get_child_count() > 0 else null
			var icon_b = btn_b.get_child(0) if btn_b.get_child_count() > 0 else null
			if icon_a and icon_b:
				var temp_texture = icon_a.texture
				icon_a.texture = icon_b.texture
				icon_b.texture = temp_texture
		else:
			piece_buttons[selected_index].text = str(pieces[selected_index])
			piece_buttons[index].text = str(pieces[index])

		piece_buttons[selected_index].modulate = Color(1, 1, 1)
		piece_buttons[index].modulate = Color(1, 1, 1)
		_style_piece(piece_buttons[selected_index], "default")
		_style_piece(piece_buttons[index], "default")
		selected_index = -1
		moves += 1
		_get_left().get_node("MovesLabel").text = "Moves: " + str(moves)
		_get_left().get_node("MessageLabel").text = "Arrange the pieces in order 1 to 16!"
		_play(sfx_swap)
		_highlight_correct_pieces()
		_check_win()

func _check_win() -> void:
	for i in TOTAL_PIECES:
		if pieces[i] != i + 1:
			return
	_on_win()

func _highlight_correct_pieces() -> void:
	

	for i in TOTAL_PIECES:
		if pieces[i] == i + 1:
			piece_buttons[i].modulate = COLOR_PIECE_CORRECT
			_style_piece(piece_buttons[i], "correct")
			if not matched_pieces.has(i):
				matched_pieces.append(i)
				_play(sfx_correct)  # ← only plays first time piece lands correctly
		elif i != selected_index:
			piece_buttons[i].modulate = Color(1, 1, 1)
			_style_piece(piece_buttons[i], "default")
			
func _on_time_up() -> void:
	timer_active = false
	_play(sfx_wrong)
	_get_left().get_node("MessageLabel").text = "Time's up! So close!"
	for i in TOTAL_PIECES:
		if pieces[i] != i + 1:
			piece_buttons[i].modulate = COLOR_PIECE_WRONG
		else:
			piece_buttons[i].modulate = COLOR_PIECE_CORRECT
	await get_tree().create_timer(2.0).timeout
	_on_lose_or_give_up()

func _on_give_up_pressed() -> void:
	timer_active = false
	_get_left().get_node("MessageLabel").text = "Gave up!" #can't fix the proper logic ("Here is the solution")
	for i in TOTAL_PIECES:
		if not puzzle_texture:
			piece_buttons[i].text = str(i + 1)
		piece_buttons[i].modulate = COLOR_PIECE_CORRECT
		_style_piece(piece_buttons[i], "correct")
	await get_tree().create_timer(2.0).timeout
	_on_lose_or_give_up()

func _on_win() -> void:
	timer_active = false
	_highlight_correct_pieces()
	_play(sfx_win)
	_get_left().get_node("MessageLabel").text = "🎉 Puzzle solved in " + str(moves) + " moves!"
	await get_tree().create_timer(1.5).timeout
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.show()
	completed.emit(true)

func _on_lose_or_give_up() -> void:
	timer_active = false
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.show()
	completed.emit(false)
