extends CanvasLayer

var visible_menu: bool = false
var panel: PanelContainer

func _ready() -> void:
	layer = 999  # always on top
	
	var toggle_btn = Button.new()
	toggle_btn.text = "DEBUG"
	toggle_btn.position = Vector2(10, 10)
	toggle_btn.pressed.connect(_toggle_menu)
	add_child(toggle_btn)
	
	panel = PanelContainer.new()
	panel.position = Vector2(10, 50)
	panel.custom_minimum_size = Vector2(220, 0)
	panel.visible = false
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# floor teleport
	_add_label(vbox, "── FLOORS ──")
	for i in [0, 1, 2, 3, 4, 5, 6, 7]:
		var btn = Button.new()
		btn.text = "Go to Floor %d" % i
		btn.pressed.connect(func(): _goto_floor(i))
		vbox.add_child(btn)
	
	# stamina controls
	_add_label(vbox, "── STAMINA ──")
	_add_button(vbox, "Fill Stamina",     func(): GameManager.ss.refill_stamina())
	_add_button(vbox, "Drain Stamina",    func(): GameManager.ss.use_stamina(GameManager.ss.get_stamina()))
	_add_button(vbox, "Trigger Adrenaline", func(): GameManager.ss.trigger_adrenaline())
	
	# minigame flags
	_add_label(vbox, "── UNLOCK MINIGAMES ──")
	_add_button(vbox, "Clear All Minigames", _clear_all_minigames)
	_add_button(vbox, "Clear Jigsaw (elevator)", func(): GameManager.ss.on_minigame_cleared("jigsaw"))
	_add_button(vbox, "Clear Wirefixer",    func(): GameManager.ss.on_minigame_cleared("wirefixer"))
	_add_button(vbox, "Clear Find Diff",    func(): GameManager.ss.on_minigame_cleared("find_the_difference"))
	
	# hearts
	_add_label(vbox, "── HEARTS ──")
	_add_button(vbox, "Full Hearts",  func(): GameManager.ss.rest())
	_add_button(vbox, "Lose Heart",   func(): GameManager.ss.lose_heart())

func _toggle_menu() -> void:
	visible_menu = !visible_menu
	panel.visible = visible_menu

func _goto_floor(floor_num: int) -> void:
	GameManager.current_floor = floor_num
	GameManager.change_room("res://scenes/rooms/Floor%d.tscn" % floor_num)

func _clear_all_minigames() -> void:
	for id in ["wirefixer", "jigsaw", "find_the_difference", "memory", "lockpicker"]:
		GameManager.ss.on_minigame_cleared(id)

func _add_button(parent: VBoxContainer, label: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = label
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _add_label(parent: VBoxContainer, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	parent.add_child(lbl)
