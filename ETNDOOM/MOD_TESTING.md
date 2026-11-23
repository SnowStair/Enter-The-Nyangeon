# Mod Testing / 模组测试

> Scope / 范围：保存 ETNDOOM 的模组装载、自动重启与无人值守回归设计。
> Maintenance / 维护：`docs/` 下的本地修改可能随远端更新被覆盖；ETNDOOM 相关测试设计统一写入本文件。
> Source / 来源：用户 2026-10-24 指定本地保存位置；装载流程依据 ETN 本体代码静态分析。
> Date / 日期：2026-10-24

## 1. 无人值守装载与重启回归设计

### 1.1 约束

- `ModManager` 只在 autoload `_ready()` 中扫描、排序和挂载；导入、启停、排序、卸载后不会在当前进程重新扫描。
- MOD 页的「立即重启」当前只执行 `get_tree().quit()`，不创建新进程；自动回归必须由游戏外的监督进程负责再次启动。
- 回归必须使用隔离 `user://`。复用 `tests/isolated_godot.py` 的做法：重定向 `APPDATA` / `LOCALAPPDATA` / `XDG_DATA_HOME`，并先运行探针确认 `OS.get_user_data_dir()` 位于临时目录内。
- 编辑器运行只扫描 `user://mods/`；项目根 `mods/` 是编辑器资源镜像，不是运行时安装目录。桌面导出版本才额外扫描 exe 同目录 `mods/`。

### 1.2 推荐的两阶段监督流程

1. **安装阶段**：监督进程启动 Godot `--headless --script <安装探针>`；探针等待 autoload 就绪后调用 `ModManager.import_zip(zip_path)`，校验返回 `ok=true`，写入带随机 nonce 的重启票据，然后以专用退出码（建议 `75`）退出。
2. **重启阶段**：监督进程确认「退出码 + 重启票据」均正确，使用**同一套环境变量和同一临时用户目录**重新启动 Godot；此时 `ModManager._ready()` 会扫描新目录并挂载 PCK。
3. **验证阶段**：验证探针检查 `ModManager.list_mods()` 中目标 mod 的 `enabled=true`、`mounted=true`、`error=""`，再检查代表性注册资源和 `ModEntry_<id>`。entry 是 deferred 创建，不能只等固定一帧；应在有超时的循环中等待目标节点或完成标记。
4. **行为阶段**：由 mod entry 或测试驱动读取 `OS.get_cmdline_user_args()`，自动进入测试房/目标场景并输出机器可读断言；结束时写 `user://regression/result.json` 并用 `SceneTree.quit(code)` 退出。
5. **生命周期阶段（可选）**：在进程停止后改写 `mods_state.json` 为 false/true，分别重启验证停用/恢复；再调用卸载阶段并重启，验证目录、状态和注册内容均消失。

### 1.3 快速模式与导出版模式

- **快速模式（不测 ZIP 安装事务）**：监督进程直接把 `mod.json`、PCK、可选 `icon.png` / `content_index.json` 复制到隔离 `user://mods/<id>/`，显式写入 `mods_state.json` 和 `mods_order.json`，然后启动一次验证。适合高频功能回归。
- **完整模式（测试安装 + 重启）**：走 1.2 的两阶段流程，覆盖 `ModInstaller` 事务、首次默认启用和下一进程挂载。适合提交前/发布前回归。
- **导出 exe 烟测**：外部监督进程预装隔离目录后启动真实 exe；测试 mod 的 entry 负责自动场景驱动和结果落盘。ZIP 安装事务继续由源码 headless 回归覆盖，避免给正式包加入常驻测试 autoload。

### 1.4 判定与故障隔离

- 日志至少记录：阶段、nonce、本体版本、mod id/version、安装目录、启用/挂载/error、解析后顺序、代表性内容数量、entry 就绪、场景断言、退出码。
- 仅看到进程退出不能视为成功；必须同时满足退出码、完成标记和结果 JSON。超时后只按监督进程记录的**精确 PID**终止。
- 新安装无 `mods_state.json` 条目时默认启用；为保证回归确定性，快速模式仍应显式写 true。重装一个历史上被禁用的同 id mod 不会自动改回启用，完整模式需在重启前明确设置预期状态。
- `import_zip()` 成功只表示文件已交换完成；当前进程的 `_mods` / 注册表不会新增刚安装的 mod，必须在下一进程验证。

## 2. Stage0 已实现的本地入口与结果

2026-10-24 已实现 `tests/run_stage0_checks.py` + `tests/stage0_checks.gd`，完整模式已通过：实际 ZIP 安装 → 退出码 75/随机票据 → 同环境重启 → PCK 挂载与 entry → 运行行为/碰撞 → 完整截图/像素 → 双份结果 JSON/退出码检查。没有使用玩家真实 user://，不依赖 godot_ai。

```powershell
& "C:\Users\雪楼梯_IceStair\AppData\Local\Programs\Python\Python313\python.exe" E:\ETN_DOOM\tests\run_stage0_checks.py
```

Godot 默认路径为 `D:/Creating/Godot/Godot_v4.7.2-stable_win64_console.exe`，可用 `--godot` 改写。运行前从 `etndoom_mod/` 源码用 SDK 打新 ZIP/PCK；DOOM2.WAD 不打包。Python 依赖为 numpy、Pillow，以及导出独立 WAD 素材参考的 `omgifol==0.5.1`（本地安装于 `tests/.stage0_deps/`）。

完整结果在 `tests/stage0_results/20261024_final/`：`summary.json` 的 `ok=true`、`complete_matrix=true`；8 个用例和 21,147 条运行断言通过；0.1 的 5 张与 0.2 的 9 张完整 1280×720 截图均通过像素断言。`references/` 记录成熟工具导出图与 WAD 哈希，`mode_consistency.json` 核对两模式素材和初始截图逐像素一致。`pixel_negative_control/pixels.json` 的失败为预期反例，证明空白图会被地图/角色断言拒绝。

源码 fixture 与导入缓存位于 `tests/.stage0_fixture/project/`，只在副本排除缺失的 `_mcp_game_helper`；原 `project.godot` 不改。每个用例目录保留参数、nonce、隔离环境路径、日志、运行结果、完整截图、截图观察条件和像素差异。失败分类包含未启动、资源/适配失败、玩法误启用、越界被干预、碰撞穿透、截图失败、像素失败。

隔离人工启动入口为 `python tests/run_stage0_manual.py --stage 0.1` / `--stage 0.2`。它同样安装并重启，运行正常主场景和 Mod entry，游戏进程不加载回归驱动；关闭窗口结束。两模式已追加 `--quit-after 120` 通过正常启动烟测，证据见 `manual_entry_smoke.json`；用户实际操作与导出 exe 验收仍待完成，不能据自动结果代签 Gate B/D。实现细节、实际构建命令与验收状态见 [`STAGE_0_IMPLEMENTATION.md`](STAGE_0_IMPLEMENTATION.md)。

Windows 上监督器优先使用 `_console.exe` 同目录的实际 `.exe`，直接捕获 stdout/stderr；console 转发程序会再创建子进程，单杀其 PID 会遗留实际游戏。人工入口的 `launch.json` 保留实际 PID/命令/user://。超时管理和退出只针对本次监督的实际 PID，不按名称批量结束其它进程。

## 3. Stage0.2 Edge Timing / 出生点到边缘计时

```powershell
& "C:\Users\雪楼梯_IceStair\AppData\Local\Programs\Python\Python313\python.exe" E:\ETN_DOOM\tests\run_stage0_measurement.py
```

该本地入口复用构建、隔离用户目录、真实 ZIP 安装及重启流程，通过实际 Mod entry 加载 Stage0.2。测量模式保留指定 Godot 二进制路径（默认 console），使用 headless 与固定 `60Hz` 物理运行，不依赖窗口键盘焦点；无需人工按住移动键。每次从出生点静止起步，分别沿东/西方向持续输入，直到 `move_and_slide()` 首次接触地图边界，保留完整物理帧序列。

结果保存在 `tests/stage0_results/<时间戳>/edge_measurement/edge_measurement.json`；监督器同时检查退出码、nonce、完成标记、隔离 `user://` 的结果副本和日志错误。2026-10-26 的最终证据在 `20261026_124953/`，49 条断言通过；两向均为 `201/60 = 3.350s`，计时比例区间约 `0.995036–1.000081`。接触位移另核验 `k≈0.999988`，支持 Stage0 当前的精确 `1:1` 映射。推导和 V03 适用边界见[实施记录](STAGE_0_IMPLEMENTATION.md)。本模式只运行边缘测算，`complete_matrix=false`，不冒充完整回归。

## 4. Stage0.3 / 侧方正交独立回归（2026-10-30）

```powershell
py -3 E:\ETN_DOOM\tests\run_stage03_checks.py
py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3
```

初始四图回归结果（高度修正前历史证据）位于 `tests/stage0_results/20261030_122100/stage03/on/`，实际命令/版本、相机参数、容差、失败历史与交接见[实施记录 §6](STAGE_0_IMPLEMENTATION.md#6-stage-03-implementation--阶段-03-实施2026-10-30)。只运行 0.3 collision=on；0.1/0.2 的历史证据不重跑，off 不列入验收。测试目录和依赖均不提交。

该轮 `ok=true`、`complete_matrix=true`，7 个实际入口用例、730 条运行断言、647,102 个像素采样通过，五组合成反例全部被拒绝。不带回归驱动的正常入口烟测另见 `tests/stage0_manual/0.3_25c9cbfa/smoke.json`，`ok=true`、`manual_acceptance=false`。

本地文件分工：`run_stage03_checks.py` 负责构建、user:// 探针、真实 ZIP 安装/75 票据/重启、运行与汇总；`stage03_checks.gd` 从实际 entry 后的场景驱动输入、记录物理/相机/截图；`stage03_reference.py` 从原 WAD、原 PNG 和 omgifol 参考计算期望。四图每图 15 张完整 1600×900 截图，共 60 张；检查原始素材全像素、WAD 字段、独立投影锚点、运动轨迹、墙段 UV/pegging、mipmap、自然深度遮挡及透明孔洞。相机/视口变化的逻辑测试不替代固定分辨率截图。

每张图保存源 `.readback`、线性 PNG、sRGB PNG、观察 JSON、采样期望图和差异图；`pixels.json` 记录通道容差 6、mip LOD 与有效采样数。纹理足迹长轴决定本机 LOD，源素材仍要求逐像素一致。五组合成错误截图保持同一观察元数据/期望，证明空白、错投影、错压缩、镜像与锚点偏移不会被放行。

`run_stage0_manual.py --stage 0.3 --map MAP01_FrontWall.wad --size 960` 可切换夹具/取景；正常游戏不加载回归驱动。`--quit-after 120` 是启动/退出烟测，会输出 `smoke.json` 并检查日志错误，**不是人工验收**。共享 `tests/.stage0_fixture/project/` 的监督器必须串行运行；不要在另一个游戏进程持有 Rapier DLL 时复制或导入该缓存。

用户于 2026-10-30 已完成首轮人工验证，仅反馈主体高度偏矮。本轮改为主体可见高度 56mu（不含光环），新增 HTest 的 50mu sector 穿入回归；用户随后确认高度有效，并允许忽略已证实的自然投影缩短，Gate D 已完成。现行五图结果见实施记录 §6.5，比例专项及验收依据见 §6.6。

高度修正后的最终结果：`tests/stage0_results/height_final_20261030/stage03/on/summary.json`，五图加三组非法入口全部通过，938 条运行断言、94 张完整截图、1,371,307 个稳定像素采样；HTest 覆盖三档视野和待机/跑动各四帧的左右朝向。独立主体掩码要求高台内露出主体，修复前的三档真实截图均被相同判据拒绝，见 `height_negative_controls.json`。人工复验使用 `py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3 --map MAP01_HTest.wad`。

比例专项位于 `tests/stage0_results/sprite_proportions_20261030/stage03/on/`：18 组无遮挡素材对照验证世界等比、屏幕 cos45 缩短，30,604 个主体采样 RGB 误差为 0。`tests/stage03_sprite_proportions.py` 已接入常规 0.3 回归；未来完整运行在 MAP01 额外保存 18 张比例截图。该次专项使用 `--maps MAP01.wad --smoke --skip-import`，完整视口 20 张、126 条运行断言和 495,340 个场景像素通过，`complete_matrix=false`，不替代此前五图完整结果。运行代码未改变，未重跑其他夹具或旧模式。
