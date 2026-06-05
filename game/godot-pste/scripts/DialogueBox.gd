extends Control
signal dialogue_finished

@export var type_speed: float = 0.035
@onready var speaker_label: Label      = $Panel/VBox/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/VBox/DialogueText
@onready var continue_hint: Label      = $Panel/VBox/ContinueHint
@onready var character_sprite: TextureRect = $CharacterSprite

var SPEAKERS := {
	"NARRATOR": { "name": "",         "color": "",        "sprite": "" },
	"MC":       { "name": "...",      "color": "#5b9bd5", "sprite": "" },
	"ATE GIRL": { "name": "Ate Girl", "color": "#e8a030", "sprite": "res://assets/sprites/ate.png" },
	"JANITOR":  { "name": "Janitor",  "color": "#9b6bbf", "sprite": "res://assets/sprites/janitor.png" },
	"GUARD":    { "name": "Guard",    "color": "#c0392b", "sprite": "res://assets/sprites/guard.png" },
	"SIR RYAN": { "name": "Sir Ryan", "color": "#e91e8c", "sprite": "res://assets/sprites/sir.png" },
}

var _lines: Array[String] = []
var _current_line: int    = 0
var _typing: bool         = false
var _skip_requested: bool = false

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.13, 0.09, 0.75)
	style.border_color = Color(0.63, 0.50, 0.31, 1.0)
	style.set_border_width_all(2)
	style.set_content_margin_all(0)
	$Panel.add_theme_stylebox_override("panel", style)
	$Panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	$Panel/VBox.anchor_left   = 0.0
	$Panel/VBox.anchor_right  = 1.0
	$Panel/VBox.anchor_top    = 0.0
	$Panel/VBox.anchor_bottom = 1.0
	$Panel/VBox.offset_left   = 32
	$Panel/VBox.offset_right  = -32
	$Panel/VBox.offset_top    = 24
	$Panel/VBox.offset_bottom = -24
	$Panel/VBox.add_theme_constant_override("separation", 8)

	anchor_left   = 0.05
	anchor_right  = 0.95
	anchor_top    = 0.68
	anchor_bottom = 0.98
	offset_left   = 0
	offset_right  = 0
	offset_top    = 0
	offset_bottom = 0

	text_label.bbcode_enabled = true
	text_label.fit_content = false
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.add_theme_color_override("default_color", Color(0.93, 0.89, 0.78))
	text_label.add_theme_font_size_override("normal_font_size", 18)

	speaker_label.add_theme_color_override("font_color", Color(0.93, 0.89, 0.78))
	speaker_label.add_theme_font_size_override("font_size", 18)

	continue_hint.text = "▼"
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_hint.add_theme_color_override("font_color", Color(0.63, 0.50, 0.31))

	character_sprite.anchor_left   = 0.75
	character_sprite.anchor_right  = 1.0
	character_sprite.anchor_bottom = 0.68
	character_sprite.offset_left   = 0
	character_sprite.offset_right  = 8
	character_sprite.offset_top    = -500
	character_sprite.offset_bottom = 0
	character_sprite.expand_mode   = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	character_sprite.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func start(lines: Array[String]) -> void:
	_lines        = lines
	_current_line = 0
	show()
	_show_line(_lines[0])

func _handle_command(cmd: String) -> void:
	if cmd == "WHITE_OUT":
		var bg = get_tree().get_first_node_in_group("room_background")
		if bg:
			var tween = create_tween()
			tween.tween_property(bg, "modulate", Color(1,1,1,1), 0.5)
	elif cmd == "BLACK_BG":
		var bg = get_tree().get_first_node_in_group("room_background")
		if bg:
			var tween = create_tween()
			tween.tween_property(bg, "modulate", Color(0,0,0,1), 0.5)
	elif cmd == "RESTORE_BG":
		var bg = get_tree().get_first_node_in_group("room_background")
		if bg:
			var tween = create_tween()
			tween.tween_property(bg, "modulate", Color(1,1,1,1), 0.5)
	elif cmd.begins_with("BG:"):
		var path = cmd.substr(3)
		var bg = get_tree().get_first_node_in_group("room_background")
		if bg and ResourceLoader.exists(path):
			bg.texture = load(path)
	elif cmd.begins_with("SPRITE:"):
		var parts = cmd.substr(7).split(",")
		if parts.size() == 2:
			SPEAKERS[parts[0]]["sprite"] = parts[1]
	elif cmd == "FADE_BLACK":
		var overlay = ColorRect.new()
		overlay.color = Color(0, 0, 0, 0)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		get_tree().root.add_child(overlay)
		var tween = create_tween()
		tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 1.5)
		
	
func _show_line(raw: String) -> void:
	var speaker_key := "NARRATOR"
	var text        := raw
	if raw.begins_with("[CMD:"):
		var end = raw.find("]")
		var cmd = raw.substr(5, end - 5)
		_handle_command(cmd)
		_advance()
		return

	if raw.begins_with("["):
		var end := raw.find("]")
		if end != -1:
			speaker_key = raw.substr(1, end - 1)
			text        = raw.substr(end + 2)
	_apply_speaker(speaker_key)
	text_label.text = ""
	continue_hint.hide()
	_typing         = true
	_skip_requested = false
	for ch in text:
		if _skip_requested:
			break
		text_label.text += ch
		await get_tree().create_timer(type_speed).timeout
	text_label.text = text
	_typing         = false
	continue_hint.show()

func _apply_speaker(key: String) -> void:
	var data: Dictionary = SPEAKERS.get(key, SPEAKERS["NARRATOR"])
	if data["name"] == "":
		speaker_label.hide()
	else:
		speaker_label.show()
		speaker_label.text = data["name"]
		speaker_label.add_theme_color_override("font_color", Color(data["color"]))
	if data["sprite"] != "":
		character_sprite.texture = load(data["sprite"])
		character_sprite.show()
	else:
		character_sprite.hide()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _typing:
			_skip_requested = true
		else:
			_advance()

func _advance() -> void:
	_current_line += 1
	if _current_line >= _lines.size():
		hide()
		dialogue_finished.emit()
	else:
		_show_line(_lines[_current_line])
