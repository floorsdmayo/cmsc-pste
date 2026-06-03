extends Control
const minigame_id = "lockpicker"
signal completed(success: bool)
var blocks: Array = []
var selected_index: int = -1
var time_left: float = 60.0
var game_active: bool = true

const COLOR_DEFAULT = Color(0.15, 0.15, 0.2)
const COLOR_SELECTED = Color(1.0, 0.8, 0.0)
const COLOR_CORRECT = Color(0.0, 0.8, 0.3)

func _ready() -> void:
	var room = get_tree().get_first_node_in_group("room_container")
	if room:
		room.hide()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$UI.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$UI.alignment = BoxContainer.ALIGNMENT_CENTER

	$UI/MessageLabel.custom_minimum_size = Vector2(800, 50)
	$UI/MessageLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$UI/MessageLabel.add_theme_font_size_override("font_size", 24)
	$UI/MessageLabel.add_theme_color_override("font_color", Color(1, 1, 1))

	$UI/TimerLabel.custom_minimum_size = Vector2(800, 50)
	$UI/TimerLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$UI/TimerLabel.add_theme_font_size_override("font_size", 20)
	$UI/TimerLabel.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	$UI/Blocks.columns = 5
	$UI/Blocks.custom_minimum_size = Vector2(800, 220)
	$UI/Blocks.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	for i in 10:
		var btn = $UI/Blocks.get_child(i)
		btn.custom_minimum_size = Vector2(150, 100)
		btn.add_theme_font_size_override("font_size", 28)
		btn.add_theme_color_override("font_color", Color(1, 1, 1))

	$UI/GiveUpButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	$UI/GiveUpButton.custom_minimum_size = Vector2(200, 50)
	$UI/GiveUpButton.add_theme_font_size_override("font_size", 18)
	$UI/GiveUpButton.add_theme_color_override("font_color", Color(1, 1, 1))

	_setup_blocks()
	_update_display()
	$UI/MessageLabel.text = "🔒 Arrange 1 to 10 to crack the lock!"
	$UI/TimerLabel.text = "⏱ Time: 60"
	$UI/GiveUpButton.pressed.connect(_on_give_up_pressed)

func _process(delta: float) -> void:
	if not game_active:
		return
	time_left -= delta
	$UI/TimerLabel.text = "⏱ Time: %d" % ceil(time_left)
	if time_left <= 10:
		$UI/TimerLabel.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	if time_left <= 0:
		game_active = false
		$UI/MessageLabel.text = "⏰ Time's up! The alarm triggered!"
		await get_tree().create_timer(1.5).timeout
		_on_lose_or_give_up()

func _setup_blocks() -> void:
	blocks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	blocks.shuffle()
	for i in 10:
		var btn = $UI/Blocks.get_child(i)
		btn.pressed.connect(_on_block_pressed.bind(i))

func _on_block_pressed(index: int) -> void:
	if not game_active:
		return
	if selected_index == -1:
		selected_index = index
		_update_display()
	else:
		var temp = blocks[selected_index]
		blocks[selected_index] = blocks[index]
		blocks[index] = temp
		selected_index = -1
		_update_display()
		_check_win()

func _check_win() -> void:
	for i in 10:
		if blocks[i] != i + 1:
			return
	_on_win()

func _update_display() -> void:
	for i in 10:
		var btn = $UI/Blocks.get_child(i)
		btn.text = str(blocks[i])
		# Use self_modulate on stylebox instead, keep modulate white
		if i == selected_index:
			btn.modulate = COLOR_SELECTED
		elif blocks[i] == i + 1:
			btn.modulate = COLOR_CORRECT
		else:
			btn.modulate = Color(1, 1, 1)  # white = no tint, button stays dark from its style

func _on_give_up_pressed() -> void:
	if not game_active:
		return
	game_active = false
	$UI/MessageLabel.text = "🚨 Abort! Security incoming..."
	await get_tree().create_timer(1.5).timeout
	_on_lose_or_give_up()

func _on_win() -> void:
	game_active = false
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
