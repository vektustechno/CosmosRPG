class_name HUD
extends CanvasLayer

@onready var ap_bar: HBoxContainer = $TopBar/APBar
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var end_turn_btn: Button = $TopBar/EndTurnButton
@onready var hp_bar: ProgressBar = $ShipStatus/HPBar
@onready var hp_label: Label = $ShipStatus/HPBar/Label
@onready var shield_front: ProgressBar = $ShipStatus/Shields/Front
@onready var shield_left: ProgressBar = $ShipStatus/Shields/Left
@onready var shield_right: ProgressBar = $ShipStatus/Shields/Right
@onready var shield_rear: ProgressBar = $ShipStatus/Shields/Rear
@onready var credits_label: Label = $Resources/Credits
@onready var sector_label: Label = $Resources/Sector
@onready var xp_bar: ProgressBar = $Progression/XPBar
@onready var level_label: Label = $Progression/LevelLabel
@onready var mission_label: Label = $Missions/MissionLabel
@onready var log_label: RichTextLabel = $CombatLog/LogLabel
@onready var msg_label: Label = $MessageLabel

var log_messages: Array = []

func _ready() -> void:
	if end_turn_btn:
		end_turn_btn.pressed.connect(_on_end_turn)

func refresh(ship: Ship) -> void:
	if not ship:
		return
	
	hp_bar.max_value = ship.max_hp
	hp_bar.value = ship.current_hp
	hp_label.text = "%d / %d" % [ship.current_hp, ship.max_hp]
	
	var shield_bars = {"front": shield_front, "left": shield_left, "right": shield_right, "rear": shield_rear}
	for side in ["front", "left", "right", "rear"]:
		var bar = shield_bars.get(side)
		if bar:
			bar.max_value = ship.max_shields.get(side, 1)
			bar.value = ship.current_shields.get(side, 0)

func refresh_ap(ship: Ship) -> void:
	if not ap_bar or not ship:
		return
	for child in ap_bar.get_children():
		child.queue_free()
	for i in range(ship.max_action_points):
		var seg = ColorRect.new()
		seg.custom_minimum_size = Vector2(16, 24)
		seg.color = Color.GREEN if i < ship.action_points else Color.DIM_GRAY
		ap_bar.add_child(seg)

func refresh_credits(amount: int) -> void:
	if credits_label:
		credits_label.text = "Credits: %d" % amount

func refresh_xp(current: int, needed: int, level: int) -> void:
	if xp_bar and level_label:
		xp_bar.max_value = needed
		xp_bar.value = current
		level_label.text = "Lv.%d" % level

func show_mission_text(text: String) -> void:
	if mission_label:
		mission_label.text = text

func add_log(msg: String) -> void:
	log_messages.append(msg)
	if log_messages.size() > 50:
		log_messages.pop_front()
	if log_label:
		log_label.text = "\n".join(log_messages)

func show_message(text: String, duration: float = 2.0) -> void:
	if msg_label:
		msg_label.text = text
		msg_label.modulate = Color.WHITE
		var tween = create_tween()
		tween.tween_property(msg_label, "modulate", Color.TRANSPARENT, duration)

func set_turn_text(text: String) -> void:
	if turn_label:
		turn_label.text = text

func _on_end_turn() -> void:
	if Global.turn_manager:
		Global.turn_manager.end_turn()
