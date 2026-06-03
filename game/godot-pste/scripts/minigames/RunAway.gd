extends Control

const minigame_id = "run_away"
signal completed(success: bool)

# --- Config ---
const TOTAL_SQUARES = 5
const SAFE_ZONE_START = 0.35   # safe region: 35% to 65% of the bar
const SAFE_ZONE_END   = 0.65
const INDICATOR_SPEED_START = 0.4   # normalized units per second
const SPEED_INCREMENT   = 0.07      # gets faster each square

# --- State ---
var current_square: int = 0
var indicator_pos: float = 0.0      # 0.0 to 1.0
var indicator_dir: float = 1.0
var indicator_speed: float = INDICATOR_SPEED_START
var waiting_for_input: bool = true
var animating: bool = false

# --- Node refs (set these up in your scene) ---
@onready var indicator_bar   = $MarginContainer/VBox/BarContainer/IndicatorBar
@onready var safe_zone_rect  = $MarginContainer/VBox/BarContainer/SafeZone
@onready var squares_container = $MarginContainer/VBox/SquaresContainer
@onready var result_label    = $MarginContainer/VBox/ResultLabel
@onready var instruction_label = $MarginContainer/VBox/InstructionLabel
@onready var bar_container   = $MarginContainer/VBox/BarContainer

var square_nodes: Array = []

# -------------------------------------------------------
func _ready() -> void:
	get_tree().get_first_node_in_group("room_container").hide()
	_build_squares()
	_reset_round()
	instruction_label.text = "Press SPACE when the marker is in the green zone!"
	result_label.text = ""

func _build_squares() -> void:
	for child in squares_container.get_children():
		child.queue_free()
	square_nodes.clear()
	for i in range(TOTAL_SQUARES):
		var sq = ColorRect.new()
		sq.custom_minimum_size = Vector2(48, 48)
		sq.color = Color(0.3, 0.3, 0.3)
		squares_container.add_child(sq)
		square_nodes.append(sq)

func _reset_round() -> void:
	indicator_pos = 0.0
	indicator_dir = 1.0
	waiting_for_input = true
	animating = false
	_update_bar_visuals()

# -------------------------------------------------------
func _process(delta: float) -> void:
	if not waiting_for_input:
		return

	# Move indicator back and forth
	indicator_pos += indicator_dir * indicator_speed * delta
	if indicator_pos >= 1.0:
		indicator_pos = 1.0
		indicator_dir = -1.0
	elif indicator_pos <= 0.0:
		indicator_pos = 0.0
		indicator_dir = 1.0

	_update_bar_visuals()

func _update_bar_visuals() -> void:
	if not is_instance_valid(indicator_bar):
		return
	var bar_width = bar_container.size.x
	# Position the indicator
	indicator_bar.position.x = indicator_pos * bar_width - indicator_bar.size.x * 0.5
	# Color the safe zone
	safe_zone_rect.position.x = SAFE_ZONE_START * bar_width
	safe_zone_rect.size.x = (SAFE_ZONE_END - SAFE_ZONE_START) * bar_width

# -------------------------------------------------------
func _input(event: InputEvent) -> void:
	if not waiting_for_input:
		return
	if event.is_action_pressed("ui_accept"):   # Space / Enter
		_on_player_press()

func _on_player_press() -> void:
	waiting_for_input = false
	var in_zone = indicator_pos >= SAFE_ZONE_START and indicator_pos <= SAFE_ZONE_END

	if in_zone:
		_advance_square()
	else:
		_on_lose_or_give_up()

func _advance_square() -> void:
	# Color the completed square green
	square_nodes[current_square].color = Color(0.2, 0.8, 0.2)
	current_square += 1

	if current_square >= TOTAL_SQUARES:
		_on_win()
		return

	# Next round is faster
	indicator_speed += SPEED_INCREMENT
	result_label.text = "Nice! %d / %d" % [current_square, TOTAL_SQUARES]

	# Brief pause then resume
	await get_tree().create_timer(0.4).timeout
	_reset_round()

# -------------------------------------------------------
func _on_win() -> void:
	result_label.text = "You escaped!"
	await get_tree().create_timer(1.2).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(true)

func _on_lose_or_give_up() -> void:
	result_label.text = "Caught! Too slow..."
	# Flash squares red
	for sq in square_nodes:
		sq.color = Color(0.8, 0.2, 0.2)
	await get_tree().create_timer(1.2).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(false)
