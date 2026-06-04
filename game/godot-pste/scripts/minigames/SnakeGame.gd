extends Control

const minigame_id = "snake"
signal completed(success: bool)

var snake_logic
var cell_size = 20
var grid_width = 20
var grid_height = 20
var timer = 0.0
var running = false
var pong_logic = null
var pong_phase = false

# ─── Asset auto-detection ─────────────────────────────────────────────────────
const ASSET_PATH       := "res://assets/minigames/snake/"
const FONT_EXTENSIONS  := ["ttf", "otf", "woff", "tres"]
const SOUND_EXTENSIONS := ["wav", "ogg", "mp3"]

var _sfx_eat:     AudioStreamPlayer = null
var _sfx_die:     AudioStreamPlayer = null
var _sfx_phase:   AudioStreamPlayer = null
var _sfx_win:     AudioStreamPlayer = null
var _sfx_pong:    AudioStreamPlayer = null

# ─── Node refs ────────────────────────────────────────────────────────────────
@onready var game_board   = $CanvasLayer/GameBoard
@onready var score_label  = $CanvasLayer/UI/ScoreLabel
@onready var phase_label  = $CanvasLayer/UI/PhaseLabel
@onready var taunt_label  = $CanvasLayer/UI/TauntLabel
@onready var close_button = $CanvasLayer/UI/CloseButton

var phase_taunts = {
	0: "Sssso you found my nest… Allow me to shed some light on your ssituation — by taking it away! Conssider thiss your practical exam!",
	1: "Impresssive… but can you handle my WALL-gorithmsss?",
	2: "You think you can COMPILE me?! I'll turn YOU to SSSTONEEE!"
}


# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.hide()

	snake_logic = SnakeLogic.new()
	add_child(snake_logic)
	snake_logic.setup(grid_width, grid_height)
	snake_logic.apple_eaten.connect(_on_apple_eaten)
	snake_logic.phase_changed.connect(_on_phase_changed)
	snake_logic.game_ended.connect(_on_game_ended)

	close_button.pressed.connect(_on_give_up)

	$CanvasLayer/GameBoard.size = Vector2(grid_width * cell_size, grid_height * cell_size)
	$CanvasLayer/GameBoard.custom_minimum_size = Vector2(grid_width * cell_size, grid_height * cell_size)

	game_board.snake_logic = snake_logic
	game_board.grid_width  = grid_width
	game_board.grid_height = grid_height
	game_board.cell_size   = cell_size

	_load_assets()
	_style_ui()
	_layout_scene()

	taunt_label.text = phase_taunts[0]
	running = true


# ══════════════════════════════════════════════════════════════════════════════
#  ASSET AUTO-DETECTION  (res://assets/minigames/snake/)
# ══════════════════════════════════════════════════════════════════════════════

func _load_assets() -> void:
	var d := DirAccess.open(ASSET_PATH)
	if d == null:
		push_warning("SnakeMinigame: asset folder not found — %s" % ASSET_PATH)
		return

	d.list_dir_begin()
	var fname := d.get_next()
	while fname != "":
		if not d.current_is_dir():
			var ext := fname.get_extension().to_lower()
			var full: String = ASSET_PATH + fname
			if ext in FONT_EXTENSIONS:
				_apply_font(full)
			elif ext in SOUND_EXTENSIONS:
				_wire_sound(fname.to_lower(), full)
		fname = d.get_next()
	d.list_dir_end()


func _apply_font(path: String) -> void:
	var font := load(path) as Font
	if font == null:
		push_warning("SnakeMinigame: could not load font → %s" % path)
		return
	print("SnakeMinigame: using font → %s" % path)
	for node in [score_label, phase_label, taunt_label, close_button]:
		if node and is_instance_valid(node):
			node.add_theme_font_override("font", font)


func _wire_sound(fname: String, path: String) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		return
	print("SnakeMinigame: loaded sound → %s" % path)
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	# Slot by keyword
	if   "eat"   in fname or "apple"  in fname: _sfx_eat   = player
	elif "die"   in fname or "death"  in fname or "lose" in fname: _sfx_die   = player
	elif "phase" in fname or "change" in fname: _sfx_phase  = player
	elif "win"   in fname or "clear"  in fname or "complete" in fname: _sfx_win = player
	elif "pong"  in fname or "rally"  in fname or "serve"    in fname: _sfx_pong = player


# ══════════════════════════════════════════════════════════════════════════════
#  UI STYLING
# ══════════════════════════════════════════════════════════════════════════════

func _style_ui() -> void:
	# ── Score label ─────────────────────────────────────────────────
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color",        Color(0.95, 0.88, 0.60))
	score_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	score_label.add_theme_constant_override("shadow_offset_x", 1)
	score_label.add_theme_constant_override("shadow_offset_y", 1)

	# ── Phase label ──────────────────────────────────────────────────
	phase_label.add_theme_font_size_override("font_size", 15)
	phase_label.add_theme_color_override("font_color",        Color(0.55, 1.0, 0.60))
	phase_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	phase_label.add_theme_constant_override("shadow_offset_x", 1)
	phase_label.add_theme_constant_override("shadow_offset_y", 1)
	phase_label.text = "Phase 1"

	# ── Taunt label ──────────────────────────────────────────────────
	taunt_label.add_theme_font_size_override("font_size", 14)
	taunt_label.add_theme_color_override("font_color",        Color(0.88, 0.75, 0.90))
	taunt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.50))
	taunt_label.add_theme_constant_override("shadow_offset_x", 1)
	taunt_label.add_theme_constant_override("shadow_offset_y", 1)
	taunt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# ── Give Up / Close button ───────────────────────────────────────
	close_button.text = "Give Up"
	close_button.add_theme_font_size_override("font_size", 15)
	close_button.add_theme_color_override("font_color", Color(1.0, 0.78, 0.78))

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color            = Color(0.50, 0.08, 0.08, 0.88)
	btn_normal.border_color        = Color(0.80, 0.22, 0.22, 1.0)
	btn_normal.border_width_left   = 2
	btn_normal.border_width_right  = 2
	btn_normal.border_width_top    = 2
	btn_normal.border_width_bottom = 2
	btn_normal.corner_radius_top_left     = 6
	btn_normal.corner_radius_top_right    = 6
	btn_normal.corner_radius_bottom_left  = 6
	btn_normal.corner_radius_bottom_right = 6
	close_button.add_theme_stylebox_override("normal", btn_normal)

	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.72, 0.13, 0.13, 1.0)
	close_button.add_theme_stylebox_override("hover", btn_hover)


# ══════════════════════════════════════════════════════════════════════════════
#  LAYOUT  — board left-of-centre, UI panel to its right
# ══════════════════════════════════════════════════════════════════════════════

func _layout_scene() -> void:
	var board_px := Vector2(grid_width * cell_size, grid_height * cell_size)  # 400 × 400

	# Total content width: board + gap + sidebar
	var gap         := 32.0
	var sidebar_w   := 220.0
	var total_w     := board_px.x + gap + sidebar_w
	var total_h     := board_px.y

	# Centre the whole block, then shift left by 60 px for the offset
	var screen      := get_viewport_rect().size
	var origin_x    := (screen.x - total_w) * 0.5 - 60.0
	var origin_y    := (screen.y - total_h) * 0.5

	# ── Position game board ───────────────────────────────────────────
	game_board.set_position(Vector2(origin_x, origin_y))

	# ── Build sidebar VBox to the right of the board ──────────────────
	var ui_root := $CanvasLayer/UI as Control
	# Detach existing label nodes so we can re-parent cleanly
	for node in [score_label, phase_label, taunt_label, close_button]:
		if node and is_instance_valid(node) and node.get_parent():
			node.get_parent().remove_child(node)

	var sidebar := VBoxContainer.new()
	sidebar.position = Vector2(origin_x + board_px.x + gap, origin_y)
	sidebar.custom_minimum_size = Vector2(sidebar_w, total_h)
	sidebar.add_theme_constant_override("separation", 14)
	ui_root.add_child(sidebar)

	# Phase label at top
	sidebar.add_child(phase_label)

	# Thin separator line
	var sep1 := HSeparator.new()
	sidebar.add_child(sep1)

	# Score label
	sidebar.add_child(score_label)

	# Spacer pushes taunt downward
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(spacer)

	# Taunt label in the middle
	taunt_label.custom_minimum_size = Vector2(sidebar_w, 0)
	sidebar.add_child(taunt_label)

	# Another spacer
	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(spacer2)

	# Give Up button pinned to bottom
	close_button.custom_minimum_size = Vector2(sidebar_w, 36)
	sidebar.add_child(close_button)


# ══════════════════════════════════════════════════════════════════════════════
#  GAME LOOP
# ══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not running:
		return
	timer += delta
	if timer >= snake_logic.get_move_speed():
		timer = 0.0
		snake_logic.step()
	if pong_phase:
		pong_logic.step(delta, snake_logic.get_snake_body())
		game_board.pong_logic = pong_logic
	game_board.queue_redraw()


func _input(event: InputEvent) -> void:
	if not running:
		return
	if event.is_action_pressed("ui_right"):
		snake_logic.set_direction(1, 0)
	elif event.is_action_pressed("ui_left"):
		snake_logic.set_direction(-1, 0)
	elif event.is_action_pressed("ui_up"):
		snake_logic.set_direction(0, -1)
	elif event.is_action_pressed("ui_down"):
		snake_logic.set_direction(0, 1)


# ══════════════════════════════════════════════════════════════════════════════
#  GAME EVENTS
# ══════════════════════════════════════════════════════════════════════════════

func _on_apple_eaten(score: int) -> void:
	score_label.text = "🐍  HP: %d / 67" % max(67 - score, 0)
	if _sfx_eat:
		_sfx_eat.play()


func _on_phase_changed(new_phase: int) -> void:
	phase_label.text = "— Phase %d —" % (new_phase + 1)
	taunt_label.text = phase_taunts[new_phase]
	if _sfx_phase:
		_sfx_phase.play()


func _on_game_ended(success: bool) -> void:
	if not success:
		if _sfx_die:
			_sfx_die.play()
		running = false
		get_tree().get_first_node_in_group("room_container").show()
		completed.emit(false)
		return
	_start_pong_transition()


func _start_pong_transition() -> void:
	running = false
	taunt_label.text = "You may have defeated my algorithmss… but have you met my SSERVE-ior?! I sssummon — ALEX EALA!"
	score_label.text = "⚡  Get ready…"
	phase_label.text = "— Final Phase —"
	if _sfx_pong:
		_sfx_pong.play()
	await get_tree().create_timer(3.0).timeout
	_launch_pong()


func _launch_pong() -> void:
	snake_logic.clear_walls()
	snake_logic.clear_statues()
	snake_logic.trim_to(8)
	snake_logic.reset_for_pong()

	pong_logic = PongGame.new()
	add_child(pong_logic)
	pong_logic.setup(grid_width, grid_height)
	pong_logic.point_scored.connect(_on_point_scored)
	pong_logic.game_ended.connect(_on_pong_ended)
	pong_phase = true
	game_board.pong_phase = true
	running = true
	taunt_label.text = "Ssstruggling? Allow me to RALLY some backup!"
	_update_pong_score()


func _on_point_scored(_player_scored: bool) -> void:
	_update_pong_score()


func _update_pong_score() -> void:
	score_label.text = "🏓  You: %d   Alex: %d" % [pong_logic.get_player_score(), pong_logic.get_alex_score()]


func _on_pong_ended(player_won: bool) -> void:
	running = false
	if player_won:
		taunt_label.text = "Fault! FAULT! Thiss can't be happening…"
		if _sfx_win:
			_sfx_win.play()
		await get_tree().create_timer(2.0).timeout
		taunt_label.text = "Imposssible… I'll add this to your final exam…"
		await get_tree().create_timer(2.0).timeout
	else:
		if _sfx_die:
			_sfx_die.play()
		taunt_label.text = "Out of boundsss! Just like your chanccess of esscaping!"
		await get_tree().create_timer(2.0).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(player_won)


func _on_give_up() -> void:
	running = false
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(false)
