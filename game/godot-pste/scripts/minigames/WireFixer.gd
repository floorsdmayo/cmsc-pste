extends Control

const minigame_id = "wirefixer"
signal completed(success: bool)

var wire_logic
var left_buttons: Array = []
var right_buttons: Array = []
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var selected_left: int = -1

var colors = {
	"red": Color(1, 0, 0),
	"blue": Color(0, 0.4, 1),
	"green": Color(0, 0.8, 0),
	"yellow": Color(1, 0.9, 0)
}

func _ready() -> void:
	get_tree().get_first_node_in_group("room_container").hide()
	wire_logic = WireFixer.new()
	add_child(wire_logic)
	wire_logic.setup(4)
	wire_logic.wire_connected.connect(_on_wire_connected)
	wire_logic.wire_wrong.connect(_on_wire_wrong)
	wire_logic.puzzle_complete.connect(_on_puzzle_complete)
	$CanvasLayer/CloseButton.pressed.connect(_on_give_up)
	_build_ui()

func _build_ui() -> void:
	for i in range(4):
		var color_name = wire_logic.get_color(i)
		var btn = Button.new()
		btn.text = color_name.capitalize()
		btn.modulate = colors[color_name]
		btn.custom_minimum_size = Vector2(100, 40)
		btn.pressed.connect(_on_left_pressed.bind(i))
		$CanvasLayer/WirePanel/LeftColumn.add_child(btn)
		left_buttons.append(btn)

	for i in range(4):
		var color_index = wire_logic.get_right_order(i)
		var color_name = wire_logic.get_color(color_index)
		var btn = Button.new()
		btn.text = color_name.capitalize()
		btn.modulate = colors[color_name]
		btn.custom_minimum_size = Vector2(100, 40)
		btn.pressed.connect(_on_right_pressed.bind(i))
		$CanvasLayer/WirePanel/RightColumn.add_child(btn)
		right_buttons.append(btn)

func _on_left_pressed(index: int) -> void:
	selected_left = index
	wire_logic.set_selected_left(index)

func _on_right_pressed(index: int) -> void:
	if selected_left == -1:
		return
	var success = wire_logic.try_connect(selected_left, index)
	if not success:
		# flash red to indicate wrong
		right_buttons[index].modulate = Color(1, 0, 0)
		await get_tree().create_timer(0.3).timeout
		var color_index = wire_logic.get_right_order(index)
		right_buttons[index].modulate = colors[wire_logic.get_color(color_index)]
	selected_left = -1
	wire_logic.set_selected_left(-1)

func _on_wire_connected(left_index: int) -> void:
	left_buttons[left_index].disabled = true

func _on_wire_wrong(_left_index: int) -> void:
	pass

func _on_puzzle_complete() -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(true)

func _on_give_up() -> void:
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(false)
