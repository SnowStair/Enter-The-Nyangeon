# ETNDOOM Mod / 开发入口

ETNDOOM 将 Crispy Doom 单人运行时接入 Enter The Nyangeon。当前开发入口为 **M1**，Mod ID 为 `etndoom_m1`，桥接与内核均使用 **ABI 2**，目标平台为 **Windows x64**。

M1 已实现新游戏、当前图重开、死亡重生、流程确认、暂停、8 个存档槽及 SDL_mixer/OPL 音频。此前已通过 fork 本体的迁移兼容检查，人工验收仍未完成；当前构建用于本地验证，不代表已完成正式组合分发。

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
3. 例如，以下 PowerShell 命令运行 The Ultimate Doom；把示例可执行文件路径换成实际宿主路径：

   ```powershell
   & 'C:/Games/Enter The Nyangeon/Enter The Nyangeon.exe' -- --etndoom=m1 --m1-resource=doom
   ```

DSS 可使用 `--m1-resource=dss --m1-episode=2 --m1-map=1`；自制夹具可使用 `--m1-resource=fixture --m1-jump=on`。`--m1-skill` 接受 1–5；Doom/DSS 的关卡范围为 E1–E4、M1–M9。未指定 `--etndoom=m1` 时不会进入 M1。

操作：WASD 移动，左右方向键转向，Shift 跑步，Ctrl 或画面左键开火，E 使用，1–7 切换武器；开启跳跃时 Space 跳跃。Esc 暂停，F5 重开本图，Enter 重生/确认，F6/F7 保存/读取当前槽位，F10 返回 ETN，F9 再次进入。

## Repository / 入库范围与本地资料

正式 Mod 源码、构建脚本、接口头、固定依赖包及许可证、自制 `MAP01.wad` 随仓库保存。原生构建目录、解压源码、下载缓存、生成的 Mod 包与 Python 缓存由各级 `.gitignore` 排除。

`ETNDOOM/` 详细知识库、根目录 `AGENTS.md`、第三方 WAD、`release/`、`.migration/` 及 ETNDOOM 本地测试脚本和证据仅本地保留，克隆仓库不会取得。已有上游跟踪的 `tests/` 文件继续保留；本地 ETNDOOM 测试不属于公开构建流程的前置条件。

## Legacy / 历史阶段

M0 与 Stage0 源码继续保留。M0 需要 ABI 1，不能将当前 `build_native.py` 生成的 ABI 2 内核与 M0 桥接混用。Stage0 完整历史回归依赖的部分自制地图已经缺失，不能将其旧命令视为当前完整可运行入口。详细阶段契约、历史命令和验收记录保存在本地知识库。
