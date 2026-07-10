extends Control

@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	title_label.text = "CosmoRPG"
	title_label.add_theme_color_override("font_color", Color("#e94560"))
	title_label.add_theme_font_size_override("font_size", 64)
