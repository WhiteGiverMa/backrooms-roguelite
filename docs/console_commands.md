# 开发者控制台命令文档

控制台是 backrooms-roguelite 的开发者工具，用于调试和快速测试游戏状态。

## 呼出方式

1. 在主菜单 → **设置** → 勾选 **开发者模式**
2. 进入游戏后按 **反引号键 `` ` ``**（位于 Esc 下方）呼出/隐藏控制台
3. 输入 `/help` 查看所有命令

> **注意**：开发者模式未开启时，反引号键无响应。开发者模式状态持久化到 `user://settings.json`。关闭开发者模式时会联动关闭「移除战争迷雾」选项。

## 通用操作

| 按键 | 功能 |
|------|------|
| `` ` `` | 呼出/隐藏控制台 |
| `Tab` | 接受当前选中的补全候选 |
| `↑` / `↓` | 切换补全候选 / 浏览历史输入 |
| `Enter` | 执行当前输入 |
| `Esc` | 隐藏控制台 |
| 鼠标点击面板外 | 取消输入框焦点 |

输入以 `/` 开头则执行命令；输入命令名前缀（不带 `/`）也可匹配命令。补全提示在输入栏下方实时显示。

## 命令一览

| 命令 | 别名 | 签名 | 说明 |
|------|------|------|------|
| `/help` | `?` | `/help` | 显示所有可用命令 |
| `/clear` | `cls` | `/clear` | 清空控制台输出 |
| `/god` | — | `/god` | 切换上帝模式（玩家无敌，免疫所有伤害） |
| `/fog` | — | `/fog` | 切换战争迷雾开启状态 |
| `/heal` | `h` | `/heal [N]` | 恢复 N 点生命值，无参数则恢复满血 |
| `/damage` | `dmg` | `/damage [N]` | 对自己造成 N 点伤害（默认 10），用于测试受伤/死亡 |
| `/ammo` | — | `/ammo` | 当前武器弹药填满 |
| `/kill_all` | `killall` | `/kill_all` | 清空当前楼层所有敌人 |
| `/noclip` | `nc` | `/noclip` | 切换穿墙模式（无视碰撞） |
| `/sanity` | `san` | `/sanity [N]` | 设置理智为 N，无参数则恢复满理智 |
| `/floor` | — | `/floor [N]` | 跳到第 N 层并重新生成（无参数则下一层） |
| `/currency` | `gold` | `/currency [N]` | 增加 N 点局外货币（默认 100） |
| `/restart` | `r` | `/restart` | 重新生成当前楼层 |

## 命令详解

### `/help` — 显示帮助

```
/help
```

列出所有已注册命令的签名、描述和别名，按命令名字母排序。

### `/clear` — 清空输出

```
/clear
```

清空控制台输出区域的所有文本。历史输入不受影响。

### `/god` — 切换上帝模式 ★

```
/god
```

切换玩家的无敌状态。开启后玩家免疫所有伤害（`take_damage()` 直接返回），再次输入则关闭。

**实现**：切换 `Player.is_invincible` 字段。

### `/fog` — 切换战争迷雾 ★

```
/fog
```

切换战争迷雾的可见性。开启时屏幕被圆形视野遮罩覆盖（玩家周围可见，远处黑暗）；关闭时全图可见。

**实现**：切换 `FogOfWar` CanvasLayer 的 `visible` 属性。

**与设置界面的关系**：设置中的「移除战争迷雾」控制进入关卡时的初始状态；`/fog` 命令在游戏中可随时重新打开或关闭，两者互不冲突。

### `/heal [N]` — 恢复生命

```
/heal        # 恢复满血
/heal 50     # 恢复 50 点生命
```

无参数时直接将生命值设为最大值；有参数时调用 `Player.heal(N)`（受最大值上限约束）。

### `/damage [N]` — 对自己造成伤害

```
/damage      # 造成 10 点伤害
/damage 20   # 造成 20 点伤害
```

调用 `Player.take_damage(N)`，用于测试受伤动画、死亡流程。上帝模式开启时此命令无效（伤害被免疫）。

### `/ammo` — 弹药填满

```
/ammo
```

将当前武器的弹药设为最大值，并通知 HUD 更新。

### `/kill_all` — 清除所有敌人

```
/kill_all
```

对当前场景中所有属于 `enemy` 组的敌人调用 `die()`，清空当前楼层。击杀计入 RunManager 的 `enemies_killed` 统计。

### `/noclip` — 切换穿墙

```
/noclip
```

切换穿墙模式。开启时玩家的 `collision_layer` 和 `collision_mask` 设为 0，可穿过所有墙体；关闭时恢复默认值（layer=2, mask=1）。

**实现**：切换 `Player.is_noclip` 字段并动态修改碰撞层。

### `/sanity [N]` — 设置理智

```
/sanity       # 恢复满理智
/sanity 50    # 设为 50
```

无参数时设为 `max_sanity`；有参数时设为指定值（受 0~max_sanity 约束）。注意：理智设为 0 不会触发游戏结束（`modify_sanity` 才会检查），此命令直接赋值。

### `/floor [N]` — 跳转楼层

```
/floor        # 下一层
/floor 5      # 跳到第 5 层
```

设置 `RunManager.current_floor` 并调用 `LevelGenerator.generate_floor()` 重新生成楼层。楼层必须 >= 1。

### `/currency [N]` — 增加货币

```
/currency       # 增加 100 点
/currency 500   # 增加 500 点
```

增加局外货币（`MetaProgression.currency`）并保存到存档。用于快速解锁升级。

### `/restart` — 重新生成楼层

```
/restart
```

调用 `LevelGenerator.generate_floor()` 重新生成当前楼层。与 `/floor` 的区别：不改变楼层编号，只重新生成布局。

## AI 远程调用

控制台支持通过 godot-mcp 远程调用（TCP 交互服务器）：

```
game_call_method(nodePath="/root/Console", method="dev_command", args=["/god"])
```

参数为单字符串格式：`"/命令 参数"`（如 `"/heal 50"`，不是 `["/heal", "50"]`）。

## 架构说明

控制台系统由 4 个文件组成：

| 文件 | 职责 |
|------|------|
| `scripts/ui/console_command.gd` | `ConsoleCommand` 基类（RefCounted），定义 name/aliases/signature/description/execute 接口，含场景查找 helper |
| `scripts/ui/console_engine.gd` | `ConsoleEngine`（RefCounted），纯逻辑：命令注册、解析、补全路由、历史持久化 |
| `scripts/ui/console_commands.gd` | `ConsoleCommands`，13 个命令的具体实现（内部类聚合） |
| `scripts/ui/console.gd` | `Console` autoload（CanvasLayer layer=128），UI 渲染、输入处理、命令分发 |

设计参考 odyssey-cards 的 ChatScreen（C#），适配为 GDScript。引擎层（ConsoleEngine）与 UI 层（Console）分离，便于未来扩展或测试。
