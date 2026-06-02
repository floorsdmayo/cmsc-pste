extends Control

const minigame_id = "lockpicker"
signal completed(success: bool)

var blocks: Array = []
var selected_index: int = -1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_blocks()
	_update_display()
	$UI/MessageLabel.text = "Arrange the blocks in order 1 to 10!"
	$UI/GiveUpButton.pressed.connect(_on_give_up_pressed)

func _setup_blocks() -> void:
	blocks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	blocks.shuffle()
	for i in 10:
		var btn = $UI/Blocks.get_child(i)
		btn.pressed.connect(_on_block_pressed.bind(i))

func _on_block_pressed(index: int) -> void:
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
		if i == selected_index:
			btn.modulate = Color(1, 1, 0)
		else:
			btn.modulate = Color(1, 1, 1)

func _on_give_up_pressed() -> void:
	$UI/MessageLabel.text = "Gave up!"
	await get_tree().create_timer(1.0).timeout
	_on_lose_or_give_up()

func _on_win() -> void:
	$UI/MessageLabel.text = "Solved! Great job!"
	await get_tree().create_timer(1.5).timeout
	completed.emit(true)

func _on_lose_or_give_up() -> void:
	$UI/MessageLabel.text = "Better luck next time."
	await get_tree().create_timer(1.5).timeout
	completed.emit(false)
