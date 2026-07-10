extends Control

@onready var faction_list: VBoxContainer = $Panel/FactionList
@onready var detail_name: Label = $Panel/Detail/Name
@onready var detail_rep: Label = $Panel/Detail/Reputation
@onready var detail_tier: Label = $Panel/Detail/Tier
@onready var detail_desc: Label = $Panel/Detail/Description
@onready var close_btn: Button = $Panel/CloseButton

var faction_system: FactionSystem

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(_on_close)
	faction_system = _find_faction_system()
	if faction_system:
		_populate_list()

func open() -> void:
	visible = true
	if faction_system:
		_populate_list()

func _populate_list() -> void:
	for child in faction_list.get_children():
		child.queue_free()
	
	for fid in faction_system.factions.keys():
		var f = faction_system.get_faction(fid)
		if not f:
			continue
		
		var btn = Button.new()
		btn.text = f.name
		btn.pressed.connect(_on_faction_selected.bind(fid))
		faction_list.add_child(btn)

func _on_faction_selected(fid: String) -> void:
	var f = faction_system.get_faction(fid)
	if not f:
		return
	detail_name.text = f.name
	detail_rep.text = "Reputation: %d" % f.reputation
	detail_tier.text = "Tier: %d" % faction_system.get_faction_tier(fid)
	detail_desc.text = f.description

func _on_close() -> void:
	visible = false

func _find_faction_system() -> FactionSystem:
	var root = Engine.get_main_loop().root
	for child in root.get_children():
		if child is FactionSystem:
			return child
	return null
