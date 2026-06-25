## ConsoleCommand — 开发者控制台命令抽象基类。
## 每条命令自包含名称、别名、用法签名、描述、执行逻辑和参数补全。
## 参考 odyssey-cards 的 ChatScreenCommand（C#），适配为 GDScript。
extends RefCounted
class_name ConsoleCommand

## 命令名（唯一标识，不含 / 前缀）。
var name: String = ""

## 命令别名。
var aliases: PackedStringArray = []

## 用法签名（如 "/heal [N]"）。
var signature: String = ""

## 描述文本。
var description: String = ""

## 执行命令。args 不包含命令名本身，只包含空格分隔的参数。
## 返回 Dictionary: { "success": bool, "message": String }
## message 中的特殊标记：
##   "__CLEAR__" — 清空控制台输出
func execute(_args: PackedStringArray) -> Dictionary:
	return _fail("未实现")

## 获取参数补全候选。partial_arg 为用户已输入的部分参数文本。
## 返回 Array[Dictionary]，每个元素: { "insert_text": String, "primary_text": String, "secondary_text": String }
## insert_text 应为纯参数值（不带命令前缀，引擎会自动补全）。
## 返回空数组表示该命令无参数补全。
func get_arg_candidates(_partial_arg: String) -> Array:
	return []

# ===== 受保护的 helper（供子类使用）=====

func _ok(message: String) -> Dictionary:
	return {"success": true, "message": message}

func _fail(message: String) -> Dictionary:
	return {"success": false, "message": message}

## 构造补全候选 Dictionary。
static func candidate(insert_text: String, primary_text: String, secondary_text: String = "") -> Dictionary:
	return {
		"insert_text": insert_text,
		"primary_text": primary_text,
		"secondary_text": secondary_text,
	}

# ===== 场景查找 helper =====

## 获取当前 SceneTree（命令是 RefCounted，无 get_tree()）。
func _scene_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree

## 获取玩家节点（在 "player" 组中）。不在场景或无玩家时返回 null。
func _player() -> Node:
	var tree := _scene_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("player")

## 获取战争迷雾 CanvasLayer（在 "fog_of_war" 组中）。
func _fog_layer() -> CanvasLayer:
	var tree := _scene_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("fog_of_war") as CanvasLayer

## 获取所有 Enemy 节点。
func _all_enemies() -> Array:
	var tree := _scene_tree()
	if tree == null:
		return []
	return tree.get_nodes_in_group("enemy")

## 查找当前关卡的 LevelGenerator（通过玩家父节点或遍历根节点）。
func _find_level_generator() -> Node:
	var tree := _scene_tree()
	if tree == null:
		return null
	# 优先通过玩家父节点
	var p := _player()
	if p != null and p.get_parent() is LevelGenerator:
		return p.get_parent()
	# 遍历根节点
	for node in tree.root.get_children():
		if node is LevelGenerator:
			return node
	return null
