# Migration / ETNDOOM fork 仓库迁移

> Date / 日期：2026-11-23。
> Source / 来源：user（迁移目标、先提交再适配、远端限制）；code（Git 树、WAD 路径）；test（新目录构建与真实宿主回归）。

## Repository / 仓库关系与初始提交

当前开发根目录为 `E:\Enter-The-Nyangeon-ETNDoom`，开发分支为 `Rev`。

- 原上游本地基线：`E:\Enter-The-Nyangeon`，`b0ef6d5f33bdc162a0af951dcfa4eafda179bf47`；仅作只读比较，禁止操作其远端。
- 旧 ETNDOOM 内容：`E:\ETN_DOOM`，`ceef1c0a656063e93835bf83c5e45830985119d3`，独立 Git 历史；源目录完整保留。
- fork 本体基线：`65505ff4ec81a7fb3dfde0133fc2058d3960113d`，含上述上游基线及之后 115 个提交。
- 用户确认后的初始迁入提交：`b203a596802f0d9147688c37d29f255b3d1a3d28`（`feat: 迁入 ETNDOOM Mod 与设计文档`）。包含两个目录 98 个文件和两个根级规则文件；这 98 个文件的 Git blob 与旧 ETNDOOM 一致。
- 初始提交后的路径适配与本页文档为后续独立改动，提交仍须用户确认。AI 不执行 push；fork 远端修改须用户确认，旧上游远端禁止任何操作。

旧 ETNDOOM 对比本体 `b0ef6d5`：99 个新增（98 个项目文件与旧 `docs/MIGRATION.md`）、8 个变化（`.gitignore`、`.gitattributes`、`AGENTS.md`、`README.md` 和 `docs/` 四份文档）、46 个缺失（全部是旧 ETNDOOM 未跟踪的上游测试）。本体功能源码、资源及 `project.godot` 无差异。迁入没有删除 fork 的测试或覆盖它的新版本体；`docs/` 保持上游内容。旧迁移报告按原字节保存在 [Legacy/MIGRATION.md](Legacy/MIGRATION.md)，其中路径和验证结果只代表 2026-10-30 的历史。

## Local Files / 本地依赖与保留范围

| 内容 | 当前处理 |
|---|---|
| `etndoom_mod/`、`ETNDOOM/`、vendor 固定源码/许可证 | 纳入 Git；第三方许可证按字节保留 |
| `wad/MAP01.wad` | 唯一已跟踪 WAD，自制夹具 |
| `wad/DOOM2.WAD`、`wad/doom.wad`、`wad/dss/` | 从旧根复制并核对 SHA-256，仅本地忽略；DSS 外部 DEH 仅参考、不加载 |
| `native/downloads/SDL2-devel-2.32.10-mingw.tar.gz` | 从旧根复制，构建入口校验固定 SHA-256，仅本地 |
| M0/M1 测试脚本 | 40 份从旧根复制，未覆盖 fork 的上游测试；所有 `tests/` 改动不提交 |
| `.git/info/exclude` | 本地增加 `/tests/`，只隐藏未跟踪测试与证据，不移除已跟踪上游测试 |
| 原生构建、`etndoom_mod/build/`、`release/`、`.migration/` | 目标目录重新生成，仅本地 |
| 旧结果、旧发布包、Obsidian 配置、旧 `.migration/` | 原样保留在 `E:\ETN_DOOM`，没有整体搬运/清理；不能称本次运行证据 |

本次仍采用本机明确 WAD 路径：`m0/session.gd:4`、`m1/session.gd:4`、`stage0/stage0.gd:4`、`stage03/stage03.gd:4` 改为 `E:/Enter-The-Nyangeon-ETNDoom/etndoom_mod/wad/`。PCK 会内嵌这些路径，迁移后必须重建并安装新 ZIP；本次不是任意目录可用的通用资源配置功能。

## Build and Host / 构建与测试宿主

在新根目录使用 Godot 4.7.2、Python、MinGW gcc、CMake 和 Ninja：

```powershell
py -3 etndoom_mod/build_native.py --all
py -3 etndoom_mod/build_m1.py
```

直接从根工程导出的首次宿主被缺失的 `godot_ai` autoload 阻断（失败证据 `tests/m1_results/20261123_180649/summary.json`）。最终宿主来自 `.migration/compat_20261123/host_source/`：逐个复制 fork 已跟踪文件，在隔离副本中只剔除 `project.godot` 的两行 `godot_ai` 配置，并对测试/文档/SDK 源目录加本地 `.gdignore`。实际仓库的 `project.godot` 未改。重现脚本为 `.migration/compat_20261123/export_host.py`，文件清单、被剔除行与导出身份见 `host_export.json`，日志见 `host_import.log`、`host_export.log`。

宿主沿用本地测试脚本需要的 `release/pak/Enter The Nyangeon v0.5.2.0-test.exe` 文件名，实际内嵌源码是 fork `65505ff` 基线（导出预设为 0.5.2.3），不是旧 0.5.2.0 发布包。首次根工程导入产生的 627 个 `.import` 变化及 11 个新 UID 已清理，只恢复本轮生成内容；未回退功能源码。隔离导出日志仍有退出时资源计数提示，运行回归未记录脚本/资源错误。

## Verification / 本次兼容结果

```powershell
py -3 tests/run_m1_checks.py --output tests/m1_results/fork_compat_20261123
py -3 tests/m1_prepare_delivery_manual.py
```

`tests/m1_results/fork_compat_20261123/summary.json`：`ok=true`，11 个宿主用例共 6,039 条断言通过；fixture 700 tic、纯 Doom/DSS E2/DSS E4 各 350 tic，合计 1,750 tic 独立参考差分完全一致。覆盖真实 ZIP 安装、退出码/随机票据、运行时边界、调度、4 组画面、返回 ETN 与再次进入；四份实际视口截图均已检查。

- Mod ZIP SHA-256：`de1e39f44cd1a42b38547c59e5ba3418c21104e60599e361ec5575dc5df0fd85`；build ID：`56def0d517eab3a52ebd`。
- 测试宿主 SHA-256：`89732b7771fd2d06ba8a59f79b78468e69634eafc03ff78c8a72edb00148f6e0`。
- 五组新人工入口已通过隔离安装生成，统一入口为 `tests/m1_manual/启动M1人工验证.cmd`，身份见 `current_entries.json`；人工验收仍待用户。
- `complete_host_matrix=false`：本轮未执行 V18 更新/禁用/卸载链，也未重跑全部玩法/音频/存档专项；此次结果仅表示迁移兼容范围通过。
- M0 已是 ABI 1 历史基线，默认原生构建为 M1 ABI 2；不能用当前 `build_native.py` 接 `build_m0.py` 声称 M0 已重建。M0/Stage0 此次只做路径适配，未运行其历史回归；Stage0 完整五图仍缺四张已删除夹具，没有恢复这些删除。

逐个本地资源哈希、ZIP 边界与初始/适配状态汇总见 `.migration/compat_20261123/migration_verification.json`。本次没有改变 M1“实现完成、人工验收未完成”的阶段状态。
