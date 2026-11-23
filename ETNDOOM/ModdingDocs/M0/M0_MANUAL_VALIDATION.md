# M0 Manual Validation / 人工验证入口与检查单

> Date / 日期：2026-11-18。
> Status / 状态：**人工验收通过，M0 已完成**（2026-11-18，来源：user）。两个正式入口及原始启动冒烟证据保留；用户确认与结案记录见 §5。自动结果另见[探针记录](M0_PROBES_AND_ACCEPTANCE.md)。G1 组合发布授权仍待裁定。
> Source / 来源：user（2026-11-18 确认人工通过） | code | test；只使用用户已获准的两种 WAD 组合。

## 1. Launch / 直接启动

以下两个启动器已准备好，均使用独立测试用户目录，关闭窗口结束。它们只运行正式 `etndoom_m0` entry，安装用测试模组已移除：

| 入口 | 启动文件 | 内容 |
|---|---|---|
| 自制图 + 原生跳跃 | [`启动人工验证.ps1`](../../../tests/m0_manual/20261117_201947_fixture_2089de/启动人工验证.ps1) | `DOOM2.WAD + MAP01.wad`，`MAP01`，skill 3，jump on |
| 原版 Doom II | [`启动人工验证.ps1`](../../../tests/m0_manual/20261117_201950_doom2_1539d3/启动人工验证.ps1) | 仅 `DOOM2.WAD`，从 `MAP01` 开始，skill 3，jump off |

实际完整路径如下，复制到 PowerShell 运行：

```powershell
& 'E:\ETN_DOOM\tests\m0_manual\20261117_201947_fixture_2089de\启动人工验证.ps1'
& 'E:\ETN_DOOM\tests\m0_manual\20261117_201950_doom2_1539d3\启动人工验证.ps1'
```

重新安装当前包并启动新的隔离人工目录：

```powershell
py -3 tests/run_m0_manual.py --resource fixture --jump
py -3 tests/run_m0_manual.py --resource doom2
```

加 `--prepare-only` 仅准备启动器。模组包为 `etndoom_mod/build/m0/etndoom_m0.zip`，build `beca8371a8191c976757`，SHA-256 `f0dc5a55b6ec2ae8cb91fbd3bf9ca54c64d2c2f56ee1c901b7d01a7c4192ca54`。当前临时显示是 Crispy 软件画面，最终俯视属于 M2；M0 未开启音频输出。

## 2. Controls / 操作

| 按键 | 操作 |
|---|---|
| W/S、A/D | 前后移动、左右横移 |
| ←/→ | 转向 |
| Shift | 加速移动 |
| Ctrl / 鼠标左键 | 开火 |
| E | 使用/开门 |
| 1–7 | 请求切换武器 |
| Space | Crispy 原生跳跃，仅 jump on 入口启用 |
| Esc | 暂停/继续；失焦自动暂停 |
| F5 | 销毁并重新创建会话 |
| F10 / 顶部返回按钮 | 返回原 ETN 菜单 |

## 3. Checklist / 人工检查单

本清单记录主观体验和真实交互；自动截图/差分不能代替人工确认。完整战斗、机关、跨图、存读档的系统性继承验收仍归 M1。

1. 自制图入口显示真实 DOOM 场景和状态栏，窗口缩放后比例、清晰度可接受，界面没有挡住关键操作。
2. 在自制图移动、转向、贴墙和上下台阶；连续按键与释放均正常，未出现粘键或突然跳位。Space 确有原生起跳/落地，F5 后出生状态恢复。
3. Esc 暂停 5 秒后继续，不补跑暂停时间；切换到其它窗口再回来，处于暂停状态，继续后无残留开火/移动。
4. 原版 Doom II 入口可见 `MAP01`，按 E 开门、开火、拾取和切武器可操作；记录任何明显异常，但不因此把整套战斗/流程验收标完成。
5. F10 返回时原 ETN 菜单仍可点击，鼠标状态正确，原菜单音频按进入前状态恢复；再次通过启动器进入，初态一致。
6. 如出现报错，记录入口、步骤、显示错误与该目录的 `launch.json`、`manual.log`/隔离 `logs/ETN_debug.log`。不要将异常 WAD 另存派生文件后自动加入测试，新的资源仍需明确许可。

记录建议：`入口 / 检查项 / 通过或问题 / 复现步骤 / 日志位置`。SUPERSEDED: 2026-11-18，原“等待人工结果”已由用户确认通过取代。两个 `launch.json`、`smoke.json` 及自动 `summary.json` 中的 `manual_acceptance=false` 保留为生成当时的历史快照；当前结论由 §5 的独立人工记录与交付索引表达，不改写原自动输出。

## 4. Cleanup / 退出后的原生缓存清理

正常更新成功后 entry 会清理非当前构建缓存；卸载后 entry 不再运行，需要显式清理最后缓存。先完全关闭由该启动器启动的游戏，再使用本地工具并指定对应 `launch.json` 中的 `user_dir`：

```powershell
py -3 tests/clean_m0_cache.py --user-dir 'E:/ETN_DOOM/tests/m0_manual/20261117_201947_fixture_2089de/人工验证 隔离用户/APPDATA/Godot/app_userdata/Enter The Nyangeon'
```

工具仅接受本仓库 `tests/` 内的隔离路径，只清本模组 native 根中的哈希目录，保留 `saves`。文件仍被占用会报告保留项，不强制关闭其它进程。普通关闭游戏无需每次清缓存；再次启动会按完整哈希重新验证和复制缺失文件。

## 5. Acceptance / 人工验收结论（2026-11-18）

- Source / 来源：user。
- 用户原话：“预期内的M0行为全部完成，我标记人工验证为通过”。
- 结论：M0 预期行为的人工验收通过，阶段已完成；不从这条总体确认推导逐项操作录像、完整 M1 玩法覆盖或新增资源许可。
- 本地记录：`tests/m0_results/final_delivery_20261117/manual_acceptance.json`；统一索引 `delivery.json` 已记录 `manual_acceptance=true`、`m0_complete=true`，并保留 G1 待裁定。
- 验收构建：build `beca8371a8191c976757`，ZIP SHA-256 `f0dc5a55b6ec2ae8cb91fbd3bf9ca54c64d2c2f56ee1c901b7d01a7c4192ca54`；本次文档收尾与清理不重新构建或替换已验收产物。
- 后续边界：完整战斗/机关/流程/存档/音频属于 M1，最终俯视属于 M2；G1 组合发布授权仍待裁定。
