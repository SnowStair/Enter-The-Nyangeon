# ETNDOOM Mod / 开发入口

> Fork Workspace / 当前工作区（2026-11-23）：`E:\Enter-The-Nyangeon-ETNDoom`，分支 `Rev`。M1 已在 fork 当前本体通过迁移兼容检查；新依赖、真实宿主来源与覆盖边界见 [迁移记录](../ETNDOOM/MIGRATION.md)。五组人工入口已生成于 `tests/m1_manual/启动M1人工验证.cmd`，仍待用户验收。下方 Stage0 与旧验收中的旧路径仅是历史证据。

## M1 / 当前开发入口（2026-11-22）

M1 使用独立 Mod ID `etndoom_m1`、ABI 2，接通新游戏/当前图重开/死亡重生、流程确认、暂停、8 个事务存档槽、完整地图/实体/资源观察和 SDL_mixer/OPL 音频。当前构建命令为：

```powershell
py -3 etndoom_mod/build_native.py --all
py -3 etndoom_mod/build_m1.py
py -3 tests/run_m1_checks.py
py -3 tests/run_m1_manual.py --resource doom
py -3 tests/run_m1_manual.py --resource dss --episode 2
```

输出 `build/m1/etndoom_m1.zip`，不含 WAD。纯 Doom 与 Doom+DSS 分别使用获准资源；DSS 只读内嵌 DEHACKED。`--resource fixture --jump` 和 `--resource doom2` 继续提供自制跳跃/原版 Doom II 的人工入口。启动器生成独立用户目录及可重复打开的 `启动人工验证.ps1`；完整操作见 [M1 人工验证](../ETNDOOM/ModdingDocs/M1/M1_MANUAL_VALIDATION.md)，数据消费者见 [M1 实际格式](../ETNDOOM/ModdingDocs/M1/M1_DATA_SCHEMA.md)。

**阶段1（M1）实现完成，但验收未完成**（2026-11-22，用户确认）。自动回归已通过，人工验收尚待用户执行；自动证据与覆盖范围集中在 [M1 验收](../ETNDOOM/ModdingDocs/M1/M1_VALIDATION.md)。M0 源码入口、历史产物和记录保留在下文；当前默认原生构建已升级 ABI 2，不能与 M0 ABI 1 桥接混用。

## M0 / 已验收历史基线

当前 M0 使用新 Mod ID `etndoom_m0`，Crispy Doom 7.2-1 固定内核，真实 ETN 发布版安装/运行及自动回归已通过。**M0 已完成，人工验收于 2026-11-18 由用户确认通过**；G1 组合发布授权仍待裁定。完整记录见 [M0 总览](../ETNDOOM/ModdingDocs/M0/README.md)，启动器和检查单见 [人工验证](../ETNDOOM/ModdingDocs/M0/M0_MANUAL_VALIDATION.md)。

```powershell
# 历史 M0 需要 ABI 1 内核产物；当前 build_native.py 构建 ABI 2，不能混用。
py -3 tests/run_m0_manual.py --resource fixture --jump
py -3 tests/run_m0_manual.py --resource doom2
```

构建依赖/固定哈希见 `vendor/dependencies.json` 和M0选型§9。默认输出 `build/m0/etndoom_m0.zip`，不包含WAD或本体资源；当前源码读取已获准的 `E:/Enter-The-Nyangeon-ETNDoom/etndoom_mod/wad/DOOM2.WAD`，fixture另叠加同目录 `MAP01.wad`。当前为原版软件画面，音频未接入，最终俯视属M2；完整战斗/机关/流程/存档验收属M1。自动入口为本地 `tests/run_m0_checks.py`、`tests/run_m0_negative_checks.py`，最终交付证据为 `tests/m0_results/final_delivery_20261117/delivery.json`。

## Repository / 源码与本地产物

`build_native.py`、`build_m0.py`、`entry/m0_entry.gd`、`m0/`、`native/` 手写源码、`gdextension/` 桥接与接口头、`vendor/` 固定源码包/依赖清单/许可证均入库。`vendor/crispy-doom-35b49519.tar.gz` 是独立构建输入，不能作为普通下载缓存清理。

`build/`、`native/{build,reference_build,core_source,reference_source,dependencies,downloads}/`、`gdextension/build/` 与 API 导出、编译器生成物和 Python 缓存由 `.gitignore` 排除。`tests/` 的 ETNDOOM 新增脚本/证据/人工入口、`release/`、`.migration/`、外部 IWAD/DSS 按仓库约定仅本地保存；fork 已跟踪的上游测试继续保留；正式源码、知识库与自制地图不作宽泛忽略。

2026-11-18 用户确认：`ETNDOOM/.obsidian/` 整个文件夹仅本地保留，已跟踪的配置和主题移出 Git 索引；10 张已在工作区删除的历史 WAD 纳入本次 M0 提交。现存 `MAP01.wad` 与商业 IWAD 的边界保持上文约定。

## Stage0 / 历史独立入口

以下为既有 Stage0 历史说明，运行源码独立保留。2026-11-18 用户确认将 10 张历史 WAD 的既有删除纳入提交；其中包含旧五图构建/回归依赖的部分夹具，因此下方旧命令依赖已缺失的地图，不能视为当前可直接执行的完整 Stage0 回归入口。M0 只使用获准的 `MAP01.wad` 与本地 `DOOM2.WAD`，其验收不受影响；未以 M0 结果替代 Stage0 回归。

开发源：`E:\ETN_DOOM\etndoom_mod\`；Mod ID：`etndoom_stage0`；版本：`0.3.0`。这是一次性开发测试入口。

## Build / 构建

```powershell
python E:\ETN_DOOM\etndoom_mod\build_stage0.py --godot "D:\Creating\Godot\Godot_v4.7.2-stable_win64_console.exe"
```

输出 `build/etndoom_stage0.zip` 与 `.pck`。ZIP 内仅有 `mod.json` 和 PCK；PCK 内是 `res://mods/etndoom_stage0/` 下的 entry、场景、脚本和五张固定 `MAP01*.wad`（含 `MAP01_HTest.wad`）。构建采用明确白名单，**不包含 DOOM2.WAD**、测试脚本或本体资源。

运行时读取本机外部依赖 `E:/ETN_DOOM/etndoom_mod/wad/DOOM2.WAD`。该路径按 D01/D02/D10 固定；缺失或素材格式不支持时输出具体错误。

## Run / 人工启动

当前阶段 0.3 的隔离人工入口：

```powershell
py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3
py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3 --map MAP01_BackWall.wad
py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3 --map MAP01_FrontWall.wad
py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3 --map MAP01_Texture.wad --overview
py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3 --map MAP01_HTest.wad
```

0.3 使用 `--stage0=0.3 --stage0-collision=on`，固定 Momoi、逻辑 `32×32mu` 矩形碰撞、`525mu/s` 速度与 `1720mu/s²` 向量加速度。WASD/原移动动作按屏幕方向逆投影；不启动原玩法。正交相机固定 `yaw=45°`、`pitch=45°`；`F2` 切换跟随/整图，`+` / `-` 每次调整 `10mu`，跟随范围 `640..1600mu`、默认 `960mu`。五张夹具的整图 `size=1400mu`。可用 `--size 640` 指定启动取景。设计画面为 1600×900；场外滚动背景及 glow 启用，角色与墙面自然深度遮挡，无阴影。

Momoi 的 **主体可见高度为 56mu，不含光环**；光环随主体等比缩放。`MAP01_HTest.wad` 的北侧区域 floor=50mu，出生后沿屏幕右上方向穿入（可用 W+D）；玩家脚底仍在 h=0，高台应挡住主体下部并露出头部像素，只有光环可见不算高度通过。2026-10-30 用户已确认高度正常；竖直 billboard 在当前 45° 俯视下会自然产生 cos45 的纵向缩短，原素材逐帧对照已通过，按用户意见保留该效果。Gate D 已完成。

导出版安装新 ZIP 并重启后，可直接使用：

```powershell
& "E:\ETN_DOOM\release\pak\Enter The Nyangeon v0.5.2.0-test.exe" -- --stage0=0.3 --stage0-collision=on
```

附加开发参数为 `--stage0-map=MAP01_FrontWall.wad`、`--stage0-size=960`、`--stage0-view=overview`，只允许与 0.3 一起使用。无效/重复/缺值参数不切换测试场景。`off` 可解析，但不属于当前验收范围。人工验收覆盖视角、墙面、角色裁切边缘/孔洞、遮挡与手感；2026-10-30 的用户确认与专项证据已满足 Gate D，见实施记录 §6.6。

以下保留 0.1/0.2 历史入口，本轮不重跑：

在游戏设置的 MOD 页导入 `build/etndoom_stage0.zip`，确认启用并退出，再启动：

```powershell
& "E:\ETN_DOOM\release\pak\Enter The Nyangeon v0.5.2.0-test.exe" -- --stage0=0.1
& "E:\ETN_DOOM\release\pak\Enter The Nyangeon v0.5.2.0-test.exe" -- --stage0=0.2
```

以上导出版命令供用户安装后验收；本次完整自动回归使用源码工程。更新包后也须重启。无参数继续正常游戏；无效、空值、缺值、重复参数会报告参数错误并继续正常游戏。

也可运行以下隔离人工入口：它会构建、验证 `user://` 隔离、调用真实 ZIP 安装、检查重启票据，再不带回归驱动地启动正常主场景。关闭窗口结束。

```powershell
python E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.1
python E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.2
```

移动沿用本体 `move_left/right/up/down`。0.1 可穿过逻辑边界并停留在外；0.2 受真实静态墙阻挡，可沿边滑动并离墙。无武器、攻击、技能、跳跃、HUD 或原版回合流程。相机居中跟随，场外滚动背景和 glow 启用。

## Regression / 自动回归

需要 Python 的 `numpy`、`Pillow`，以及用于独立 WAD 参考图的 `omgifol==0.5.1`。本地参考工具可安装在测试目录：

```powershell
python -m pip install numpy Pillow
python -m pip install omgifol==0.5.1 --target E:\ETN_DOOM\tests\.stage0_deps
python E:\ETN_DOOM\tests\run_stage03_checks.py
```

Godot 默认使用上述本机路径，可通过 `--godot` 覆盖。0.3 结果位于 `tests/stage0_results/<时间>/stage03/on/`，包含真实安装/重启、五图字段、完整截图、独立素材与射线像素参照、运动轨迹及反例。测试脚本、参考图、截图及隔离工程仅在本地使用。测试监督器共用隔离工程缓存，须串行启动，避免 Windows 的 Rapier DLL 占用。旧 `run_stage0_checks.py` 保留用于历史基线。完整说明见 [`STAGE_0_IMPLEMENTATION.md`](../ETNDOOM/Legacy/Stage0/STAGE_0_IMPLEMENTATION.md)；人工验收仍按开发细化文档执行。
