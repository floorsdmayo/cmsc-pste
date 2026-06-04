extends ColorRect

var snake_logic = null
var cell_size = 20
var grid_width = 20
var grid_height = 20
var pong_logic = null
var pong_phase = false

func _draw() -> void:
	if snake_logic == null: return

	var phase = snake_logic.get_phase()

	# background
	draw_rect(Rect2(Vector2.ZERO, Vector2(grid_width * cell_size, grid_height * cell_size)), Color(0.1, 0.1, 0.1))

	# walls
	for w in snake_logic.get_walls():
		draw_rect(Rect2(Vector2(w.x * cell_size, w.y * cell_size), Vector2(cell_size, cell_size)), Color(0.595, 0.349, 0.225, 1.0))

	# statues
	for statue in snake_logic.get_statues():
		var pos = statue["pos"]
		var dur = statue["durability"]
		var color = Color(0.6, 0.5, 0.4) if dur > 1 else Color(0.8, 0.7, 0.6)
		draw_rect(Rect2(Vector2(pos.x * cell_size, pos.y * cell_size), Vector2(cell_size, cell_size)), color)
		if dur == 1:
			draw_line(
				Vector2(pos.x * cell_size, pos.y * cell_size),
				Vector2((pos.x + 1) * cell_size, (pos.y + 1) * cell_size),
				Color(0.3, 0.2, 0.1), 2
			)

	# apple/heart
	if not pong_phase:
		var ap = snake_logic.get_apple_pos()
		draw_rect(Rect2(Vector2(ap.x * cell_size, ap.y * cell_size), Vector2(cell_size, cell_size)), Color(1, 0.2, 0.2))

	# snake body
	var body = snake_logic.get_snake_body()
	for i in range(body.size()):
		var seg = body[i]
		var color = Color(0.2, 0.8, 0.2) if i == 0 else Color(0.1, 0.6, 0.1)
		draw_rect(Rect2(Vector2(seg.x * cell_size, seg.y * cell_size), Vector2(cell_size - 1, cell_size - 1)), color)

	# light mode darkness overlay
	if phase == 0:
		_draw_darkness()

	# pong elements
	if pong_logic != null:
		# ball
		var ball = pong_logic.get_ball_pos()
		draw_rect(Rect2(Vector2(ball.x * cell_size, ball.y * cell_size), Vector2(cell_size, cell_size)), Color(1, 1, 1))

		# alex paddle
		var alex_y = pong_logic.get_alex_y()
		var alex_h = pong_logic.get_alex_height()
		var paddle_top = (alex_y - alex_h / 2.0) * cell_size
		draw_rect(Rect2(Vector2((grid_width - 1) * cell_size, paddle_top), Vector2(cell_size, alex_h * cell_size)), Color(1, 0.5, 0))

func _draw_darkness() -> void:
	var head = (snake_logic.get_snake_body())[0]
	var head_center = Vector2(head.x * cell_size + cell_size / 2.0, head.y * cell_size + cell_size / 2.0)
	var radius = snake_logic.get_light_radius() * cell_size
	for x in range(grid_width):
		for y in range(grid_height):
			var cell_center = Vector2(x * cell_size + cell_size / 2.0, y * cell_size + cell_size / 2.0)
			if cell_center.distance_to(head_center) > radius:
				draw_rect(Rect2(Vector2(x * cell_size, y * cell_size), Vector2(cell_size, cell_size)), Color(0, 0, 0, 0.95))
