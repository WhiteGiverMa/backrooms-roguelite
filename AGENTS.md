# Backrooms Roguelite 项目知识库

**生成时间：** 2026-06-26  
**分支：** `master`  
**项目性质：** Godot 4.7 草稿项目，纯 GDScript，横版后室探索射击 Roguelite。

## 概览

入口是 `scenes/ui/main_menu.tscn`。核心游戏流由 7 个 autoload 驱动：`GameManager` 管场景和状态，`RunManager` 管单局数据，`MetaProgression` 管局外成长，`AudioManager` 管音频，`Settings` 管持久化设置，`McpInteractionServer` 管 Godot MCP 远程交互，`Console` 管开发者控制台。

这是早期草稿，不要过度设计层级文档；根级说明足够。

## 结构

```text
.
├── project.godot          # 主场景、autoload、输入映射、渲染/物理设置
├── scenes/ui/             # main_menu、upgrades_screen、game_over、settings
├── scenes/levels/         # game_level 根场景、room_template 房间模板
├── scenes/pickups/        # 拾取物场景（健康/弹药/理智/武器/货币 共8个）
├── scripts/systems/       # GameManager、RunManager、MetaProgression、AudioManager、Pickup、Settings
├── scripts/levels/        # LevelGenerator、Room、EnemySpawner、ItemSpawner、FogOfWar
├── scripts/player/        # Player
├── scripts/enemies/       # Enemy
├── scripts/weapons/       # Weapon、Bullet
├── scripts/ui/            # UI 控制脚本（见 scripts/ui/AGENTS.md）
└── assets/sprites/        # 当前只有 player.png，且运行时玩家图不是从它加载
```

## 去哪里改

| 任务 | 位置 | 注意 |
| --- | --- | --- |
| 场景流、暂停、游戏结束 | `scripts/systems/game_manager.gd` | `start_run()` 切到 `game_level.tscn`，`game_over()` 延迟后切结算 |
| 单局数值：楼层/理智/击杀 | `scripts/systems/run_manager.gd` | 理智归零会触发游戏结束 |
| 局外升级和存档 | `scripts/systems/meta_progression.gd` | 存到 `user://meta_progression.save`，当前是明文 JSON |
| 玩家移动、冲刺、受伤 | `scripts/player/player.gd` | 文件偏大，程序化精灵占很多行 |
| 武器系统：手枪/匕首/定身枪 | `scripts/weapons/weapon.gd` | `RANGED`/`MELEE` 枚举；`attack()` 统一入口 |
| 子弹与状态效果 | `scripts/weapons/bullet.gd` | `status_effect`/`effect_duration` — 命中时调 `apply_status` |
| 弹药储备系统 | `scripts/player/player.gd` (ammo_reserves) | 武器装填从 `player.ammo_reserves` 消耗；拾取增加储备 |
| 背包 UI（Minecraft 风格） | `scripts/ui/inventory.gd` | 9×3网格+hotbar行+tooltip+详情窗；按B打开 |
| 热键栏 UI | `scripts/ui/hotbar.gd` | 4格，程序化像素图标（非文字） |
| HUD：血量/理智/体力/弹药/换弹条 | `scripts/ui/hud.gd` | 弹药信号从 `RunManager.ammo_changed` 接收 |
| 换弹进度条 | `scripts/ui/hud.gd` | 黄色 ProgressBar 绑定 `weapon.reload_progress` |
| 敌人 AI | `scripts/enemies/enemy.gd` | 状态是字符串；支持 `stun` 状态效果 |
| 房间与门 | `scripts/levels/room.gd` | 根据连接动态生成墙体碰撞和门洞 |
| 关卡生成 | `scripts/levels/level_generator.gd` | `_ready()` 中直接 `generate_floor()` |
| 拾取物系统 | `scripts/systems/pickup.gd` | 6种类型：HEALTH/AMMO/SANITY/WEAPON/KEY/CURRENCY |
| 物品生成器 | `scripts/levels/item_spawner.gd` | `health_pickup`/`ammo_pickups`/`weapon_pickups` 数组 |
| 控制台命令 | `scripts/ui/console_commands.gd` | `/give_weapon`/`/give_ammo`/`/weapons`/`/inv`/`/ammo` 等 |

## 代码地图

| 符号 | 类型 | 位置 | 角色 |
| --- | --- | --- | --- |
| `GameManager` | Autoload | `scripts/systems/game_manager.gd` | 全局状态机、场景切换 |
| `RunManager` | Autoload | `scripts/systems/run_manager.gd` | 当前 run 数据、理智、楼层 |
| `MetaProgression` | Autoload | `scripts/systems/meta_progression.gd` | 货币、升级、存档 |
| `AudioManager` | Autoload | `scripts/systems/audio_manager.gd` | SFX 池和音乐播放器 |
| `LevelGenerator` | `Node2D` | `scripts/levels/level_generator.gd` | 生成房间布局并放置实体 |
| `Room` | `Node2D` | `scripts/levels/room.gd` | 房间连接、门洞、碰撞墙 |
| `Player` | `CharacterBody2D` | `scripts/player/player.gd` | 移动、冲刺、武器、死亡 |
| `Enemy` | `CharacterBody2D` | `scripts/enemies/enemy.gd` | 巡逻/追击/攻击、受击死亡 |
| `Weapon` | `Node2D` | `scripts/weapons/weapon.gd` | 弹药、射击、装填；RANGED/MELEE 枚举 |
| `Bullet` | `Area2D` | `scripts/weapons/bullet.gd` | 直线飞行、命中敌人或墙体 |
| `Pickup` | `Area2D` | `scripts/systems/pickup.gd` | 治疗、弹药、理智、武器、货币拾取 |
| `ItemSpawner` | `Node` | `scripts/levels/item_spawner.gd` | 按概率生成拾取物 |
| `ConsoleEngine` | `RefCounted` | `scripts/ui/console_engine.gd` | 控制台命令注册和调度 |

## 项目约定

- 文件名用 `snake_case`，`class_name`/autoload 用 `PascalCase`。
- 目录按领域分：`scripts/systems`、`scripts/levels`、`scripts/ui` 等；不要为了小改新增抽象目录。
- UI 文案当前是中文；代码标识符保持英文。
- Godot `.import` 元数据如果对应源资源已跟踪，可以保留；不要手动编辑 `.import`。
- `.godot/`、`.codegraph/`、`.omo/` 是本地/工具产物，不应进入新提交。
- `generate_player.py` 是旧工具，不是游戏运行依赖；里面有历史绝对路径，运行前必须先修正。

## 项目特有注意点

- 多数精灵在运行时用 `Image.create()` 生成。改玩家/敌人外观会改 GDScript，而不只是换图片。
- `game_level.tscn` 的根节点就是 `LevelGenerator`，生成逻辑与场景生命周期耦合。
- `project.godot` 启用了 `physics/2d/run_on_separate_thread=true`。
- 项目有 `[dotnet]` 配置痕迹，但没有 C# 项目文件；除非明确启用 C#，不要继续扩展这条线。
- 当前没有测试、导出预设、CI。验证必须以 Godot 运行项目为准。

## 命令

```bash
# 运行项目
godot --path .

# 旧精灵工具；需要 Pillow，且脚本路径应先改成相对路径
python generate_player.py
```

## 手动 QA 面

每次改核心脚本后跑一遍：主菜单开始游戏 → 进入关卡 → WASD 移动 → Space 冲刺 → 鼠标射击 → R 换弹（进度条可见）→ 1-4 切武器/手电 → B 背包 → 被敌人接触受伤 → 死亡进入结算 → 重试/返回菜单。

没有自动化测试时，不要只靠脚本静态检查宣布完成。

当前MCP比较脆弱，若以上路径阻塞，则请求人类验证，或克隆[godot-mcp](https://github.com/WhiteGiverMa/godot-mcp)到本地进行修复和重部署。

## 反模式与陷阱（本项目特有）

### GDScript 类型推断

**`:=` 禁止用于 Variant 来源。** 项目 `project.godot` 将 `INFERRED_DECLARATION` 警告提升为错误。以下模式必然崩溃：

```gdscript
# ❌ 崩溃 — Dictionary.get() 返回 Variant
var val := dict.get("key", 0)
# ✅ 安全
var val: int = dict.get("key", 0)

# ❌ 崩溃 — get_first_node_in_group() 返回 Node，属性访问推断为 Variant
var p := get_tree().get_first_node_in_group("player")
var fl_on := p.flashlight_on
# ✅ 安全
var p = get_tree().get_first_node_in_group("player")
var fl_on: bool = p.flashlight_on

# ❌ 崩溃 — has_method() 后的鸭子调用推断为 Variant
var reserve := owner_player.get_ammo_reserve(ammo_type)
# ✅ 安全
var reserve: int = owner_player.get_ammo_reserve(ammo_type)
```

**规则**：构造函数（`XXX.new()`）、算术运算、纯类型返回值等可用 `:=`。涉及 `Dictionary`、`Node` 属性访问、`has_method` 鸭子调用时必须显式标注类型。

### Object == String 比较

```gdscript
# ❌ 运行时错误 — Weapon 实例 == "flashlight" 字符串
if hotbar[i] == "flashlight":
# ✅ 安全
if hotbar[i] is String and hotbar[i] == "flashlight":
```

### get_meta() 必须配 has_meta()

```gdscript
# ❌ 崩溃 — 空格子没有 "item" meta
var item = slot.get_meta("item", null)
# ✅ 安全
if not slot.has_meta("item"): return
var item = slot.get_meta("item")
```

### instantiate() 后必须 add_child()

```gdscript
# ❌ Weapon 不在场景树 — _ready/_process 永不执行
var pistol = pistol_scene.instantiate()
add_weapon(pistol)  # 只加入数组，没加入场景树
# ✅ Weapon.equip() 内部检测 is_inside_tree 并 add_child 到 WeaponPivot
```

### 信号初始化竞态

Player._ready() 先于 HUD._ready() 执行。`_give_starting_weapon()→equip_weapon()` 发射 `weapon_changed` 时 HUD 尚未连接该信号 → **首把武器的信号绑定丢失**。

修复：HUD._ready() 连接信号后，手动调 `_on_weapon_changed(player.current_weapon)` 主动绑定。调用顺序很关键——必须在 `reload_bar` 等依赖对象创建**之后**才调。

### Image.create 居中操作必须边界检查

```gdscript
# ❌ 大图居中到小图时 ox 为负，set_pixel 越界
var ox := (dst_w - src_w) / 2  # 可能为负
dst.set_pixel(ox + x, oy + y, c)
# ✅
var px: int = ox + x
if px >= 0 and px < dst_w and py >= 0 and py < dst_h:
    dst.set_pixel(px, py, c)
```

### Control 子节点的 position vs global_position

锚点非 (0,0) 的 Control 节点下，`position` 是相对父控件的本地坐标。与鼠标/屏幕交互必须用 `global_position`。

### MarginContainer + fit_content 在事件处理器中不可靠

`mouse_entered` / `mouse_exited` 回调中，RichTextLabel 的 `fit_content=true` 布局不会在同帧完成 → `get_minimum_size()` 返回 (0,0) → 面板塌陷为残影。

修复：不用 `get_minimum_size()`，直接设固定 `custom_minimum_size` + `size`。内边距用 `StyleBoxFlat.content_margin` 而非 `MarginContainer`。
