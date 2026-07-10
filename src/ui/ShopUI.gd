extends Control

@onready var item_grid: GridContainer = $Panel/ItemGrid
@onready var player_items: VBoxContainer = $Panel/PlayerItems
@onready var credits_label: Label = $Panel/CreditsLabel
@onready var close_btn: Button = $Panel/CloseButton

var station: StationData
var shop_inventory: Array = []

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(_on_close)

func open(station_data: StationData) -> void:
	station = station_data
	visible = true
	var level = 1
	if Global.player_ship:
		level = Global.player_ship.stats.get("level", 1)
	shop_inventory = ShopSystem.generate_inventory(station, level)
	_refresh()

func _refresh() -> void:
	for child in item_grid.get_children():
		child.queue_free()
	for child in player_items.get_children():
		child.queue_free()
	
	if Global.player_ship:
		credits_label.text = "Credits: %d" % Global.player_ship.inventory.credits
	
	for i in range(shop_inventory.size()):
		var item = shop_inventory[i]
		if item is EquipmentData:
			var btn = Button.new()
			btn.text = "%s (%d cr)" % [item.get_display_name(), ShopSystem.calculate_price(item)]
			btn.pressed.connect(_buy_item.bind(i))
			item_grid.add_child(btn)
	
	if Global.player_ship:
		var inv = Global.player_ship.inventory
		for i in range(inv.items.size()):
			var item = inv.get_item(i)
			if item:
				var btn = Button.new()
				btn.text = item.get_display_name() + " [SELL]"
				btn.pressed.connect(_sell_item.bind(i))
				player_items.add_child(btn)

func _buy_item(shop_index: int) -> void:
	if shop_index < 0 or shop_index >= shop_inventory.size():
		return
	if not Global.player_ship:
		return
	
	var item = shop_inventory[shop_index]
	var result = ShopSystem.buy_item(item, Global.player_ship.inventory, Global.player_ship.inventory.credits)
	if result.get("success"):
		shop_inventory.remove_at(shop_index)
	_refresh()

func _sell_item(inv_index: int) -> void:
	if not Global.player_ship:
		return
	ShopSystem.sell_item(inv_index, Global.player_ship.inventory)
	_refresh()

func _on_close() -> void:
	visible = false
