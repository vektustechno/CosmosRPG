class_name StationData
extends Resource

@export var station_id: String = ""
@export var name: String = "Station"
@export var faction_id: String = "federation"
@export var has_shipyard: bool = false
@export var services: Array = ["shop"]
@export var fuel_price: int = 50
@export var repair_cost_per_hp: int = 2
