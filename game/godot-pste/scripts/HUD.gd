extends Control
@onready var stamina_label = $StatsBar/StaminaLabel
@onready var hearts_label = $StatsBar/HeartsLabel
@onready var inventory_button = $InventoryButton

func _ready() -> void:
	GameManager.stamina_changed.connect(_on_stamina_changed)
	GameManager.hearts_changed.connect(_on_hearts_changed)
	_update_display()

func _update_display() -> void:
	stamina_label.text = "Stamina: %d/%d" % [GameManager.ss.get_stamina(), GameManager.ss.get_max_stamina()]
	hearts_label.text = "❤ %d/%d" % [GameManager.ss.get_hearts(), GameManager.ss.get_max_hearts()]

func _on_stamina_changed(new_value: int) -> void:
	stamina_label.text = "Stamina: %d/%d" % [new_value, GameManager.ss.get_max_stamina()]

func _on_hearts_changed(new_value: int) -> void:
	hearts_label.text = "❤ %d/%d" % [new_value, GameManager.ss.get_max_hearts()]
