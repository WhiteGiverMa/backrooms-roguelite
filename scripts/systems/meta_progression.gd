extends Node

const SAVE_PATH = "user://meta_progression.save"

var currency: int = 0
var upgrades: Dictionary = {
	"max_health": 0,
	"max_sanity": 0,
	"move_speed": 0,
	"damage": 0,
	"reload_speed": 0,
	"starting_ammo": 0,
	"dash_cooldown": 0,
}

const UPGRADE_COSTS: Dictionary = {
	"max_health": [50, 100, 200, 400, 800],
	"max_sanity": [30, 60, 120, 240, 480],
	"move_speed": [40, 80, 160, 320, 640],
	"damage": [60, 120, 240, 480, 960],
	"reload_speed": [40, 80, 160, 320, 640],
	"starting_ammo": [30, 60, 120, 240, 480],
	"dash_cooldown": [50, 100, 200, 400, 800],
}

const UPGRADE_EFFECTS: Dictionary = {
	"max_health": 20.0,
	"max_sanity": 15.0,
	"move_speed": 25.0,
	"damage": 0.15,
	"reload_speed": 0.12,
	"starting_ammo": 10,
	"dash_cooldown": 0.5,
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_progression()

func add_run_reward() -> void:
	var summary = RunManager.get_run_summary()
	var earned = int(summary["floor"] * 10 + summary["kills"] * 2 + summary["rooms"] * 3)
	currency += earned
	save_progression()

func can_afford(upgrade_id: String) -> bool:
	var level = upgrades.get(upgrade_id, 0)
	if level >= UPGRADE_COSTS[upgrade_id].size():
		return false
	return currency >= UPGRADE_COSTS[upgrade_id][level]

func purchase_upgrade(upgrade_id: String) -> bool:
	if not can_afford(upgrade_id):
		return false
	var level = upgrades[upgrade_id]
	currency -= UPGRADE_COSTS[upgrade_id][level]
	upgrades[upgrade_id] = level + 1
	save_progression()
	return true

func get_upgrade_value(upgrade_id: String) -> float:
	var level = upgrades.get(upgrade_id, 0)
	return UPGRADE_EFFECTS[upgrade_id] * level

func get_upgrade_level(upgrade_id: String) -> int:
	return upgrades.get(upgrade_id, 0)

func get_max_level(upgrade_id: String) -> int:
	return UPGRADE_COSTS[upgrade_id].size()

func save_progression() -> void:
	var data = {
		"currency": currency,
		"upgrades": upgrades
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_progression() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data:
		currency = data.get("currency", 0)
		upgrades = data.get("upgrades", upgrades)

func reset_progression() -> void:
	currency = 0
	for key in upgrades:
		upgrades[key] = 0
	save_progression()
