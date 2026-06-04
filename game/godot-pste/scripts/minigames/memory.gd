extends Control

const minigame_id = "memory"
signal completed(success: bool)

const EMOJIS = ["🔥", "💧", "⭐", "🌙", "🍀", "🎵", "💎", "🌸"]
const TOTAL_PAIRS = 8
const TIME_LIMIT  = 90

const ASSET_DIR    = "res://assets/minigames/memory/"
const BG_IMAGE     = ASSET_DIR + "background.png"
const CARD_BACK    = ASSET_DIR + "card_back.png"
const CARD_FRONT   = ASSET_DIR + "card_front.png"
const CARD_MATCHED = ASSET_DIR + "card_matched.png"
const FONT_PATH    = ASSET_DIR + "font.ttf"
# ── Audio: drop these files in the same folder to enable sound ───────────────
const SFX_MATCH   = ASSET_DIR + "sfx_correct.mp3"   # card pair matched
const SFX_WRONG   = ASSET_DIR + "sfx_wrong.mp3"     # mismatch flip-back
const SFX_WIN     = ASSET_DIR + "success.wav"       # all pairs found
const SFX_TIMEOUT = ASSET_DIR + "sfx_timeout.mp3"   # time ran out

const COLOR_BG           = Color(0.06, 0.06, 0.10)
const COLOR_CARD_DEFAULT = Color(0.14, 0.20, 0.36)
const COLOR_CARD_FLIPPED = Color(0.22, 0.32, 0.54)
const COLOR_CARD_MATCHED = Color(0.18, 0.65, 0.28)
const COLOR_CARD_WRONG   = Color(0.68, 0.18, 0.18)
const COLOR_ACCENT       = Color(0.94, 0.82, 0.28)

var card_values  : Array = []
var card_buttons : Array = []
var flipped      : Array = []
var matched      : Array = []
var first_pick   : int   = -1
var second_pick  : int   = -1
var can_flip     : bool  = true
var matches_found: int   = 0
var time_left    : float = TIME_LIMIT
var timer_active : bool  = false
var loaded_font          = null

# Audio players — null if the file wasn't found
var sfx_match:   AudioStreamPlayer = null
var sfx_wrong:   AudioStreamPlayer = null
var sfx_win:     AudioStreamPlayer = null
var sfx_timeout: AudioStreamPlayer = null

var _msg_label   : Label
var _timer_label : Label
var _cards_grid  : GridContainer
var _give_up_btn : Button

# ════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.hide()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport().get_visible_rect().size

	_load_font()
	_load_audio()
	_build_scene()
	timer_active = true

# ── Font ──────────────────────────────────────────────────────────────────────
func _load_font() -> void:
	if ResourceLoader.exists(FONT_PATH):
		loaded_font = load(FONT_PATH)

# ── Audio ─────────────────────────────────────────────────────────────────────
func _load_audio() -> void:
	var entries = [
		[SFX_MATCH,   "sfx_match"],
		[SFX_WRONG,   "sfx_wrong"],
		[SFX_WIN,     "sfx_win"],
		[SFX_TIMEOUT, "sfx_timeout"],
	]
	for entry in entries:
		var path = entry[0]
		var prop = entry[1]
		if ResourceLoader.exists(path):
			var player = AudioStreamPlayer.new()
			player.stream = load(path)
			add_child(player)
			set(prop, player)

func _play(player: AudioStreamPlayer) -> void:
	if player:
		player.play()

# ════════════════════════════════════════════════════════════════════════════
#  Scene construction
# ════════════════════════════════════════════════════════════════════════════
func _build_scene() -> void:
	# Background
	if ResourceLoader.exists(BG_IMAGE):
		var bg = TextureRect.new()
		bg.texture = load(BG_IMAGE)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.z_index = -1
		add_child(bg)
	else:
		var bg = ColorRect.new()
		bg.color = COLOR_BG
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.z_index = -1
		add_child(bg)

	# Outer centering container
	var outer = CenterContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(outer)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 16)
	outer.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "🃏  Memory Match"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	if loaded_font:
		title.add_theme_font_override("font", loaded_font)
	vbox.add_child(title)

	# Message label
	_msg_label = Label.new()
	_msg_label.text = "Match all the pairs!"
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_label.custom_minimum_size = Vector2(680, 40)
	_msg_label.add_theme_font_size_override("font_size", 22)
	_msg_label.add_theme_color_override("font_color", Color.WHITE)
	if loaded_font:
		_msg_label.add_theme_font_override("font", loaded_font)
	vbox.add_child(_msg_label)

	# Timer label
	_timer_label = Label.new()
	_timer_label.text = "⏱  Time: " + str(TIME_LIMIT) + "s"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.custom_minimum_size = Vector2(680, 36)
	_timer_label.add_theme_font_size_override("font_size", 20)
	_timer_label.add_theme_color_override("font_color", Color.WHITE)
	if loaded_font:
		_timer_label.add_theme_font_override("font", loaded_font)
	vbox.add_child(_timer_label)

	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(680, 4)
	vbox.add_child(sep)

	# Card grid
	var grid_wrap = CenterContainer.new()
	grid_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(grid_wrap)

	_cards_grid = GridContainer.new()
	_cards_grid.columns = 4
	_cards_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_cards_grid.add_theme_constant_override("h_separation", 12)
	_cards_grid.add_theme_constant_override("v_separation", 12)
	grid_wrap.add_child(_cards_grid)

	# ── Give Up button — same style as wirefixer ──────────────────────────
	_give_up_btn = Button.new()
	_give_up_btn.text = "✕  Give Up"
	_give_up_btn.custom_minimum_size = Vector2(200, 48)
	_give_up_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

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

	_give_up_btn.add_theme_stylebox_override("normal",  normal_style)
	_give_up_btn.add_theme_stylebox_override("hover",   hover_style)
	_give_up_btn.add_theme_stylebox_override("pressed", pressed_style)
	_give_up_btn.add_theme_color_override("font_color", Color.WHITE)
	_give_up_btn.add_theme_font_size_override("font_size", 18)
	if loaded_font:
		_give_up_btn.add_theme_font_override("font", loaded_font)
	_give_up_btn.pressed.connect(_on_give_up_pressed)
	vbox.add_child(_give_up_btn)

	_setup_cards()

# ════════════════════════════════════════════════════════════════════════════
#  Card logic
# ════════════════════════════════════════════════════════════════════════════
func _setup_cards() -> void:
	for c in _cards_grid.get_children():
		c.queue_free()

	card_values.clear(); flipped.clear(); matched.clear(); card_buttons.clear()
	first_pick = -1; second_pick = -1; matches_found = 0; can_flip = true

	for emoji in EMOJIS:
		card_values.append(emoji)
		card_values.append(emoji)
	card_values.shuffle()

	for i in 16:
		flipped.append(false)
		matched.append(false)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(150, 88)
		btn.text = "?"
		btn.add_theme_font_size_override("font_size", 34)
		btn.add_theme_color_override("font_color", Color.WHITE)
		if loaded_font:
			btn.add_theme_font_override("font", loaded_font)
		_style_card(btn, "default")
		_cards_grid.add_child(btn)
		card_buttons.append(btn)
		btn.pressed.connect(_on_card_pressed.bind(i))

func _style_card(btn: Button, state: String) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2

	match state:
		"default":
			if ResourceLoader.exists(CARD_BACK):
				var s = StyleBoxTexture.new()
				s.texture = load(CARD_BACK)
				btn.add_theme_stylebox_override("normal", s)
				btn.add_theme_stylebox_override("hover",  s)
				return
			style.bg_color     = COLOR_CARD_DEFAULT
			style.border_color = Color(0.30, 0.40, 0.65)
		"flipped":
			if ResourceLoader.exists(CARD_FRONT):
				var s = StyleBoxTexture.new()
				s.texture = load(CARD_FRONT)
				btn.add_theme_stylebox_override("normal", s)
				btn.add_theme_stylebox_override("hover",  s)
				return
			style.bg_color     = COLOR_CARD_FLIPPED
			style.border_color = Color(0.50, 0.70, 1.00)
		"matched":
			if ResourceLoader.exists(CARD_MATCHED):
				var s = StyleBoxTexture.new()
				s.texture = load(CARD_MATCHED)
				btn.add_theme_stylebox_override("normal", s)
				btn.add_theme_stylebox_override("hover",  s)
				return
			style.bg_color     = COLOR_CARD_MATCHED
			style.border_color = Color(0.40, 0.90, 0.50)

	btn.add_theme_stylebox_override("normal", style)
	var hover = style.duplicate()
	hover.bg_color = style.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", hover)

# ── Timer ─────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not timer_active:
		return
	time_left -= delta
	_update_timer_label()
	if time_left <= 0.0:
		time_left    = 0.0
		timer_active = false
		_on_time_up()

func _update_timer_label() -> void:
	var s = int(ceil(time_left))
	_timer_label.text = "Time: " + str(s) + "s"
	if time_left <= 20:
		_timer_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.28))
	elif time_left <= 40:
		_timer_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.20))
	else:
		_timer_label.add_theme_color_override("font_color", Color.WHITE)

# ── Card interaction ──────────────────────────────────────────────────────────
func _on_card_pressed(index: int) -> void:
	if not can_flip or not timer_active:
		return
	if flipped[index] or matched[index]:
		return
	if first_pick == index:
		return

	flipped[index] = true
	card_buttons[index].text = card_values[index]
	_style_card(card_buttons[index], "flipped")

	if first_pick == -1:
		first_pick = index
	else:
		second_pick = index
		can_flip    = false
		await get_tree().create_timer(0.8).timeout
		_check_match()

func _check_match() -> void:
	if card_values[first_pick] == card_values[second_pick]:
		matched[first_pick] = true
		matched[second_pick] = true
		_style_card(card_buttons[first_pick],  "matched")
		_style_card(card_buttons[second_pick], "matched")
		matches_found += 1
		_play(sfx_match)
		_msg_label.text = "✅  " + str(matches_found) + " / " + str(TOTAL_PAIRS) + " pairs found!"
		if matches_found == TOTAL_PAIRS:
			await get_tree().create_timer(0.5).timeout
			_on_win()
	else:
		_play(sfx_wrong)
		flipped[first_pick]  = false
		flipped[second_pick] = false
		card_buttons[first_pick].modulate  = Color(1.0, 0.35, 0.35)
		card_buttons[second_pick].modulate = Color(1.0, 0.35, 0.35)
		await get_tree().create_timer(0.35).timeout
		card_buttons[first_pick].text  = "?"
		card_buttons[second_pick].text = "?"
		card_buttons[first_pick].modulate  = Color.WHITE
		card_buttons[second_pick].modulate = Color.WHITE
		_style_card(card_buttons[first_pick],  "default")
		_style_card(card_buttons[second_pick], "default")

	first_pick  = -1
	second_pick = -1
	can_flip    = true

# ── End states ────────────────────────────────────────────────────────────────
func _on_time_up() -> void:
	can_flip = false
	_play(sfx_timeout)
	_msg_label.text = "Time's up! Better luck next time."
	for i in 16:
		card_buttons[i].text = card_values[i]
		if not matched[i]:
			card_buttons[i].modulate = Color(1.0, 0.35, 0.35)
	await get_tree().create_timer(2.0).timeout
	_finish(false)

func _on_give_up_pressed() -> void:
	timer_active = false
	_msg_label.text = "You gave up…"
	await get_tree().create_timer(1.0).timeout
	_finish(false)

func _on_win() -> void:
	timer_active = false
	_play(sfx_win)
	_msg_label.text = "🎉  You matched them all! Amazing!"
	await get_tree().create_timer(1.5).timeout
	_finish(true)

func _finish(success: bool) -> void:
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.show()
	completed.emit(success)
