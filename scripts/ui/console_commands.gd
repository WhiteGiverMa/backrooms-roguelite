## ConsoleCommands — 开发者控制台的具体命令实现集合。
## 每个内部类继承 ConsoleCommand，自包含执行逻辑。
## 参考 odyssey-cards 的 Commands/*Commands.cs，适配为 GDScript 内部类。
##
## 命令清单：
##   /help                显示帮助。别名 /?
##   /clear               清空控制台输出。别名 /cls
##   /god                 切换上帝模式（玩家无敌）。
##   /fog                 切换战争迷雾开启状态。
##   /heal [N]            恢复 N 点生命值，无参数则满血。别名 /h
##   /damage [N]          对自己造成 N 点伤害（默认 10）。别名 /dmg
##   /ammo                当前武器弹药填满。
##   /kill_all            清空当前楼层所有敌人。别名 /killall
##   /noclip              切换穿墙模式。别名 /nc
##   /sanity [N]          设置理智为 N，无参数则满理智。别名 /san
##   /floor [N]           跳到第 N 层（重新生成楼层）。
##   /currency [N]        增加 N 点局外货币（默认 100）。别名 /gold
##   /restart             重新生成当前楼层。别名 /r
extends RefCounted
class_name ConsoleCommands


# ===== /help =====

class HelpCommand extends ConsoleCommand:
	var _engine: ConsoleEngine = null

	func _init(engine: ConsoleEngine = null) -> void:
		name = "help"
		aliases = PackedStringArray(["?"])
		signature = "/help"
		description = "显示所有可用命令。"
		_engine = engine

	func execute(_args: PackedStringArray) -> Dictionary:
		if _engine == null:
			return _fail("命令引擎未初始化")
		var cmds: Array[ConsoleCommand] = _engine.get_commands()
		if cmds.is_empty():
			return _ok("暂无可用的开发者命令")
		# 去重（按 name）
		var seen: Dictionary = {}
		var unique: Array[ConsoleCommand] = []
		for cmd in cmds:
			if not seen.has(cmd.name):
				seen[cmd.name] = true
				unique.append(cmd)
		unique.sort_custom(_by_name)
		var lines: PackedStringArray = ["=== 开发者命令 ==="]
		for cmd in unique:
			var alias_str: String = ""
			if cmd.aliases.size() > 0:
				alias_str = "（别名: %s）" % ", ".join(cmd.aliases)
			# 对齐：签名占 28 字符宽度
			var sig_padded: String = cmd.signature
			while sig_padded.length() < 28:
				sig_padded += " "
			lines.append("  %s — %s%s" % [sig_padded, cmd.description, alias_str])
		return _ok("\n".join(lines))

	static func _by_name(a: ConsoleCommand, b: ConsoleCommand) -> bool:
		return a.name.to_lower() < b.name.to_lower()


# ===== /clear =====

class ClearCommand extends ConsoleCommand:
	func _init() -> void:
		name = "clear"
		aliases = PackedStringArray(["cls"])
		signature = "/clear"
		description = "清空控制台输出。"

	func execute(_args: PackedStringArray) -> Dictionary:
		return _ok("__CLEAR__")


# ===== /god — 切换上帝模式（玩家无敌）★ =====

class GodCommand extends ConsoleCommand:
	func _init() -> void:
		name = "god"
		signature = "/god"
		description = "切换上帝模式（玩家无敌，免疫所有伤害）。"

	func execute(_args: PackedStringArray) -> Dictionary:
		var p := _player()
		if p == null:
			return _fail("当前场景没有玩家（请先开始一局游戏）")
		if not ("is_invincible" in p):
			return _fail("玩家节点不支持上帝模式（缺少 is_invincible 字段）")
		p.is_invincible = not bool(p.is_invincible)
		var status: String = "开启" if p.is_invincible else "关闭"
		return _ok("上帝模式已%s" % status)


# ===== /fog — 切换战争迷雾 ★ =====

class FogCommand extends ConsoleCommand:
	func _init() -> void:
		name = "fog"
		signature = "/fog"
		description = "切换战争迷雾开启状态。"

	func execute(_args: PackedStringArray) -> Dictionary:
		var fog := _fog_layer()
		if fog == null:
			return _fail("当前场景没有战争迷雾节点（请先进入关卡）")
		fog.visible = not fog.visible
		var status: String = "开启" if fog.visible else "关闭"
		return _ok("战争迷雾已%s" % status)


# ===== /heal [N] =====

class HealCommand extends ConsoleCommand:
	func _init() -> void:
		name = "heal"
		aliases = PackedStringArray(["h"])
		signature = "/heal [N]"
		description = "恢复 N 点生命值，无参数则恢复满血。"

	func execute(args: PackedStringArray) -> Dictionary:
		var p := _player()
		if p == null:
			return _fail("当前场景没有玩家")
		if not p.has_method("heal"):
			return _fail("玩家节点不支持 heal()")
		if args.size() > 0:
			var n: float = float(args[0])
			p.heal(n)
			return _ok("恢复 %.0f 点生命值（当前 %.0f / %.0f）" % [n, float(p.health), float(p.max_health)])
		# 无参数 → 满血
		p.health = float(p.max_health)
		if p.has_signal("health_changed"):
			p.health_changed.emit(p.health, p.max_health)
		return _ok("生命值已恢复满（%.0f / %.0f）" % [float(p.health), float(p.max_health)])


# ===== /damage [N] =====

class DamageCommand extends ConsoleCommand:
	func _init() -> void:
		name = "damage"
		aliases = PackedStringArray(["dmg"])
		signature = "/damage [N]"
		description = "对自己造成 N 点伤害（默认 10），用于测试受伤/死亡。"

	func execute(args: PackedStringArray) -> Dictionary:
		var p := _player()
		if p == null:
			return _fail("当前场景没有玩家")
		if not p.has_method("take_damage"):
			return _fail("玩家节点不支持 take_damage()")
		var n: float = 10.0
		if args.size() > 0:
			n = float(args[0])
		p.take_damage(n)
		return _ok("对自己造成 %.0f 点伤害（当前 %.0f / %.0f）" % [n, float(p.health), float(p.max_health)])


# ===== /ammo =====

class AmmoCommand extends ConsoleCommand:
	func _init() -> void:
		name = "ammo"
		signature = "/ammo"
		description = "当前武器弹药填满。"

	func execute(_args: PackedStringArray) -> Dictionary:
		var p := _player()
		if p == null:
			return _fail("当前场景没有玩家")
		var weapon = p.get("current_weapon")
		if weapon == null:
			return _fail("玩家当前没有武器")
		weapon.current_ammo = int(weapon.max_ammo)
		# 通知 HUD
		if RunManager.has_signal("ammo_changed"):
			RunManager.ammo_changed.emit(int(weapon.current_ammo), int(weapon.max_ammo))
		return _ok("弹药已填满（%d / %d）" % [int(weapon.current_ammo), int(weapon.max_ammo)])


# ===== /kill_all =====

class KillAllCommand extends ConsoleCommand:
	func _init() -> void:
		name = "kill_all"
		aliases = PackedStringArray(["killall"])
		signature = "/kill_all"
		description = "清空当前楼层所有敌人。"

	func execute(_args: PackedStringArray) -> Dictionary:
		var enemies := _all_enemies()
		if enemies.is_empty():
			return _ok("当前没有敌人")
		var count: int = 0
		for enemy in enemies:
			if enemy is Enemy and not enemy.is_dead:
				enemy.die()
				count += 1
		return _ok("已清除 %d 个敌人" % count)


# ===== /noclip =====

class NoclipCommand extends ConsoleCommand:
	func _init() -> void:
		name = "noclip"
		aliases = PackedStringArray(["nc"])
		signature = "/noclip"
		description = "切换穿墙模式（无视碰撞）。"

	func execute(_args: PackedStringArray) -> Dictionary:
		var p := _player()
		if p == null:
			return _fail("当前场景没有玩家")
		if not ("is_noclip" in p):
			return _fail("玩家节点不支持穿墙模式（缺少 is_noclip 字段）")
		p.is_noclip = not bool(p.is_noclip)
		# 穿墙时关闭物理碰撞层，恢复时还原
		if p.is_noclip:
			p.collision_layer = 0
			p.collision_mask = 0
		else:
			p.collision_layer = 2
			p.collision_mask = 1
		var status: String = "开启" if p.is_noclip else "关闭"
		return _ok("穿墙模式已%s" % status)


# ===== /sanity [N] =====

class SanityCommand extends ConsoleCommand:
	func _init() -> void:
		name = "sanity"
		aliases = PackedStringArray(["san"])
		signature = "/sanity [N]"
		description = "设置理智为 N，无参数则恢复满理智。"

	func execute(args: PackedStringArray) -> Dictionary:
		if not GameManager or not RunManager:
			return _fail("RunManager 未就绪")
		if args.size() > 0:
			var n: float = float(args[0])
			RunManager.sanity = clamp(n, 0.0, float(RunManager.max_sanity))
		else:
			RunManager.sanity = float(RunManager.max_sanity)
		if RunManager.has_signal("sanity_changed"):
			RunManager.sanity_changed.emit(RunManager.sanity)
		return _ok("理智值：%.0f / %.0f" % [float(RunManager.sanity), float(RunManager.max_sanity)])


# ===== /floor [N] =====

class FloorCommand extends ConsoleCommand:
	func _init() -> void:
		name = "floor"
		signature = "/floor [N]"
		description = "跳到第 N 层并重新生成（无参数则下一层）。"

	func execute(args: PackedStringArray) -> Dictionary:
		if not RunManager:
			return _fail("RunManager 未就绪")
		var target: int = RunManager.current_floor + 1
		if args.size() > 0:
			target = int(args[0])
			if target < 1:
				return _fail("楼层必须 >= 1")
		RunManager.current_floor = target
		if RunManager.has_signal("floor_changed"):
			RunManager.floor_changed.emit(target)
		# 触发楼层重新生成
		var level_gen := _find_level_generator()
		if level_gen and level_gen.has_method("generate_floor"):
			level_gen.generate_floor()
			return _ok("已跳转到第 %d 层" % target)
		return _ok("楼层计数已设为 %d（需手动 /restart 重新生成）" % target)


# ===== /currency [N] =====

class CurrencyCommand extends ConsoleCommand:
	func _init() -> void:
		name = "currency"
		aliases = PackedStringArray(["gold"])
		signature = "/currency [N]"
		description = "增加 N 点局外货币（默认 100）。"

	func execute(args: PackedStringArray) -> Dictionary:
		if not MetaProgression:
			return _fail("MetaProgression 未就绪")
		var n: int = 100
		if args.size() > 0:
			n = int(args[0])
		MetaProgression.currency += n
		if MetaProgression.has_method("save_progression"):
			MetaProgression.save_progression()
		return _ok("增加 %d 点货币（当前 %d）" % [n, int(MetaProgression.currency)])


# ===== /restart =====

class RestartCommand extends ConsoleCommand:
	func _init() -> void:
		name = "restart"
		aliases = PackedStringArray(["r"])
		signature = "/restart"
		description = "重新生成当前楼层。"

	func execute(_args: PackedStringArray) -> Dictionary:
		var tree := _scene_tree()
		if tree == null:
			return _fail("场景树未就绪")
		var level_gen := _find_level_generator()
		if level_gen == null:
			return _fail("当前不在关卡中（找不到 LevelGenerator）")
		if not level_gen.has_method("generate_floor"):
			return _fail("LevelGenerator 不支持 generate_floor()")
		level_gen.generate_floor()
		return _ok("已重新生成当前楼层")
