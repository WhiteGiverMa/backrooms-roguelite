## ConsoleEngine — 控制台命令引擎（纯逻辑，不依赖 Godot UI）。
## 负责命令注册、执行调度、补全路由和历史管理。
## 参考 odyssey-cards 的 ChatScreenEngine（C#），适配为 GDScript。
extends RefCounted
class_name ConsoleEngine

const HISTORY_MAX: int = 40

# name/alias → command 路由表（不区分大小写）。
# 用 Dictionary，key 统一存小写。
var _commands_by_name: Dictionary = {}
# 保持注册顺序的唯一命令列表（用于 /help 和补全去重）。
var _registered: Array[ConsoleCommand] = []
# 历史输入队列（最新的在尾部）。
var history: PackedStringArray = []


# ===== 注册 =====

## 注册命令。自动注册 name 和所有 aliases 到查找表。
func register(cmd: ConsoleCommand) -> void:
	if cmd == null or cmd.name.is_empty():
		push_error("ConsoleEngine: 无法注册空命令")
		return
	# 避免重复加入 _registered
	for existing in _registered:
		if existing == cmd:
			return
	_registered.append(cmd)
	_commands_by_name[cmd.name.to_lower()] = cmd
	for alias in cmd.aliases:
		_commands_by_name[alias.to_lower()] = cmd

## 已注册的唯一命令列表（保持注册顺序）。
func get_commands() -> Array[ConsoleCommand]:
	return _registered

## 按名称或别名查找命令。token 不含 / 前缀。
func try_resolve(token: String) -> ConsoleCommand:
	return _commands_by_name.get(token.to_lower(), null)


# ===== 执行 =====

## 执行命令字符串。格式: "/<action> [参数]"。
## 返回 Dictionary: { "success": bool, "message": String }
func execute(input: String) -> Dictionary:
	input = input.strip_edges()
	if not input.begins_with("/"):
		return _fail("命令需以 / 开头，输入 /help 查看帮助")

	var content: String = input.substr(1)
	var parts: PackedStringArray = content.split(" ", false)
	if parts.is_empty():
		return _fail("命令需以 / 开头，输入 /help 查看帮助")

	var action: String = parts[0]
	var args: PackedStringArray = []
	for i in range(1, parts.size()):
		args.append(parts[i])

	# 历史记录（仅记录有效输入）
	_history_enqueue(input)

	var cmd: ConsoleCommand = try_resolve(action)
	if cmd == null:
		return _fail("未知命令: /%s，输入 /help 查看帮助" % action)

	return cmd.execute(args)


# ===== 补全 =====

## 根据当前输入生成补全候选列表。
## 分两阶段：命令名补全（空格前）、参数补全（空格后）。
func get_completions(input: String) -> Array:
	var result: Array = []
	if input.is_empty() or not input.begins_with("/"):
		return result

	var content: String = input.substr(1)
	var space_idx: int = content.find(" ")
	var partial_cmd: String
	var raw_command_token: String
	if space_idx < 0:
		partial_cmd = content.to_lower()
		raw_command_token = content
	else:
		partial_cmd = content.substr(0, space_idx).to_lower()
		raw_command_token = content.substr(0, space_idx)

	# 阶段 1：命令名补全（还没输入空格）
	if space_idx < 0:
		var unique_by_name: Dictionary = {}
		for cmd in _commands_by_name.values():
			if not unique_by_name.has(cmd.name):
				unique_by_name[cmd.name] = cmd
		var cmds: Array = unique_by_name.values()
		cmds.sort_custom(_compare_cmd_by_name)
		for cmd in cmds:
			if cmd.name.to_lower().begins_with(partial_cmd) or _has_alias_starting_with(cmd, partial_cmd):
				var signature_tail: String = ""
				var sig_space: int = cmd.signature.find(" ")
				if sig_space >= 0:
					signature_tail = cmd.signature.substr(sig_space + 1)
				var primary: String = ("/%s %s" % [cmd.name, signature_tail]).strip_edges()
				var alias_str: String = ""
				if cmd.aliases.size() > 0:
					alias_str = "（别名: %s）" % ", ".join(cmd.aliases)
				result.append(ConsoleCommand.candidate("/%s " % cmd.name, primary, cmd.description + alias_str))
				if result.size() >= 6:
					break
		return result

	# 阶段 2：参数补全（已输入空格）
	var matched_cmd: ConsoleCommand = try_resolve(raw_command_token)
	if matched_cmd == null:
		return result

	var arg_part: String = content.substr(space_idx + 1).strip_edges(true, false)
	# 去掉左侧空格后用于过滤
	arg_part = arg_part.lstrip(" ")
	var candidates: Array = matched_cmd.get_arg_candidates(arg_part)
	if candidates.is_empty():
		return result

	# 过滤并排序
	var filtered: Array = []
	for c in candidates:
		var insert_text: String = c.get("insert_text", "")
		if insert_text.findn(arg_part) >= 0 or arg_part.is_empty():
			filtered.append(c)
	filtered.sort_custom(_compare_candidate_by_insert_text)

	for candidate in filtered:
		var insert_text: String = candidate.get("insert_text", "")
		# 确保带完整命令前缀
		if not insert_text.to_lower().begins_with(("/%s " % raw_command_token).to_lower()):
			result.append({
				"insert_text": ("/%s %s " % [raw_command_token, insert_text]).strip_edges(true, false),
				"primary_text": candidate.get("primary_text", ""),
				"secondary_text": candidate.get("secondary_text", ""),
			})
		else:
			result.append(candidate)
		if result.size() >= 8:
			break
	return result


# ===== 历史持久化 =====

func save_history(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	for line in history:
		f.store_line(line)

func load_history(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	history.clear()
	while not f.eof_reached():
		var line: String = f.get_line()
		if not line.is_empty():
			history.append(line)
	# 截断到上限
	if history.size() > HISTORY_MAX:
		history = history.slice(history.size() - HISTORY_MAX)


# ===== 内部 =====

func _history_enqueue(input: String) -> void:
	# 去重：与最后一条相同则不重复记录
	if history.size() > 0 and history[history.size() - 1] == input:
		return
	history.append(input)
	if history.size() > HISTORY_MAX:
		history = history.slice(history.size() - HISTORY_MAX)

func _has_alias_starting_with(cmd: ConsoleCommand, prefix: String) -> bool:
	for alias in cmd.aliases:
		if alias.to_lower().begins_with(prefix):
			return true
	return false

static func _compare_cmd_by_name(a: ConsoleCommand, b: ConsoleCommand) -> bool:
	return a.name.to_lower() < b.name.to_lower()

static func _compare_candidate_by_insert_text(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("insert_text", "")) < String(b.get("insert_text", ""))

static func _fail(message: String) -> Dictionary:
	return {"success": false, "message": message}
