# ETNDOOM Mod / 开发入口

ETNDOOM 将 Crispy Doom 单人运行时接入 Enter The Nyangeon。当前开发入口为 **M1**，Mod ID 为 `etndoom_m1`，桥接与内核均使用 **ABI 2**，目标平台为 **Windows x64**。

原 M1 内核范围已实现并通过人工验收，包含完整单人流程、事务存档及 SDL_mixer/OPL 音频。当前 `Rev_test` 分支进一步恢复 Crispy Doom 的原生操作体验，用于彻底的 M1 人工回归并供后续开发继续使用；允许加入方便测试的功能。

2026-11-26 本轮交互实现已落盘，涵盖鼠标视角、无调试栏的完整画面、原生 Pause/菜单、游戏内 Options 与四页 Crispness 设置、8 页共 64 个存档槽及测试方案/存档选择入口。用户已确认设置范围为游戏内 Options 和全部四页 Crispness；独立 Setup 工具及其手柄配置不在本轮范围。自动回归与窗口专项通过；用户于 2026-11-27 确认本轮功能实现全部正常，新增范围通过本轮人工验收。

本轮验证包含 4,176 条原接口断言、1,750 tic 独立参考对照、两个真实窗口进程的 287 条交互断言，以及 E/Space 使用机关专项的 484 条断言。纯宿主未加载 M1 时也出现的退出期 Texture RID / RenderingServer 报错仍存在；交互专项没有新增错误。用户已确认本轮功能实现全部正常。当前没有 demo 播放/录制入口，因此 Demo Timer、Timer Direction、Progress Bar 的设置与持久化已接入，但其 demo 运行态效果不属于已验证范围。

## Requirements / 构建环境

在仓库根目录执行下方命令。建议使用 Python 3.12 或更新版本；构建脚本使用 `tarfile` 的安全解包过滤器。准备以下工具：

- Godot 4.7.2 Windows x64；构建脚本可用 `--godot` 指定实际可执行文件。
- MinGW-W64 x64 GCC、CMake、Ninja，确保 `gcc`、`cmake`、`ninja` 可从 `PATH` 调用。既有验证组合为 GCC 16.2.0、CMake 4.4.2、Ninja 1.13.2，使用 Windows UCRT。
- SDL2 2.32.10 的 MinGW 开发包：从 [SDL 官方下载地址](https://www.libsdl.org/release/SDL2-devel-2.32.10-mingw.tar.gz) 获取，保存为 `etndoom_mod/native/downloads/SDL2-devel-2.32.10-mingw.tar.gz`，无需手动解包。构建脚本校验固定 SHA-256。

固定依赖、哈希与许可证见 [vendor/dependencies.json](vendor/dependencies.json)。仓库已包含 Crispy Doom 固定源码包、SDL2_mixer 2.8.1 开发包和对应许可证；`vendor/` 中这些文件是构建输入，不是可删除的缓存。

## Resources / 本地游戏资源

自制 `MAP01.wad` 随仓库保存。其余 WAD 由使用者自行准备，统一放入以下被 Git 忽略的目录；构建 ZIP 不包含 WAD：

```text
etndoom_mod/wad/
├── MAP01.wad
└── Third Party WAD/
    ├── DOOM2.WAD
    ├── doom.wad
    └── dss/
        ├── DSS.wad
        ├── DSS.deh
        └── DSS.txt
```

| 资源参数 | 所需文件 | 用途 |
| --- | --- | --- |
| `fixture` | `Third Party WAD/DOOM2.WAD` + `MAP01.wad` | 自制 MAP01；默认资源配置 |
| `doom2` | `Third Party WAD/DOOM2.WAD` | 原版 Doom II |
| `doom` | `Third Party WAD/doom.wad` | The Ultimate Doom |
| `dss` | `Third Party WAD/doom.wad` + `Third Party WAD/dss/DSS.wad` | Doom + DSS；DSS 替换 E2/E4 地图 |

DSS 使用 WAD 内嵌的 DEHACKED；外部 `DSS.deh` 仅保留作参考，不额外加载。只需准备要运行的资源配置所需文件。

**当前资源路径仍写在源码中，尚无通用资源选择配置。** `m1/session.gd` 中的 `IWAD`、`PWAD`、`DOOM`、`DSS` 默认以 `E:/Enter-The-Nyangeon-ETNDoom/etndoom_mod/wad/` 为根。若克隆到其他目录，先按实际位置修改这些常量，再构建 Mod。第三方资源常量指向 `Third Party WAD/`，自制 `PWAD` 仍指向原来的 `MAP01.wad`。移动资源或修改常量后，须重新打包并安装新 ZIP，既有 PCK 不会自动更新路径。

## Build / 构建 M1

```powershell
py -3 etndoom_mod/build_native.py
py -3 etndoom_mod/build_m1.py --godot 'D:/Creating/Godot/Godot_v4.7.2-stable_win64_console.exe'
```

将示例 Godot 路径改为本机实际路径。第一条命令构建 M1 内核并准备依赖 DLL；如还需独立参考程序，可改用 `py -3 etndoom_mod/build_native.py --all`。`--jobs` 调整原生构建并行数，默认 8。

默认产物为 `etndoom_mod/build/m1/etndoom_m1.zip`，包含 PCK、原生桥接、内核、SDL2/SDL2_mixer DLL 及许可证。`build_m1.py` 还支持 `--output` 和 `--native-dir`；实际构建身份与文件哈希记录在输出目录的 `build_lock.json`，原生构建记录在 `native/build/build-lock.json`。

## Install and Run / 安装与运行

准备兼容的 ETN Windows x64 宿主；从本仓库构建或运行本体时，先阅读 [根 README](../README.md) 中的 Godot 环境和本地辅助插件说明。

1. 在游戏设置的 **MOD** 页导入生成的 `etndoom_m1.zip` 并启用。
2. 完整退出游戏，再带 M1 参数启动。更新 Mod 后也需要完整退出再启动，以加载匹配的新原生库。
3. 例如，以下 PowerShell 命令打开测试入口，并预选 The Ultimate Doom；把示例可执行文件路径换成实际宿主路径：

   ```powershell
   & 'C:/Games/Enter The Nyangeon/Enter The Nyangeon.exe' -- --etndoom=m1 --m1-resource=doom
   ```

DSS 可使用 `--m1-resource=dss --m1-episode=2 --m1-map=1`；自制夹具可使用 `--m1-resource=fixture --m1-jump=on`。`--m1-skill` 接受 1–5；Doom/DSS 的关卡范围为 E1–E4、M1–M9。未指定 `--etndoom=m1` 时不会进入 M1。

默认启动面板可选 fixture、Doom、Doom II、DSS E2/E4，调整难度、章节、地图和跳跃配置，再选择新游戏或已有本地存档。面板默认勾选全屏游玩；退出后恢复 ETN 窗口。需要直接运行时追加 `--m1-direct`；加载指定存档可再加 `--m1-load-slot=0..63`，槽位编号从 0 开始。

操作沿用 Crispy 默认键位，并在游玩时保留 `E` 使用机关的兼容操作：

| 输入 | 行为 |
| --- | --- |
| 鼠标移动、←/→ | 转动视角 |
| WASD、↑/↓，Shift | 移动/横移，跑步 |
| Ctrl 或鼠标左键、E / Space | 开火、使用机关/死亡重生 |
| 1–7、鼠标滚轮，`/` | 选择武器、切换武器；启用跳跃时 `/` 跳跃 |
| Tab，Esc，Pause | 自动地图、原生菜单、原生暂停 |
| F2 / F3，F4 | 存档/读档菜单、音量菜单 |
| F6 / F9，F10 | 快速保存/快速读取、原生退出确认 |

原生 Quit 返回测试启动面板；面板可返回 ETN，ETN 中 F9 再次打开测试面板。Crispy 画面使用完整视口并遵循原生宽高比校正，不显示宿主工具栏、tic 状态、键位提示、CRT、调试面板或过场覆盖层。游戏内设置通过原生菜单调整；VSync、帧率和 Smooth Pixel Scaling 同步到实际 Godot 显示，平滑像素缩放采用与原生整数放大后线性缩放等价的 shader。返回时恢复宿主窗口、内容缩放、鼠标、显示设置与覆盖层状态。

Options 和四页 Crispness 的配置均已接入。Demo Timer、Timer Direction、Progress Bar 可调整并保存；当前没有 demo 播放/录制入口，其 demo 运行态效果尚未验证。

存档与 Crispy 配置保存在 `user://etndoom_m1/saves/<resource>_<original|jump>/`，与 ETN 主存档隔离。同一用户数据目录可跨进程继续；人工测试脚本若创建新的隔离目录，须使用它生成的同一启动器复开才能看到先前存档。存档为 `m1-slot-N.etns`，保留原生名称与文件时间；读取时严格核验资源与内核 DLL 内容身份。交互存档记录并恢复保存时的 jump/freeaim/overunder 规则。不同构建的旧档保留在原目录，应使用对应旧构建启动器读取。

## Repository / 入库范围与本地资料

正式 Mod 源码、构建脚本、接口头、固定依赖包及许可证、自制 `MAP01.wad` 随仓库保存。原生构建目录、解压源码、下载缓存、生成的 Mod 包与 Python 缓存由各级 `.gitignore` 排除。

`ETNDOOM/` 详细知识库、根目录 `AGENTS.md`、第三方 WAD、`release/`、`.migration/` 及 ETNDOOM 本地测试脚本和证据仅本地保留，克隆仓库不会取得。已有上游跟踪的 `tests/` 文件继续保留；本地 ETNDOOM 测试不属于公开构建流程的前置条件。

## Runtime Observation / 运行观察接口

`Rev_test` 实际游玩经 `m1_input` 接收原始键鼠事件，由 Crispy `G_PrepTiccmd/G_BuildTiccmd` 构建输入，`m1_play_tick` 推进 35 Hz 模拟；`m1_ui_status` 返回菜单、原生暂停与显示设置。对应桥接口为 `input_json`、`play_tick_json`、`ui_status_json`。游戏内菜单和自动地图/秘籍沿原生 responder 路径，宿主不再代写全部玩法输入。

`session.play_tick()` 仍只消费轻量 `status`，保留世界代次、时钟、流程和请求完成信息；每 tic 不生成实体与地图的完整 JSON 快照。交互模式支持原生动态 framebuffer 尺寸与 uncapped 显示；菜单仍响应但不推进世界模拟。原生 Pause 与打开菜单保持不同语义，失焦另由宿主暂停原因管理。

`session.command(cmd)`、`session.step(count)` 默认仍返回完整 `snapshot`；显式 `session.snapshot()` 也保持原有数据格式。需要完整观察数据的消费者应自行控制读取频率，大地图的全量快照仍有明显成本。`step(count, false)` 只返回轻量状态，暂停时仍返回 `executed=0`。

显式 ticcmd 的 `command/step` 路径保留原来的固定配置与缓存读取语义；`m1_status` 对应 `status_json` / `step_status_core`。交互能力是 ABI 2 的追加导出，须重新构建内核和 M1 包并配套安装，新桥接在创建会话前拒绝缺少必需导出的旧内核。更新后使用新进程；不同内核构建的旧存档会被兼容性预检拒绝。

## Legacy / 历史阶段

M0 与 Stage0 源码继续保留。M0 需要 ABI 1，不能将当前 `build_native.py` 生成的 ABI 2 内核与 M0 桥接混用。Stage0 完整历史回归依赖的部分自制地图已经缺失，不能将其旧命令视为当前完整可运行入口。详细阶段契约、历史命令和验收记录保存在本地知识库。
