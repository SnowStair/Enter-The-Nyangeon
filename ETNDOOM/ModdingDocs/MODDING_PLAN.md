# Modding Plan / 原生模组能力边界

> Scope / 范围：本体工程、发布包和原生加载器保持不变，只通过现有加载器安装模组。
> Evidence / 证据：本地代码与 Godot 官方资料；以下可行性判断不是完整重制模组的运行测试结果。
> Date / 日期：2026-10-14

## 1. Fingerprint / 项目与入口

- 本地工程：`E:\ETN_DOOM`；本体版本 `v0.5.1.3`（`script/Game.gd:10`），项目声明 Godot `4.7` / Forward Plus（`project.godot:20`），现有玩法为 2D。
- 原生加载器：`ModManager`；`user://mods/<id>/mod.json` + `<id>.pck`，桌面发布版另扫描 exe 同目录 `mods/`（`script/mod_manager.gd:187`）。不引入外部注入器、修改器或另一种加载器。
- 挂载入口：`ModManager._ready()` → `_mount_enabled()` → `_mount_one()` → `ProjectSettings.load_resource_pack(pck_path, replace_files)`（`script/mod_manager.gd:83,504`）。
- 脚本入口：`_run_entry_scripts.call_deferred()` → `load(entry).new()` → `add_child(node)`；entry 为普通 Node，随 `ModManager` 跨主场景存活（`script/mod_manager.gd:942`）。
- 存档与配置：`user://PlayerData.res`、`user://config.ini`（`script/Game.gd:5`）；加载器状态另存 `user://mods/`。完整重制可以自己用另一套文件格式和路径，须避免与本体常驻逻辑冲突。

## 2. Modification Levels / 分层能力

| 层级 | 可修改内容 | 当前机制与边界 |
|---|---|---|
| 内容扩充 | 角色、道具、敌人、支援、服装、关卡、模式、语言 | `defs/` + `ModAPI`，遵守本体资源类型与实际消费方契约 |
| 规则改造 | 伤害、死亡、刷怪、回合推进、转场、菜单、联机 | entry + `GameEvents` + `ExtensionHooks`；接管点返回 true 时本体跳过对应分支 |
| 场景与表现替换 | UI、地图、场景脚本、材质、贴图、音频 | 自带场景或 `replace_files=true` 覆盖路径；覆盖须考虑缓存、导出格式与依赖 |
| 完整玩法重制 | 自带主流程、玩家/敌人、规则、输入、UI、存档 | entry 延迟切到自带场景，独立实现玩法；隔离本体常驻单例副作用 |
| 引擎与平台启动 | 改 Godot 二进制、启动初始化、平台权限 | 不属于现有普通脚本/资源模组可直接替换的范围 |

**结论**：上限接近“在现有 Godot 运行环境内运行另一套游戏”，可达到玩法层面的完整重制。它不提供通用方法补丁系统，也不意味着能逐项无条件替换所有已初始化对象。

- `ModAPI` 是稳定接口，不是权限沙箱。前缀、资源类型、`overrides` 检查针对注册内容；entry 能直接调用场景树与单例，现有联机入口也直接向 `get_tree().root` 添加常驻节点（`coop_entry.gd:43`）。
- 独立玩法不必继承原版 `Player`、伤害、波次、对象池，也不必把主场景放进原版 `defs/levels/`；可直接加载自带 `PackedScene`。
- 复用原版时，信号通知只表示“事件发生”，不自动取消原逻辑；gate/interceptor 才是现有分支接管接口（`script/extension_hooks.gd:118`）。
- JSON 补丁只查 `_registry`。`_build_reserved_ids()` 初始化空注册表并保留本体角色/社团 id，并非将全部本体资源注册；缺失目标会跳过（`script/mod_manager.gd:103`、`script/mod_patch.gd:29`）。同名 `overrides` 也不改写所有直接 `load()` 或场景内的资源引用。
- 现有 coop 模组是跨系统改造的代码实例：入口创建联网与 UI 节点、安装 hook，manifest 当前还通过 PCK 覆盖两个脚本（`mod_sdk/coop_mod/mods/etn_coop/mod.json:10`）。不能将它描述为只用声明式内容 API。

## 3. Startup and Cache / 启动时序与缓存

- Godot 启动先遍历 autoload，加载资源并实例化 Node 放入 `to_add`，再在另一个循环中将它们加入根节点。后一个阶段才触发本项目 `ModManager._ready()` 的挂载。因此，**单纯前移 autoload 顺序不足以覆盖其他单例的脚本加载**。该结论来自官方引擎源码；本轮未对本地发布二进制做启动探针。
- 官方引擎源码：[Godot `main/main.cpp`](https://github.com/godotengine/godot/blob/master/main/main.cpp)，本轮读取的 `4542-4590` 行依次包含 `List<Node *> to_add`、`to_add.push_back(n)`、后续 `sml->get_root()->add_child(E)`；与本项目 `_ready()` 挂载位置联合核对。链接为可变分支，后续引擎升级须重新核对。
- `replace_files` 替换的是资源包路径解析。它不改磁盘上的本体包，也不自动替换既有 Node、脚本对象、常量里的 preload 引用或其他持有的 Resource。常规加载命中缓存时仍可能得到旧对象；高级缓存模式或手工重建另需处理引用与生命周期，不能当成全局热补丁。
- 官方说明：[导出 PCK 与模组](https://docs.godotengine.org/en/stable/tutorials/export/exporting_pcks.html)、[ResourceLoader 缓存模式](https://docs.godotengine.org/en/stable/classes/class_resourceloader.html)。已读取的 PCK 说明明确建议在 autoload 的 `_init()` 挂载，而不是 `_enter_tree()` / `_ready()`，以避免晚于 preload；缓存模式链接供后续查阅。
- 导出本体的脚本可能为 `.gdc` + `.gd.remap`；覆盖只放同名裸 `.gd` 会被原 remap 导向旧 `.gdc`。按 SDK 用 `ModPackReplace` 导出同格式；依赖也会一并进入包（`mod_sdk/ModPackReplace.preset.cfg:23`、`mod_sdk/coop_mod/README.md`）。
- `replace_paths` 仅指导构建，不是运行期白名单；运行期直接把 manifest 的 `replace_files` 传给引擎（`script/mod_manager.gd:515`）。

## 4. Conversion Route / 完整重制的可行路线

1. 在模组包自己的 `res://mods/<id>/` 下提供 entry、主场景与全部游戏逻辑。
2. entry 在当前启动流程稳定后延迟切到自带主场景；entry 不在当前主场景之下，切场景后仍存活。无需改本体的 `run/main_scene`。
3. 根据实际冲突处理本体单例的输入、处理回调、信号订阅、UI 和全局设置；不用的原版战斗场景不实例化。
4. 使用自带规则与数据，按需要选择复用原版声音/资源/单例；每增加一处复用，都核对对应契约。
5. 最终在原样发布的本体 + 模组包上验证启动、切场景、退出、禁用模组和存档隔离。

TODO: 待确认：完整重制的实际演示、具体发布二进制保留的引擎模块、目标平台上的输入/渲染/权限限制。本轮不构建模组、不安装、不改本体、不验证这些运行效果。
