> Migration / 迁移（2026-10-30）：ETNDOOM 当前开发根目录为 `E:\ETN_DOOM`。本文历史记录中的 `E:\Enter-The-Nyangeon` 路径保留作为当时证据；现行目录与运行入口见 [`docs/MIGRATION.md`](../../docs/MIGRATION.md)。

# Build and Run Log / 构建与运行记录

> Scope / 范围：记录 Enter The Nyangeon 当前源码的本地启动、Windows 导出和单文件运行验证。
> Project / 项目：`E:\Enter-The-Nyangeon`
> Date / 日期：2026-10-21
> Status / 状态：已完成本地验证；未提交 Git。

## 1. Environment / 环境

- Godot：`4.7.2.stable.official.ed1daf0bf`
- Godot editor：`D:\Creating\Godot\Godot_v4.7.2-stable_win64.exe`
- Godot console：`D:\Creating\Godot\Godot_v4.7.2-stable_win64_console.exe`
- Export templates：`D:\Creating\Godot\editor_data\export_templates\4.7.2.stable`
- Project version：`v0.5.1.4`（`script/Game.gd`）
- Main scene：`res://scenes/main/title_screen.tscn`
- Physics：`Rapier2D v0.8.37`

## 2. Source Run / 源码运行

### 2.1 Flow / 流程

1. 使用 Godot editor 从源码目录打开项目：

   ```powershell
   & 'D:\Creating\Godot\Godot_v4.7.2-stable_win64.exe' --path 'E:\Enter-The-Nyangeon'
   ```

2. 编辑器启动项目主场景 `res://scenes/main/title_screen.tscn`。
3. 使用实际游戏窗口检查渲染、主菜单和物理引擎初始化。
4. 将运行日志和截图保存在 Godot 工具目录：
   - `D:\Creating\Godot\etn-game.log`
   - `D:\Creating\Godot\etn-runtime-check.log`
   - `D:\Creating\Godot\etn-running.png`

### 2.2 Result / 结果

- 游戏成功启动并进入主菜单。
- `Forward Plus` / Vulkan 渲染正常。
- 日志确认 `Rapier2D v0.8.37` 正常加载。
- 本机缺少 `addons/godot_ai`，启动时出现与 `_mcp_game_helper` 和编辑器插件相关的 autoload/plugin 错误；该错误没有阻止游戏进入主菜单。
- 源码中的 `project.godot` 本地 `godot_ai` 配置按项目约定保留，没有为了运行验证而修改。

## 3. Export / 导出

### 3.1 Isolated build / 隔离构建

为避免旧示例、测试、`ETNDOOM` 和 SDK 进入本体，先在以下临时目录建立构建副本：

```text
E:\Enter-The-Nyangeon\.godot\single-exe-build\source
```

构建副本排除了：

- `release`
- `tests`
- `ETNDOOM`
- `mod_sdk`
- `android`
- `docs`
- `mods`
- `addons/godot_ai`

构建副本只移除了本地开发辅助插件的 autoload 和 editor plugin 声明；Rapier2D 保留。

### 3.2 Native Godot export / Godot 原生导出

使用 `Windows Desktop` 预设导出：

```powershell
& 'D:\Creating\Godot\Godot_v4.7.2-stable_win64.exe' `
  --headless `
  --path 'E:\Enter-The-Nyangeon\.godot\single-exe-build\source' `
  --export-release 'Windows Desktop' `
  'E:\Enter-The-Nyangeon\.godot\single-exe-build\native\ETN.exe'
```

原生导出成功，但 Godot 的 `binary_format/embed_pck=true` 只将项目 PCK 嵌入 `ETN.exe`，Rapier2D 的 GDExtension 仍生成独立 DLL：

- `ETN.exe`：`328125528` bytes
- `libgodot_rapier.windows.x86_64-pc-windows-msvc.dll`：`8710656` bytes

无界面启动检查成功，退出码为 `0`，日志确认：

```text
PHYSICS ENGINE 2D: Rapier2D v0.8.37
```

PCK 目录检查结果：

- 共 `3881` 个资源条目。
- 未发现 `release/`、`tests/`、`ETNDOOM/`、`mod_sdk/`、`mods/` 或 `addons/godot_ai/`。
- `project.binary` 中保留 Rapier2D 配置。
- `project.binary` 中不含 `_mcp_game_helper`。

## 4. Single EXE Run / 单文件运行

### 4.1 Packaging flow / 封装流程

由于 Rapier2D DLL 不能由 Godot 原生导出直接合并进可执行文件，将上述两个原生导出文件打入单文件启动器：

```text
E:\Enter-The-Nyangeon\release\pak\Enter The Nyangeon v0.5.1.4.exe
```

启动器行为：

1. 检查内嵌 `ETN.exe` 与 Rapier2D DLL 的大小和 SHA-256。
2. 首次运行时解包到：

   ```text
   %LOCALAPPDATA%\EnterTheNyangeon\Runtime\ca776eddf163632cefff941c9545f9b4f345368c01c2a195dccb710dca545f22
   ```

3. 从该缓存目录启动真正的 Godot 游戏。
4. 后续运行复用校验通过的缓存文件。

这是运行时解包型单文件，不是将 Rapier2D 原生代码静态链接进 Godot 引擎；交付目录仍只有一个 `.exe`。

### 4.2 Run flow / 运行流程

从非源码工作目录启动，确保不会误用源码资源：

```powershell
Start-Process `
  -FilePath 'E:\Enter-The-Nyangeon\release\pak\Enter The Nyangeon v0.5.1.4.exe' `
  -ArgumentList '--windowed', '--resolution', '1280x720' `
  -WorkingDirectory 'C:\Windows'
```

另进行了无界面启动检查：

```powershell
& 'E:\Enter-The-Nyangeon\release\pak\Enter The Nyangeon v0.5.1.4.exe' `
  --headless `
  --quit-after 120 `
  --log-file 'E:\Enter-The-Nyangeon\.godot\single-exe-build\single exe startup.log'
```

### 4.3 Result / 结果

- 单文件无界面启动退出码：`0`。
- 冷启动耗时约 `12.7` 秒，主要包含首次解包。
- 实际运行进程路径确认位于 `%LOCALAPPDATA%\EnterTheNyangeon\Runtime\...`，不是源码目录。
- GPU 安全截图成功，主菜单正常显示：
  - `E:\Enter-The-Nyangeon\.godot\single-exe-build\packaged-game.png`
- 窗口画面确认标题、语言选择、菜单项、版本号 `v0.5.1.4` 和背景资源均正常。
- 最终产物大小：`249657856` bytes。
- 最终产物 SHA-256：

  ```text
  071245E62DED65EACFAAEE7C1CCFD1EF3D4B8DF5CA6861992EB1448449889155
  ```

## 5. Delivery Boundary / 交付边界（2026-10-21 历史记录）

当时 `release\pak` 顶层只有：

```text
Enter The Nyangeon v0.5.1.4.exe
```

`release\pak\eg` 保留原有旧示例：

```text
Enter The Nyangeon v 0.3.3.4.exe
```

旧示例没有被覆盖或作为当次构建使用。源码、导出预设和项目中的 `godot_ai` 本地工具配置没有因当次打包而提交或改写；临时构建材料位于 `.godot/single-exe-build`。

## 6. Latest Build / 最新提交打包（2026-10-24）

### 6.1 Source and export / 源码与导出

- Git HEAD：`b0ef6d5`（`feat(level): 下调 TM 难度伤害系数 4.0 → 3.5`），工作树已拉取至该提交；源码版本为 `v0.5.2.0-test`。
- Godot：`4.7.2.stable.official.ed1daf0bf`，Rapier2D `v0.8.37`。
- 在 `.godot/single-exe-build-20261024/source` 建立隔离副本；排除 `.git`、`.godot`、`release`、`tests`、`ETNDOOM`、`etndoom_mod`、`mod_sdk`、`android`、`docs`、`mods` 和本地 `godot_ai` 插件。仅在副本 `project.godot` 移除 `_mcp_game_helper` autoload 并清空 editor plugin 列表，主工作树未改动。
- 重新导入资源成功。导入音频时出现一次 `ERROR: Condition "p_position > length" is true.`，导入进程仍以退出码 `0` 完成；后续导出、无界面启动及实际窗口运行均成功。
- Windows Desktop 原生导出命令：

  ```powershell
  & 'D:\Creating\Godot\Godot_v4.7.2-stable_win64_console.exe' `
    --headless `
    --path 'E:\Enter-The-Nyangeon\.godot\single-exe-build-20261024\source' `
    --export-release 'Windows Desktop' `
    'E:\Enter-The-Nyangeon\.godot\single-exe-build-20261024\native\ETN.exe'
  ```

- 原生导出包含 `ETN.exe`（`328442296` bytes）及 `libgodot_rapier.windows.x86_64-pc-windows-msvc.dll`（`8710656` bytes）。两者封装进单文件启动器，首次运行按 SHA-256 校验后解包到 `%LOCALAPPDATA%\EnterTheNyangeon\Runtime\<bundle-id>`。

### 6.2 Run result / 运行结果

- 输出：`E:\Enter-The-Nyangeon\release\pak\Enter The Nyangeon v0.5.2.0-test.exe`。
- 无界面检查从 `C:\Windows` 启动，带 `--headless --quit-after 180`，退出码 `0`；运行日志确认 `Rapier2D v0.8.37`。
- 窗口模式从 `C:\Windows` 启动，启动器与游戏进程均响应正常；实际 GPU 窗口截图确认主菜单、简体中文语言选择和背景资源正常显示。截图：`E:\Enter-The-Nyangeon\.godot\single-exe-build-20261024\packaged-window.png`。
- 本次窗口运行日志：`%APPDATA%\Godot\app_userdata\Enter The Nyangeon\logs\ETN_debug2026-10-24T18.17.58.log`；仅有 Godot/Vulkan 与 Rapier2D 初始化信息，未见脚本或资源错误。
- 最终 EXE 大小：`249889280` bytes；SHA-256：

  ```text
  AAF8B276D6B5DEA55F83960608436368817BD6B7656170759A19F78506754C1D
  ```

- `release\pak` 顶层为新 EXE 与原有 `eg` 示例目录；`eg` 未修改。除该示例外，交付目录没有拆分出的游戏 EXE、PCK 或 Rapier DLL。
- 本次构建副本、启动器源码、载荷与验证日志均位于 `.godot/single-exe-build-20261024`；没有提交 Git，也没有改动主工作树中的项目配置。
