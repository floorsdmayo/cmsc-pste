extends Control

const minigame_id = "run_away"
signal completed(success: bool)

# --- Config ---
const TOTAL_SQUARES = 10

# Each round: [speed, safe_zone_start, safe_zone_end]
const ROUND_CONFIG = [
	[0.30, 0.35, 0.65],  # Round 1:  slow, wide, center
	[0.50, 0.10, 0.30],  # Round 2:  medium, short, left side
	[0.40, 0.60, 0.90],  # Round 3:  medium, wide, right side
	[0.70, 0.45, 0.55],  # Round 4:  fast, tiny, center
	[0.45, 0.05, 0.35],  # Round 5:  medium, wide, far left
	[0.80, 0.65, 0.75],  # Round 6:  fast, short, right
	[0.55, 0.30, 0.55],  # Round 7:  medium, medium, left-center
	[0.90, 0.70, 0.80],  # Round 8:  very fast, tiny, far right
	[0.60, 0.15, 0.45],  # Round 9:  fast, medium, left
	[0.95, 0.42, 0.52],  # Round 10: brutal, tiny, center
]

# --- State ---
var current_square: int = 0
var indicator_pos: float = 0.0
var indicator_dir: float = 1.0
var indicator_speed: float = 0.30
var safe_start: float = 0.35
var safe_end: float = 0.65
var waiting_for_input: bool = true
var animating: bool = false

# --- Node refs ---
@onready var indicator_bar     = $MarginContainer/VBox/BarContainer/IndicatorBar
@onready var safe_zone_rect    = $MarginContainer/VBox/BarContainer/SafeZone
@onready var squares_container = $MarginContainer/VBox/SquaresContainer
@onready var result_label      = $MarginContainer/VBox/ResultLabel
@onready var instruction_label = $MarginContainer/VBox/InstructionLabel
@onready var bar_container     = $MarginContainer/VBox/BarContainer

var square_nodes: Array = []

# -------------------------------------------------------
func _ready() -> void:
	get_tree().get_first_node_in_group("room_container").hide()
	safe_zone_rect.color = Color(0.2, 0.85, 0.3, 0.5)
	indicator_bar.color = Color(0.95, 0.2, 0.2)
	indicator_bar.z_index = 1
	_build_squares()
	instruction_label.text = "Press SPACE when the marker is in the green zone!"
	result_label.text = ""
	await get_tree().process_frame
	if bar_container.size.x < 10:
		bar_container.custom_minimum_size = Vector2(600, 40)
		await get_tree().process_frame
	_reset_round()

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
	if current_square < ROUND_CONFIG.size():
		var cfg = ROUND_CONFIG[current_square]
		indicator_speed = cfg[0]
		safe_start = cfg[1]
		safe_end = cfg[2]
	indicator_pos = 0.0
	indicator_dir = 1.0
	waiting_for_input = true
	animating = false
	_update_bar_visuals()

# -------------------------------------------------------
func _process(delta: float) -> void:
	if not waiting_for_input:
		return
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
	indicator_bar.position.x = indicator_pos * bar_width - indicator_bar.size.x * 0.5
	indicator_bar.size.y = bar_container.size.y
	safe_zone_rect.position.x = safe_start * bar_width
	safe_zone_rect.size.x = (safe_end - safe_start) * bar_width
	safe_zone_rect.size.y = bar_container.size.y

# -------------------------------------------------------
func _input(event: InputEvent) -> void:
	if not waiting_for_input:
		return
	if event.is_action_pressed("ui_accept"):
		_on_player_press()

func _on_player_press() -> void:
	waiting_for_input = false
	var in_zone = indicator_pos >= safe_start and indicator_pos <= safe_end
	if in_zone:
		_advance_square()
	else:
		_on_lose_or_give_up()

func _advance_square() -> void:
	square_nodes[current_square].color = Color(0.2, 0.8, 0.2)
	current_square += 1
	if current_square >= TOTAL_SQUARES:
		_on_win()
		return
	result_label.text = "Nice! %d / %d" % [current_square, TOTAL_SQUARES]
	# Load next round config without resetting indicator position or direction
	var cfg = ROUND_CONFIG[current_square]
	indicator_speed = cfg[0]
	safe_start = cfg[1]
	safe_end = cfg[2]
	waiting_for_input = true

# -------------------------------------------------------
func _on_win() -> void:
	result_label.text = "You escaped! 🎉"
	await get_tree().create_timer(1.2).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(true)

func _on_lose_or_give_up() -> void:
	result_label.text = "Caught! Too slow..."
	for sq in square_nodes:
		sq.color = Color(0.8, 0.2, 0.2)
	await get_tree().create_timer(1.2).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(false)
