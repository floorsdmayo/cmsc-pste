extends Control

@onready var background = $Background
@onready var overlay    = $Overlay
@onready var vbox       = $VBox
@onready var title      = $VBox/Title
@onready var spacer     = $VBox/Spacer
@onready var btn_start  = $VBox/BtnStart
@onready var btn_quit   = $VBox/BtnQuit

const GAME_SCENE := "res://main.tscn"

func _on_start_pressed():
	get_tree().change_scene_to_file(GAME_SCENE)
func _ready():
	_setup_background()
	_setup_overlay()
	_setup_vbox()
	_setup_title()
	_setup_spacer()
	_setup_button(btn_start, "Start", Color("#F5E8B8"))
	_setup_button(btn_quit,  "Quit",  Color("#C7BDA0"))

	btn_start.pressed.connect(_on_start_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)


func _setup_background():
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


func _setup_overlay():
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color("#2E0A40B8") # last 2 digits = alpha (B8 ≈ 72%)


func _setup_vbox():
	vbox.set_anchor(SIDE_LEFT,   0.0)
	vbox.set_anchor(SIDE_TOP,    0.0)
	vbox.set_anchor(SIDE_RIGHT,  0.0)
	vbox.set_anchor(SIDE_BOTTOM, 1.0)
	vbox.size.x = 420
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)


func _setup_title():
	title.text = "DEADLOCK\nDESCENT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.uppercase = true
	title.add_theme_font_size_override("font_size", 82)
	title.add_theme_color_override("font_color",        Color("#F5E8B8"))
	title.add_theme_color_override("font_shadow_color", Color(0.5, 0.2, 0.0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)


func _setup_spacer():
	spacer.custom_minimum_size = Vector2(0, 48)


func _setup_button(btn: Button, label: String, normal_color: Color):
	btn.text = label
	btn.flat = true
	btn.custom_minimum_size = Vector2(220, 52)
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color",         normal_color)
	btn.add_theme_color_override("font_hover_color",   Color("#F7D038"))
	btn.add_theme_color_override("font_pressed_color", Color("#F0A800"))

func _on_quit_pressed():
	get_tree().quit()
