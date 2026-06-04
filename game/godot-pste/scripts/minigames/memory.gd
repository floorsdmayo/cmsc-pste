extends Control

const minigame_id = "memory"
signal completed(success: bool)

const EMOJIS = ["🔥", "💧", "⭐", "🌙", "🍀", "🎵", "💎", "🌸"]
const TOTAL_PAIRS = 8
const TIME_LIMIT = 90

var card_values: Array = []
var card_buttons: Array = []
var flipped: Array = []
var matched: Array = []
var first_pick: int = -1
var second_pick: int = -1
var can_flip: bool = true
var matches_found: int = 0
var time_left: float = TIME_LIMIT
var timer_active: bool = false

func _ready() -> void:
	get_tree().get_first_node_in_group("room_container").hide()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_cards()
	
	$UI/GiveUpButton.pressed.connect(_on_give_up_pressed)
	$UI/MessageLabel.text = "Match all the pairs!"
	timer_active = true
	print("memory ready, card count: ", $UI/Cards.get_child_count())
	print("first card: ", $UI/Cards.get_child(0))
	# test if first card is clickable
	$UI/Cards.get_child(0).pressed.connect(func(): print("CARD 0 CLICKED"))

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

func _setup_cards() -> void:
	card_values.clear()
	flipped.clear()
	matched.clear()
	card_buttons.clear()
	first_pick = -1
	second_pick = -1
	matches_found = 0
	can_flip = true

	for emoji in EMOJIS:
		card_values.append(emoji)
		card_values.append(emoji)
	card_values.shuffle()

	for i in 16:
		flipped.append(false)
		matched.append(false)
		var btn = $UI/Cards.get_child(i)
		btn.text = "?"
		btn.modulate = Color(1, 1, 1)
		card_buttons.append(btn)
		btn.pressed.connect(_on_card_pressed.bind(i))

func _on_card_pressed(index: int) -> void:
	print("card pressed: ", index, " can_flip: ", can_flip, " timer: ", timer_active)
	if not can_flip:
		return
	if not timer_active:
		return
	if flipped[index] or matched[index]:
		return
	if first_pick == index:
		return

	flipped[index] = true
	card_buttons[index].text = card_values[index]

	if first_pick == -1:
		first_pick = index
	else:
		second_pick = index
		can_flip = false
		await get_tree().create_timer(0.8).timeout
		_check_match()

func _check_match() -> void:
	if card_values[first_pick] == card_values[second_pick]:
		matched[first_pick] = true
		matched[second_pick] = true
		card_buttons[first_pick].modulate = Color(0.4, 1, 0.4)
		card_buttons[second_pick].modulate = Color(0.4, 1, 0.4)
		matches_found += 1
		$UI/MessageLabel.text = str(matches_found) + " / " + str(TOTAL_PAIRS) + " pairs found!"
		if matches_found == TOTAL_PAIRS:
			await get_tree().create_timer(0.5).timeout
			_on_win()
	else:
		flipped[first_pick] = false
		flipped[second_pick] = false
		card_buttons[first_pick].text = "?"
		card_buttons[second_pick].text = "?"
		card_buttons[first_pick].modulate = Color(1, 0.6, 0.6)
		card_buttons[second_pick].modulate = Color(1, 0.6, 0.6)
		await get_tree().create_timer(0.3).timeout
		card_buttons[first_pick].modulate = Color(1, 1, 1)
		card_buttons[second_pick].modulate = Color(1, 1, 1)

	first_pick = -1
	second_pick = -1
	can_flip = true

func _on_time_up() -> void:
	can_flip = false
	$UI/MessageLabel.text = "Time's up! You ran out of time!"
	for i in 16:
		card_buttons[i].text = card_values[i]
		if not matched[i]:
			card_buttons[i].modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(2.0).timeout
	_on_lose_or_give_up()

func _on_give_up_pressed() -> void:
	timer_active = false
	$UI/MessageLabel.text = "Gave up!"
	await get_tree().create_timer(1.0).timeout
	_on_lose_or_give_up()

func _on_win() -> void:
	timer_active = false
	$UI/MessageLabel.text = "You matched them all! Amazing!"
	await get_tree().create_timer(1.5).timeout
	completed.emit(true)

func _on_lose_or_give_up() -> void:
	timer_active = false
	$UI/MessageLabel.text = "Better luck next time."
	await get_tree().create_timer(1.5).timeout
	completed.emit(false)
