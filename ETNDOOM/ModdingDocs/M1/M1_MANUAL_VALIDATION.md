# M1 Manual Validation / M1 人工验证入口

> Date / 日期：2026-11-23（fork 迁移入口更新；原检查单 2026-11-19）。
> Source / 来源：code（M1 实际入口与操作控件）。
> Status / 状态：人工检查单；**尚未取得用户人工验收结论**。自动结果另见 [M1 验收](M1_VALIDATION.md)。

## 1. Launch / 启动

2026-11-23 已在 fork 新目录重新安装五组构建；旧目录的 2026-11-19 启动器保留为历史。直接双击 `E:\Enter-The-Nyangeon-ETNDoom\tests\m1_manual\启动M1人工验证.cmd`，选择纯Doom、DSS E2、DSS E4、自制跳跃或Doom II。统一索引为 [本地人工入口](../../../tests/m1_manual/README.md)，每个入口使用独立用户目录。

需要重新生成时，在 `E:\Enter-The-Nyangeon-ETNDoom` 打开PowerShell，先构建再选择入口：

```powershell
py -3 etndoom_mod/build_native.py --all
py -3 etndoom_mod/build_m1.py
py -3 tests/run_m1_manual.py --resource doom
py -3 tests/run_m1_manual.py --resource dss --episode 2
py -3 tests/run_m1_manual.py --resource dss --episode 4
py -3 tests/run_m1_manual.py --resource fixture --jump
py -3 tests/run_m1_manual.py --resource doom2
```

上述Python命令每次启动会在 `tests/m1_manual/<时间_资源_编号>/` 创建隔离用户目录，通过真实发布版安装 `etndoom_mod/build/m1/etndoom_m1.zip`，核验安装完成票据后再启动。目录中的 `启动人工验证.ps1` 可以重复打开同一隔离用户目录并继续读取已保存槽位。`--prepare-only` 仅完成安装与启动器生成；`--skill 1..5`、`--episode 1..4`、`--map` 选择起始难度/地图。DSS 默认 E2M1，正常加载仅 `doom.wad + DSS.wad`，不加载外部 `DSS.deh`。

原生存档严格绑定构建和资源内容；重新编译得到不同核心身份后，旧构建存档会明确拒绝。验证跨进程读取时应使用同一个生成的启动器和同一构建。

## 2. Controls / 操作

| 输入 | 行为 |
|---|---|
| W/S、A/D | 前后移动、左右横移 |
| ←/→、Shift | 转向、跑步 |
| Ctrl 或画面内鼠标左键 | 开火 |
| E、1–7 | 使用机关、切换武器 |
| Space | 配置启用时执行 Crispy 原生跳跃 |
| Esc | 切换手动暂停；聚焦只解除失焦暂停 |
| F5 | 由内核重开当前图 |
| F6 / F7 | 保存 / 读取当前选择槽位（1–8） |
| Enter | 死亡时重生，结算/结束时确认 |
| “新游戏” | 选择难度、episode/map 后开始新游戏 |
| F10 / F9 | 返回 ETN / 从保留的 ETN 菜单重新进入 |

保存仅接受有效关卡中的存活玩家。暂停时可保存、读取、重开与返回。流程请求失败会显示原因；确认请求遵循上游统计阶段，可能需要在统计推进后再次确认。

## 3. Checklist / 检查与记录

每个资源组合分别记录构建 ID、地图、难度、跳跃配置、启动器路径及观察结果。

- [ ] 画面/HUD 清晰，地图与资源符合预期；DSS 实际进入 E2/E4 替换图。
- [ ] 移动、武器、拾取、钥匙门、升降台及其它地图机关正常。
- [ ] 死亡重生、重开本图、新游戏语义正确；普通/秘密出口与后续地图由实际出口触发。
- [ ] 结算统计、确认与结束画面可继续或返回。
- [ ] 手动暂停后失焦/聚焦仍保持手动暂停；恢复不重放移动或开火。
- [ ] 战斗/机关运动中保存，继续后读取，状态与流程正确；关闭游戏后由同一启动器读取。
- [ ] 枪声、怪物、机关及音乐实际可听；暂停停止、恢复继续，换图/读档无旧声残留。
- [ ] 返回 ETN 后场景、鼠标、音频恢复；F9 再进入无 DSS 补丁或旧输入污染。
- [ ] 对失败提示、操作手感及声音体验给出用户结论，附截图/日志位置。

M1 沿用原版软件画面；最终俯视表现属于 M2。本清单不能用 M0 的人工通过代签。

## 4. Prepared Build / 本次已准备构建

当前构建 ID：`8a6171635beb851493d9`。核心 SHA-256：`0d0db6de55a422186ff28457269eb8d365842de614e29ad20453dc13e0988f26`。完整ZIP/DLL哈希、每项安装目录与启动命令记录在本地 `tests/m1_manual/current_entries.json` 及各目录`launch.json`；自动交付索引为`tests/m1_results/final_delivery_20261119/delivery.json`。

同一次人工验证请使用该索引指向的入口。更早的隔离目录保留历史测试和存档，不自动清理；更新构建后若旧核心存档被拒绝属于严格身份校验，不能改头部绕过。没有保存用户人工验收结论，也没有自动修改工作日志。
