extends Control

@onready var currency_label: Label = $MarginContainer/VBoxContainer/CurrencyLabel
@onready var upgrade_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/UpgradeList
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

const UPGRADE_NAMES: Dictionary = {
	"max_health": "最大生命值",
	"max_sanity": "最大理智值",
	"move_speed": "移动速度",
	"damage": "攻击力",
	"reload_speed": "换弹速度",
	"starting_ammo": "初始弹药",
	"dash_cooldown": "闪避冷却",
}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_refresh()

func _refresh() -> void:
	currency_label.text = "货币: %d" % MetaProgression.currency

	for child in upgrade_list.get_children():
		child.queue_free()

	for upgrade_id in UPGRADE_NAMES:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label = Label.new()
		name_label.text = UPGRADE_NAMES[upgrade_id]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var level = MetaProgression.get_upgrade_level(upgrade_id)
		var max_level = MetaProgression.get_max_level(upgrade_id)
		var level_label = Label.new()
		level_label.text = "Lv.%d/%d" % [level, max_level]
		level_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.add_child(level_label)

		var btn = Button.new()
		if level >= max_level:
			btn.text = "已满"
			btn.disabled = true
		elif MetaProgression.can_afford(upgrade_id):
			btn.text = "升级 (%d)" % MetaProgression.UPGRADE_COSTS[upgrade_id][level]
		else:
			btn.text = "升级 (%d)" % MetaProgression.UPGRADE_COSTS[upgrade_id][level]
			btn.disabled = true

		btn.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
		row.add_child(btn)
		upgrade_list.add_child(row)

func _on_upgrade_pressed(upgrade_id: String) -> void:
	if MetaProgression.purchase_upgrade(upgrade_id):
		_refresh()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
