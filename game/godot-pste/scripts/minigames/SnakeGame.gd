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

@onready var game_board = $CanvasLayer/GameBoard

var phase_taunts = {
	0: "Sssso you found my nest... Allow me to shed some light on your ssituation — by taking it away! Conssider thiss your practical exam!",
	1: "Impresssive... but can you handle my WALL-gorithmsss?",
	2: "You think you can COMPILE me?! I'll turn YOU to SSSTONEEE!"
}

func _ready() -> void:
	get_tree().get_first_node_in_group("room_container").hide()
	snake_logic = SnakeLogic.new()
	add_child(snake_logic)
	snake_logic.setup(grid_width, grid_height)
	snake_logic.apple_eaten.connect(_on_apple_eaten)
	snake_logic.phase_changed.connect(_on_phase_changed)
	snake_logic.game_ended.connect(_on_game_ended)
	$CanvasLayer/UI/CloseButton.pressed.connect(_on_give_up)
	$CanvasLayer/GameBoard.size = Vector2(grid_width * cell_size, grid_height * cell_size)
	$CanvasLayer/GameBoard.custom_minimum_size = Vector2(grid_width * cell_size, grid_height * cell_size)
	$CanvasLayer/UI/TauntLabel.text = phase_taunts[0]
	game_board.snake_logic = snake_logic
	game_board.grid_width = grid_width
	game_board.grid_height = grid_height
	game_board.cell_size = cell_size
	running = true

func _process(delta: float) -> void:
	if not running: return
	# Snake always steps on timer — during pong it becomes a moving paddle
	timer += delta
	if timer >= snake_logic.get_move_speed():
		timer = 0.0
		snake_logic.step()
	if pong_phase:
		pong_logic.step(delta, snake_logic.get_snake_body())
		game_board.pong_logic = pong_logic
	game_board.queue_redraw()

func _input(event: InputEvent) -> void:
	if not running: return
	# All 4 directions work in both phases
	if event.is_action_pressed("ui_right"):
		snake_logic.set_direction(1, 0)
	elif event.is_action_pressed("ui_left"):
		snake_logic.set_direction(-1, 0)
	elif event.is_action_pressed("ui_up"):
		snake_logic.set_direction(0, -1)
	elif event.is_action_pressed("ui_down"):
		snake_logic.set_direction(0, 1)

func _on_apple_eaten(score: int) -> void:
	$CanvasLayer/UI/ScoreLabel.text = "Sssir Rrryan HP: %d / 67" % max(67 - score, 0)

func _on_phase_changed(new_phase: int) -> void:
	$CanvasLayer/UI/PhaseLabel.text = "Phase %d" % (new_phase + 1)
	$CanvasLayer/UI/TauntLabel.text = phase_taunts[new_phase]

func _on_game_ended(success: bool) -> void:
	if not success:
		running = false
		get_tree().get_first_node_in_group("room_container").show()
		completed.emit(false)
		return
	_start_pong_transition()

func _start_pong_transition() -> void:
	running = false
	$CanvasLayer/UI/TauntLabel.text = "You may have defeated my algorithmss... but have you met my SSERVE-ior?! I sssummon — ALEX EALA!"
	$CanvasLayer/UI/ScoreLabel.text = "Get ready..."
	$CanvasLayer/UI/PhaseLabel.text = "FINAL PHASE"
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
	$CanvasLayer/UI/TauntLabel.text = "Ssstruggling? Allow me to RALLY some backup!"
	_update_pong_score()

func _on_point_scored(_player_scored: bool) -> void:
	_update_pong_score()

func _update_pong_score() -> void:
	$CanvasLayer/UI/ScoreLabel.text = "You: %d  |  Alex: %d" % [pong_logic.get_player_score(), pong_logic.get_alex_score()]

func _on_pong_ended(player_won: bool) -> void:
	running = false
	if player_won:
		$CanvasLayer/UI/TauntLabel.text = "Fault! FAULT! Thiss can't be happening..."
		await get_tree().create_timer(2.0).timeout
		$CanvasLayer/UI/TauntLabel.text = "Imposssible... I'll add this to your final exam..."
		await get_tree().create_timer(2.0).timeout
	else:
		$CanvasLayer/UI/TauntLabel.text = "Out of boundsss! Just like your chanccess of esscaping!"
		await get_tree().create_timer(2.0).timeout
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(player_won)

func _on_give_up() -> void:
	running = false
	get_tree().get_first_node_in_group("room_container").show()
	completed.emit(false)
