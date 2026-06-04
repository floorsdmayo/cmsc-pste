extends Control
const minigame_id = "lockpicker"
signal completed(success: bool)

const ROUNDS_TO_WIN = 7
const NUM_BUTTONS = 4
const FLASH_DURATION = 0.4
const FLASH_GAP = 0.2
const TIME_LIMIT = 120.0

# Asset paths
const ASSET_DIR = "res://assets/minigames/lockpicker/"
const BG_IMAGE = ASSET_DIR + "background.png"
const FONT_PATH = ASSET_DIR + "font.ttf"

# Sound paths
const SFX_BUTTON = ASSET_DIR + "button_press.wav"
const SFX_CORRECT = ASSET_DIR + "correct.mp3"
const SFX_WRONG = ASSET_DIR + "wrong.mp3"
const SFX_WIN = ASSET_DIR + "win.mp3"
const SFX_TICK = ASSET_DIR + "tick.ogg"

# Button colors
const BUTTON_COLORS = [
	Color(1.0, 0.2, 0.2),
	Color(0.2, 0.6, 1.0),
	Color(0.2, 0.9, 0.2),
	Color(1.0, 0.85, 0.0),
]
const BUTTON_DIM = [
	Color(0.3, 0.05, 0.05),
	Color(0.05, 0.15, 0.3),
	Color(0.05, 0.3, 0.05),
	Color(0.3, 0.25, 0.0),
]
const BUTTON_LABELS = ["1", "2", "3", "4"]

var sequence: Array = []
var player_input: Array = []
var current_round: int = 0
var game_active: bool = false
var player_turn: bool = false
var time_left: float = TIME_LIMIT
var loaded_font = null
var buttons: Array = []
var tick_played: bool = false

# Audio players
var sfx_button: AudioStreamPlayer
var sfx_correct: AudioStreamPlayer
var sfx_wrong: AudioStreamPlayer
var sfx_win: AudioStreamPlayer
var sfx_tick: AudioStreamPlayer

func _ready() -> void:
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.hide()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$UI.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$UI.alignment = BoxContainer.ALIGNMENT_CENTER

	_load_assets()
	_setup_audio()
	_setup_background()
	_setup_labels()
	_setup_buttons()
	_start_game()

func _load_assets() -> void:
	if ResourceLoader.exists(FONT_PATH):
		loaded_font = load(FONT_PATH)

func _setup_audio() -> void:
	sfx_button = _make_audio_player(SFX_BUTTON)
	sfx_correct = _make_audio_player(SFX_CORRECT)
	sfx_wrong = _make_audio_player(SFX_WRONG)
	sfx_win = _make_audio_player(SFX_WIN)
	sfx_tick = _make_audio_player(SFX_TICK)

func _make_audio_player(path: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	add_child(player)
	if ResourceLoader.exists(path):
		player.stream = load(path)
	return player

func _play_sfx(player: AudioStreamPlayer) -> void:
	if player.stream:
		player.play()

func _setup_background() -> void:
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
		bg.color = Color(0.05, 0.05, 0.08)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.z_index = -1
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		move_child(bg, 0)

func _setup_labels() -> void:
	$UI/MessageLabel.custom_minimum_size = Vector2(800, 50)
	$UI/MessageLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$UI/MessageLabel.add_theme_font_size_override("font_size", 26)
	$UI/MessageLabel.add_theme_color_override("font_color", Color(1, 1, 1))
	if loaded_font:
		$UI/MessageLabel.add_theme_font_override("font", loaded_font)

	$UI/TimerLabel.custom_minimum_size = Vector2(800, 40)
	$UI/TimerLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$UI/TimerLabel.add_theme_font_size_override("font_size", 20)
	$UI/TimerLabel.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	if loaded_font:
		$UI/TimerLabel.add_theme_font_override("font", loaded_font)

	# Give Up button — outlined, no fill
	var give_up_normal = StyleBoxFlat.new()
	give_up_normal.bg_color = Color(0, 0, 0, 0)
	give_up_normal.border_width_top = 2
	give_up_normal.border_width_bottom = 2
	give_up_normal.border_width_left = 2
	give_up_normal.border_width_right = 2
	give_up_normal.border_color = Color(1, 0.2, 0.2)
	give_up_normal.corner_radius_top_left = 8
	give_up_normal.corner_radius_top_right = 8
	give_up_normal.corner_radius_bottom_left = 8
	give_up_normal.corner_radius_bottom_right = 8

	var give_up_hover = StyleBoxFlat.new()
	give_up_hover.bg_color = Color(1, 0.2, 0.2, 0.15)
	give_up_hover.border_width_top = 2
	give_up_hover.border_width_bottom = 2
	give_up_hover.border_width_left = 2
	give_up_hover.border_width_right = 2
	give_up_hover.border_color = Color(1, 0.2, 0.2)
	give_up_hover.corner_radius_top_left = 8
	give_up_hover.corner_radius_top_right = 8
	give_up_hover.corner_radius_bottom_left = 8
	give_up_hover.corner_radius_bottom_right = 8

	$UI/GiveUpButton.add_theme_stylebox_override("normal", give_up_normal)
	$UI/GiveUpButton.add_theme_stylebox_override("hover", give_up_hover)
	$UI/GiveUpButton.add_theme_stylebox_override("pressed", give_up_hover)
	$UI/GiveUpButton.add_theme_stylebox_override("focus", give_up_normal)
	$UI/GiveUpButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	$UI/GiveUpButton.custom_minimum_size = Vector2(200, 50)
	$UI/GiveUpButton.add_theme_font_size_override("font_size", 18)
	$UI/GiveUpButton.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	$UI/GiveUpButton.text = "✕ Give Up"
	if loaded_font:
		$UI/GiveUpButton.add_theme_font_override("font", loaded_font)
	$UI/GiveUpButton.pressed.connect(_on_give_up_pressed)

func _setup_buttons() -> void:
	var btn_container = HBoxContainer.new()
	btn_container.name = "SimonButtons"
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	btn_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	$UI.add_child(btn_container)
	$UI.move_child(btn_container, $UI.get_child_count() - 2)

	for i in NUM_BUTTONS:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(140, 140)
		btn.add_theme_font_size_override("font_size", 36)
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.text = BUTTON_LABELS[i]
		if loaded_font:
			btn.add_theme_font_override("font", loaded_font)
		_set_button_dim(btn, i)
		btn.pressed.connect(_on_simon_button_pressed.bind(i))
		btn_container.add_child(btn)
		buttons.append(btn)

func _set_button_dim(btn: Button, index: int) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = BUTTON_DIM[index]
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func _set_button_lit(btn: Button, index: int) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = BUTTON_COLORS[index]
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func _start_game() -> void:
	sequence.clear()
	player_input.clear()
	current_round = 0
	game_active = true
	player_turn = false
	time_left = TIME_LIMIT
	tick_played = false
	$UI/MessageLabel.text = "Watch the sequence!"
	$UI/TimerLabel.text = "Time: %d" % int(TIME_LIMIT)
	await get_tree().create_timer(0.5).timeout
	_next_round()

func _next_round() -> void:
	current_round += 1
	player_input.clear()
	player_turn = false
	sequence.append(randi() % NUM_BUTTONS)
	$UI/MessageLabel.text = "Round %d / %d — Watch!" % [current_round, ROUNDS_TO_WIN]
	_set_buttons_disabled(true)
	await get_tree().create_timer(0.5).timeout
	await _play_sequence()
	player_turn = true
	_set_buttons_disabled(false)
	$UI/MessageLabel.text = "Your turn! Repeat the sequence!"

func _play_sequence() -> void:
	for btn_index in sequence:
		await get_tree().create_timer(0.5).timeout
		_set_button_lit(buttons[btn_index], btn_index)
		_play_sfx(sfx_button)
		await get_tree().create_timer(FLASH_DURATION).timeout
		_set_button_dim(buttons[btn_index], btn_index)
		await get_tree().create_timer(FLASH_GAP).timeout

func _set_buttons_disabled(disabled: bool) -> void:
	for btn in buttons:
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP

func _on_simon_button_pressed(index: int) -> void:
	if not player_turn or not game_active:
		return
	_set_button_lit(buttons[index], index)
	_play_sfx(sfx_button)
	await get_tree().create_timer(0.15).timeout
	_set_button_dim(buttons[index], index)

	player_input.append(index)
	var step = player_input.size() - 1

	if player_input[step] != sequence[step]:
		await _on_wrong_input()
		return

	if player_input.size() == sequence.size():
		player_turn = false
		_set_buttons_disabled(true)
		if current_round == ROUNDS_TO_WIN:
			_play_sfx(sfx_win)
			await get_tree().create_timer(0.5).timeout
			_on_win()
		else:
			_play_sfx(sfx_correct)
			$UI/MessageLabel.text = "✅ Correct! Get ready..."
			await get_tree().create_timer(1.0).timeout
			_next_round()

func _on_wrong_input() -> void:
	game_active = false
	player_turn = false
	_set_buttons_disabled(true)
	_play_sfx(sfx_wrong)
	for i in NUM_BUTTONS:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1, 0, 0)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		buttons[i].add_theme_stylebox_override("normal", style)
	$UI/MessageLabel.text = "❌ Wrong! Security triggered!"
	await get_tree().create_timer(2.0).timeout
	_on_lose_or_give_up()

func _process(delta: float) -> void:
	if not game_active:
		return
	time_left -= delta
	$UI/TimerLabel.text = "⏱ Time: %d" % ceil(time_left)
	if time_left <= 10:
		$UI/TimerLabel.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		if not tick_played:
			tick_played = true
			_play_sfx(sfx_tick)
	if time_left <= 0:
		game_active = false
		_play_sfx(sfx_wrong)
		$UI/MessageLabel.text = "Time's up! Alarm triggered!"
		await get_tree().create_timer(1.5).timeout
		_on_lose_or_give_up()

func _on_give_up_pressed() -> void:
	if not game_active:
		return
	game_active = false
	player_turn = false
	$UI/MessageLabel.text = "Abort! Security incoming..."
	await get_tree().create_timer(1.5).timeout
	_on_lose_or_give_up()

func _on_win() -> void:
	game_active = false
	for i in NUM_BUTTONS:
		_set_button_lit(buttons[i], i)
	$UI/MessageLabel.text = "✅ Lock cracked! You're in!"
	await get_tree().create_timer(1.5).timeout
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.show()
	completed.emit(true)

func _on_lose_or_give_up() -> void:
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.show()
	completed.emit(false)
