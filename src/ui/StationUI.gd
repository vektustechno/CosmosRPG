extends Control

@onready var title: Label = $Panel/Title
@onready var shop_btn: Button = $Panel/ShopButton
@onready var shipyard_btn: Button = $Panel/ShipyardButton
@onready var missions_btn: Button = $Panel/MissionsButton
@onready var close_btn: Button = $Panel/CloseButton
@onready var shop_ui: Control = $ShopUI
@onready var shipyard_ui: Control = $ShipyardUI

var current_station: StationData

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(_on_close)
	shop_btn.pressed.connect(_open_shop)
	shipyard_btn.pressed.connect(_open_shipyard)

func open(station: StationData) -> void:
	current_station = station
	visible = true
	title.text = station.name
	shop_btn.visible = "shop" in station.services
	shipyard_btn.visible = station.has_shipyard

func _open_shop() -> void:
	if shop_ui and shop_ui.has_method("open"):
		shop_ui.open(current_station)

func _open_shipyard() -> void:
	if shipyard_ui and shipyard_ui.has_method("open"):
		shipyard_ui.open(current_station)

func _on_close() -> void:
	visible = false
