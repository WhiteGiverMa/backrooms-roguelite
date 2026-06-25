extends Control

@onready var panel: Panel = $Panel
@onready var grid: GridContainer = $Panel/GridContainer
@onready var weapon_label: Label = $Panel/WeaponLabel
@onready var flashlight_btn: Button = $Panel/FlashlightBtn

var slot_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_slots()
	flashlight_btn.pressed.connect(_on_flashlight_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle()

func _create_slots() -> void:
	for i in range(6):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 60)
		btn.text = ""
		btn.pressed.connect(_on_slot_pressed.bind(i))
		grid.add_child(btn)
		slot_buttons.append(btn)

func toggle() -> void:
	visible = not visible
	if visible:
		get_tree().paused = true
		_refresh()
	else:
		get_tree().paused = false

func _refresh() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var inv = player.weapon_inventory
	var cur = player.current_weapon

	for i in slot_buttons.size():
		if i < inv.size():
			var w = inv[i] as Weapon
			var txt = w.weapon_name + "\n%d/%d" % [w.current_ammo, w.max_ammo]
			if w == cur:
				txt = "[E] " + txt
			slot_buttons[i].text = txt
		else:
			slot_buttons[i].text = ""

	if player.has_flashlight:
		flashlight_btn.text = "手电筒 " + ("[开]" if player.flashlight_on else "[关]")
	else:
		flashlight_btn.text = ""

func _on_slot_pressed(idx: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	if idx < player.weapon_inventory.size():
		player.equip_weapon(player.weapon_inventory[idx])
		_refresh()

func _on_flashlight_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.has_flashlight:
		return
	player._toggle_flashlight()
	_refresh()
