# Migration / ETNDOOM 独立仓库迁移

> Date / 日期：2026-10-30
> Source / 来源：user（完整独立仓库方案）、code（依赖检查）、test（文件校验与运行验证）。

## Scope / 范围

当前开发根目录为 `E:\ETN_DOOM`。从 `E:\Enter-The-Nyangeon` 复制完整本体基线，保留 `scenes/`、`script/`、`resources/`、贴图、音频、字体、Rapier2D、本地化资源、`mod_sdk/` 与 `docs/` 的原有相对路径。新仓库保留自己的 Git 历史，不复制旧 `.git`。

来源本体提交：`b0ef6d5`（`feat(level): 下调 TM 难度伤害系数 4.0 → 3.5`）；目标原有提交：`95a69c8`（`Initial commit`）。迁移前旧仓库已跟踪文件的工作区和暂存区均无改动。完整提交哈希和逐文件 SHA-256 见本地 `.migration/copy-manifest.json`。

| 内容 | 新位置 | Git 边界 |
|---|---|---|
| ETNDOOM 设计、研究、契约与历史 | `ETNDOOM/` | 可跟踪，Obsidian 窗口状态忽略 |
| Mod 代码、场景与自制地图 | `etndoom_mod/` | 可跟踪 |
| 商业 IWAD | `etndoom_mod/wad/DOOM2.WAD` | 本地保留，不提交、不打包 |
| Mod 构建产物 | `etndoom_mod/build/` | 本地保留，迁移后重新构建 |
| 全部原有本地测试及 Stage0 新增测试 | `tests/` | 本地保留，不提交 |
| 回归依赖、隔离工程、历史日志和截图 | `tests/.stage0_*`、`tests/stage0_*` | 本地保留，不提交 |
| 两个游戏导出版 | `release/pak/` | 本地保留，不提交 |
| 历史单文件导出工作区和证据 | `.godot/single-exe-build*` | 本地保留，不提交 |
| 校验清单、修改前副本和迁移原件 | `.migration/` | 本地保留，不提交 |

原本体的共享 `.godot` 编辑器、导入与 shader 缓存不复制；新回归使用自己的隔离工程。原 `mod_sdk/coop_mod/build/` 属于本体联机 Mod 的生成物，留在旧仓库；SDK 源码已复制。本次检查未发现 `mod_sdk/mobile_hotfix/`，若后续出现，仍按 AGENTS 约定保留且不提交。

## Paths / 路径与保留行为

- `etndoom_mod/stage0/stage0.gd:4` 的 `SOURCE_WAD` 改为 `E:/ETN_DOOM/etndoom_mod/wad/DOOM2.WAD`，使新构建包读取迁入的新文件。PCK 内部仍使用 `res://mods/etndoom_stage0/`；WAD 仍为外部本地依赖。
- `etndoom_mod/build_stage0.py:12` 与 `tests/isolated_godot.py:8` 原本按脚本位置推导仓库根目录，目录结构保持后无需改动。`mod_sdk/pack_mod.gd`、本体场景和资源均在新仓库内。
- 当前开发文档和命令改用新根目录；历史 WORKLOG、决策历史、旧构建日志和原始测试结果保留当时的路径，文档顶部附迁移说明，不能将历史结果误当成本次验证。
- `project.godot` 按原字节复制，不改动本地 `godot_ai` autoload 状态。原仓库本来就缺少 `addons/godot_ai`；直接打开根工程可能提示该本地插件缺失。既有 `tests/run_stage0_checks.py:49` 会在隔离工程副本中剔除工具 autoload，因此下方测试/人工入口不依赖该插件。
- 本体本地化 CSV 与 `.translation` 均按原字节复制，不重写、不触发内容更改；新仓库 `.gitattributes` 增补 `ETN_*localization.csv text eol=crlf`，保留原 UTF-8 BOM。
- 原目录中 ETNDOOM 专属新增文件在副本校验后移至新仓库的 `.migration/originals/`；此处保留迁移前原件，当前开发使用上表列出的正式位置。本体已跟踪文件不删除、不回退。

## Run / 运行

在 `E:\ETN_DOOM` 中执行：

```powershell
py -3 etndoom_mod/build_stage0.py --godot "D:\Creating\Godot\Godot_v4.7.2-stable_win64_console.exe"
py -3 tests/run_stage0_checks.py
py -3 tests/run_stage0_manual.py --stage 0.1
py -3 tests/run_stage0_manual.py --stage 0.2
```

需要 Godot 4.7.2、Python、`numpy`、`Pillow`；独立 WAD 参考工具 `omgifol==0.5.1` 已随 `tests/.stage0_deps/` 迁入。Godot 可用 `--godot` 指定其他安装位置。人工入口隔离存档、安装 Mod 并按真实 entry 启动；运行导出版时需要重新导入新构建的 ZIP 并重启，已安装的旧 PCK 不会自动更新。

## Verification / 验证

迁移文件先逐个复制并做 SHA-256 比对，再进行明确的路径和文档调整。副本与原件信息见 `.migration/copy-manifest.json`、`.migration/edited-files.json`；构建及回归会更新新目录中的生成物，历史原件另行保留。

已复制并逐文件校验 23,683 个文件，共 4,735,586,573 字节（约 4.41 GiB），包括完整本体基线和两套历史单文件导出工作区。

本次回归结果为 `tests/stage0_results/migration_20261030/summary.json`：`ok=true`、`complete_matrix=true`，8 个用例全部通过，共 21,147 条断言；Stage0.1 / 0.2 像素比对通过。真实 ZIP 安装返回 75，随机重启票据匹配。最终文件与 Git 边界校验见本地 `.migration/final-verification.json`。未创建 Git 提交，未执行推送。
