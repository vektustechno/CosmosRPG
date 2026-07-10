extends Control

@onready var ship_list: VBoxContainer = $Panel/ShipList
@onready var current_ship_label: Label = $Panel/CurrentShip
@onready var credits_label: Label = $Panel/CreditsLabel
@onready var buy_btn: Button = $Panel/BuyButton
@onready var close_btn: Button = $Panel/CloseButton

var station: StationData
var available_ships: Array = []

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(_on_close)
	buy_btn.pressed.connect(_buy_selected)

func open(station_data: StationData) -> void:
	station = station_data
	visible = true
	_refresh()

func _refresh() -> void:
	for child in ship_list.get_children():
		child.queue_free()
	
	if not Global.player_ship:
		return
	
	current_ship_label.text = "Current: " + Global.player_ship.ship_class_id.capitalize()
	credits_label.text = "Credits: %d" % Global.player_ship.inventory.credits
	
	var rep = {}
	var faction_sys = _find_faction_system()
	if faction_sys:
		for fid in faction_sys.factions.keys():
			var f = faction_sys.get_faction(fid)
			if f:
				rep[fid] = f.reputation
	
	var player_level = 1
	available_ships = ShipyardSystem.get_available_ships(station.faction_id, player_level, rep)
	
	for cls in available_ships:
		if cls is ShipClassData:
			var btn = Button.new()
			btn.text = "%s — %d cr" % [cls.class_name, cls.price]
			btn.pressed.connect(_select_ship.bind(cls.class_id))
			ship_list.add_child(btn)

var selected_class_id: String = ""

func _select_ship(class_id: String) -> void:
	selected_class_id = class_id

func _buy_selected() -> void:
	if selected_class_id == "" or not Global.player_ship:
		return
	var result = ShipyardSystem.buy_ship(selected_class_id, Global.player_ship.inventory, Global.player_ship)
	if result.get("success"):
		_refresh()
		selected_class_id = ""

func _on_close() -> void:
	visible = false

func _find_faction_system() -> FactionSystem:
	var root = Engine.get_main_loop().root
	for child in root.get_children():
		if child is FactionSystem:
			return child
	return null
