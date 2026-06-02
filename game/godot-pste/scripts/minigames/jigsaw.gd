extends Control

const minigame_id = "jigsaw"
signal completed(success: bool)

const GRID_SIZE = 4
const TOTAL_PIECES = 16
const TIME_LIMIT = 120

var pieces: Array = []
var piece_buttons: Array = []
var selected_index: int = -1
var time_left: float = TIME_LIMIT
var timer_active: bool = false
var moves: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_pieces()
	$UI/GiveUpButton.pressed.connect(_on_give_up_pressed)
	$UI/MessageLabel.text = "Arrange the pieces in order 1 to 16!"
	$UI/MovesLabel.text = "Moves: 0"
	timer_active = true

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
	$UI/TimerLabel.text = "Time: " + str(seconds) + "s"
	if time_left <= 20:
		$UI/TimerLabel.modulate = Color(1, 0.3, 0.3)
	elif time_left <= 40:
		$UI/TimerLabel.modulate = Color(1, 0.8, 0.2)
	else:
		$UI/TimerLabel.modulate = Color(1, 1, 1)

func _setup_pieces() -> void:
	pieces.clear()
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
		var btn = $UI/Grid.get_child(i)
		btn.text = str(pieces[i])
		btn.modulate = Color(1, 1, 1)
		piece_buttons.append(btn)
		btn.pressed.connect(_on_piece_pressed.bind(i))

func _on_piece_pressed(index: int) -> void:
	if not timer_active:
		return

	if selected_index == -1:
		selected_index = index
		piece_buttons[index].modulate = Color(1, 1, 0)
		$UI/MessageLabel.text = "Now pick where to swap it!"
	else:
		if selected_index == index:
			selected_index = -1
			piece_buttons[index].modulate = Color(1, 1, 1)
			$UI/MessageLabel.text = "Arrange the pieces in order 1 to 16!"
			return

		var temp = pieces[selected_index]
		pieces[selected_index] = pieces[index]
		pieces[index] = temp

		piece_buttons[selected_index].text = str(pieces[selected_index])
		piece_buttons[index].text = str(pieces[index])

		piece_buttons[selected_index].modulate = Color(1, 1, 1)
		piece_buttons[index].modulate = Color(1, 1, 1)

		selected_index = -1
		moves += 1
		$UI/MovesLabel.text = "Moves: " + str(moves)
		$UI/MessageLabel.text = "Arrange the pieces in order 1 to 16!"

		_check_win()

func _check_win() -> void:
	for i in TOTAL_PIECES:
		if pieces[i] != i + 1:
			return
	_on_win()

func _highlight_correct_pieces() -> void:
	for i in TOTAL_PIECES:
		if pieces[i] == i + 1:
			piece_buttons[i].modulate = Color(0.4, 1, 0.4)
		else:
			piece_buttons[i].modulate = Color(1, 1, 1)

func _on_time_up() -> void:
	timer_active = false
	$UI/MessageLabel.text = "Time's up! So close!"
	for i in TOTAL_PIECES:
		piece_buttons[i].text = str(pieces[i])
		if pieces[i] != i + 1:
			piece_buttons[i].modulate = Color(1, 0.4, 0.4)
		else:
			piece_buttons[i].modulate = Color(0.4, 1, 0.4)
	await get_tree().create_timer(2.0).timeout
	_on_lose_or_give_up()

func _on_give_up_pressed() -> void:
	timer_active = false
	$UI/MessageLabel.text = "Gave up! Here is the solution."
	for i in TOTAL_PIECES:
		piece_buttons[i].text = str(i + 1)
		piece_buttons[i].modulate = Color(0.4, 1, 0.4)
	await get_tree().create_timer(2.0).timeout
	_on_lose_or_give_up()

func _on_win() -> void:
	timer_active = false
	_highlight_correct_pieces()
	$UI/MessageLabel.text = "Puzzle solved in " + str(moves) + " moves!"
	await get_tree().create_timer(1.5).timeout
	# get_tree().get_first_node_in_group("room_container").show()
	completed.emit(true)

func _on_lose_or_give_up() -> void:
	timer_active = false
	await get_tree().create_timer(1.0).timeout
	# get_tree().get_first_node_in_group("room_container").show()
	completed.emit(false)
