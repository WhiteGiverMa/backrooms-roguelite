# UI 脚本指南

## 概览

11 个 .gd 文件，涵盖 5 个子系统：控制台、背包+热键栏、HUD、菜单/结算/升级、设置。

## 结构

```
scripts/ui/
├── console.gd               # Console autoload — CanvasLayer UI + 输入 + 命令分发
├── console_engine.gd         # 命令引擎（RefCounted 纯逻辑）
├── console_command.gd        # ConsoleCommand 基类
├── console_commands.gd       # 13 条命令实现（help/clear/god/fog/heal/damage/ammo/...）
├── inventory.gd              # Minecraft 风格背包：9×3 网格 + tooltip + 详情窗
├── hotbar.gd                 # 4 格热键栏 — 程序化像素图标
├── hud.gd                    # HUD：血量/理智/体力/弹药/换弹条/武器名/楼层/小地图
├── main_menu.gd              # 主菜单
├── game_over.gd              # 结算界面
├── upgrades_screen.gd        # 局外升级界面
└── settings.gd               # 设置界面（音量/开发者模式等）
```

## 去哪里改

| 任务 | 文件 | 注意 |
|------|------|------|
| 背包 UI、格子、tooltip、详情窗 | `inventory.gd` | 768 行，所有 UI 程序化创建，不依赖 tscn |
| 热键栏图标、切换武器/手电 | `hotbar.gd` | 256 行，`_generate_icons()` 生成 32×32 像素图标 |
| HUD 血量/弹药/换弹条/楼层显示 | `hud.gd` | 弹药信号从 `RunManager.ammo_changed` 接收；`_on_weapon_changed` 绑定换弹条 |
| 添加控制台命令 | `console_commands.gd` | 每条命令是内部类，继承 `ConsoleCommand`；注册到 `console.gd:_register_all_commands()` |
| 控制台 UI 布局/样式 | `console.gd` | CanvasLayer layer=128，StyleBoxFlat 样式 |
| 控制台命令基类的工具方法 | `console_command.gd` | `_player()`、`_scene_tree()`、`_fog_layer()` 等 helper |
| 设置界面 | `settings.gd` | HSlider/CheckBox/Button，信号连接到 `Settings` autoload |
| 主菜单/结算/升级 | `main_menu.gd` / `game_over.gd` / `upgrades_screen.gd` | 简单 Control → Button 信号模式 |

## 约定

- 所有 UI 用中文文案，标识符用英文。
- UI 节点一律程序化创建（Button/Label/ProgressBar/StyleBoxFlat），不编辑 tscn 文件中的 Control 子节点结构。
- `hud.gd` 和 `inventory.gd` 在同一个 `game_level.tscn` 的 HUD CanvasLayer (layer=2) 下。
- `console.gd` 是 autoload，独立 CanvasLayer (layer=128)，无需挂场景树下。

## 信号流

| 信号 | 来源 | 消费 |
|------|------|------|
| `RunManager.ammo_changed` | weapon.gd（emit）| hud.gd（connect）|
| `player.weapon_changed` | player.gd（emit）| hud.gd（connect → 换弹条绑定）|
| `weapon.reload_started/progress` | weapon.gd（emit）| hud.gd（动态 connect/disconnect）|
| `player.health_changed` | player.gd（emit）| hud.gd（connect）|
| `RunManager.floor_changed` | run_manager.gd（emit）| hud.gd（connect）|

## 陷阱

- `hud.gd` 的 `_on_ammo_changed` 在 `_ready()` 中通过 `RunManager.ammo_changed` 连接——**不要**回到 `player.ammo_changed`（声明了但从未 emit）。
- 背包 UI 的 tooltip 和详情窗使用 `global_position`（因父 Container 锚点非 (0,0)，`position` 是本地坐标）。
- `inventory.gd` 中 `StyleBoxFlat.content_margin` 替代 `MarginContainer`（因 `fit_content` 在事件处理器中异步不可靠）。
- hotbar.gd 的按钮显示用 `btn.icon` (Texture2D) + `btn.tooltip_text`，不用 `btn.text`。
