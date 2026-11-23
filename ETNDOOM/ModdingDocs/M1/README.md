# M1 Development Detail / M1 完整内核移植细化

> Date / 日期：2026-11-22（用户确认阶段状态与 Rev 提交；自动回归交付于 2026-11-19）。
> Status / 状态：**阶段1（M1）实现完成，但验收未完成**（2026-11-22，来源：user）。自动回归已通过，人工验收待完成。采用独立 `etndoom_m1` / ABI 2，原版软件画面。实际实现见桥接 §8、流程/存档 §8、平台/音频 §7及数据格式文档；自动证据与覆盖边界见 [M1_VALIDATION.md](M1_VALIDATION.md)。SUPERSEDED: 2026-11-18/19 的“仅设计、尚未实施”状态；M0 人工通过不替代 M1 人工验收。
> Source / 来源：user（M0 完成后细化 M1、既有选型和阶段边界）；code（本仓 M0 实现、固定 Crispy 源码包）；test（本地自动回归与独立参考）；下文保留设计目标和实施前起点，实际接口与结果以新增实施章节为准。
> Baseline / 基线：本仓 `980e5a1851148d6d2dcd5339228cb3f9ae1fab8a`；Crispy Doom 7.2-1，commit `35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2`。正式构建输入为本仓 `etndoom_mod/vendor/crispy-doom-35b49519.tar.gz`，其它源码目录只作研究参照。
> Parent / 上位文档：[开发路线](../DOOM_PORT_DEVELOPMENT_ROADMAP.md) §5 的 M1.1–M1.6；已实现边界见 [M0 总览](../M0/README.md)、[M0 桥接 §11](../M0/M0_BRIDGE_CONTRACT.md#11-implemented-v0--m0-实际接口冻结2026-11-17)。本目录中的建议不替代既有用户裁定。

> Approved Resources / 新增许可（2026-11-19，来源：user）：M1 必须分别回归 `doom.wad`（The Ultimate Doom）单独运行，以及 `doom.wad` 作为 IWAD 加载 `dss/DSS.wad`（Dead Sea Scolls）正常运行。DSS 使用 Crispy 默认读取的内嵌 DEHACKED，外部 `DSS.deh` 仅供参考、正常情况下不加载。完整路径/身份/验收见 [M1 验收 §2.1](M1_VALIDATION.md#21-approved-additions--m1-新增获准资源2026-11-19)。SUPERSEDED: 初稿“Doom/第三方样本尚未落实”的状态；两个组合已实际回归，详见验收证据。

## 1. Goal / 阶段目标

在真实 ETN 发布版中，使用已选 Crispy 内核完成**可驱动、可观察、可恢复的完整单人运行时**：新游戏、移动与战斗、机关与拾取、死亡重开、普通/秘密出口、跨图、结算/结束、暂停、存读档、返回 ETN 与再次进入。M1 交付还须有供 M2 消费的地图、实体、资源、流程及音频接口。

M1 沿用原版软件画面和必要诊断控制面进行验证。上游玩法已经随源码编译进入 M0，工作重点是接通宿主缺失路径、补全状态与生命周期并证明继承成立，不能把每种怪物或机关当作待重写的算法。

| 范围 | M1 处置 |
|---|---|
| Windows x64、真实 ETN 发布版、Godot 4.7.2 | 沿用 M0 构建锁与安装链；其它平台不由此推定通过 |
| 首个后端 | 继续 Crispy，不预建多后端注册框架；长期 GZDoom/UZDoom 与已移植端口切换目标不变 |
| 原规则与原生跳跃 | 原规则配置、原生 jump 配置分别验证；不接入旧 ETN 运动/伤害求解器 |
| 必需资源、声音与音乐 | 接通获准资源的数据与实际播放；必要文件错误、中文/空格路径在 M1 验证 |
| 最终俯视、Momoi、动态 mesh、鼠标俯视操作 | M2；M1 提供真实数据与失效语义，不在这里实现最终表现 |
| D08 通用资源装载、选文件/排序界面、ETNINFO | 全项 B2/M3；M1 存档的最小资源身份校验不恢复旧 D08 全套契约 |
| ETN 三维攻击、近战、跳跃姿态/光环/烟尘等 | M3；Source Port 已有跳跃声音仍属于原生音频继承 |
| Boom/MBF21、网络、demo 产品能力、跨端口存档 | 本阶段不承诺；上游存在代码不等于项目已支持 |
| G1 组合发布授权 | 继续待裁定；本地技术工作可继续，不能据 M1 技术完成宣布正式组合可发布 |

## 2. Navigation / 阅读顺序与文档职责

| 文档 | 解决的问题 |
|---|---|
| [M1_IMPLEMENTATION_PLAN.md](M1_IMPLEMENTATION_PLAN.md) | M0 差距、M1.1–M1.6 任务、改动落点、依赖和分批交付 |
| [M1_BRIDGE_CONTRACT.md](M1_BRIDGE_CONTRACT.md) | 命令/流程分离、完整数据、稳定身份、事件、内存及错误边界 |
| [M1_FLOW_AND_SAVE.md](M1_FLOW_AND_SAVE.md) | 新游戏到结束、暂停控制、同图重建、存档封套与确定性续跑 |
| [M1_PLATFORM_AND_AUDIO.md](M1_PLATFORM_AND_AUDIO.md) | 文件/资源/时钟/退出、音频实现选择和 DLL 清理 |
| [M1_VALIDATION.md](M1_VALIDATION.md) | 获准样本边界、自动/人工矩阵、参考构建、验收门槛与证据模板 |

执行前按任务查阅本体 `docs/` 与 `ETNDOOM/` 同名增量；完整模块来源继续查 [R01–R15 源码审计](../M0/M0_SOURCE_AUDIT.md)，不复制一份会漂移的全量审计表。

## 3. Starting Point / 实施前已有成果与缺口（历史）

| 项目 | 当前事实 | M1 要补齐 |
|---|---|---|
| 加载/建销 | ZIP/PCK/GDExtension 与内核 DLL 已验收；每会话加载内核，销毁后卸载 | 新 ABI/依赖/失败路径重验；沿用原结构，不重复选型 |
| 运行 | 35 tic/s，`M_Ticker → RunTic → G_Ticker`，原生跳跃与短移动差分通过 | 代表性战斗/机关/完整流程对照 |
| 快照 | 玩家最小字段、RNG、实体数量、sector；完整实体列表未导出 | 实体/关系、玩家 HUD、动态 side、流程状态、资源与音频 |
| 重开 | 当前按钮销毁会话后从 MAP01 新开 | 区分新游戏、死亡重生、当前图重建、读档；保留上游进度语义 |
| 世界代次 | 当前由地图标识变化或 `leveltime` 回落推测 | 由实际世界重建钩子明确触发；同图读档也失效旧引用 |
| 存档 | 内核包含上游保存实现，但无公开存读档 API | 接通请求执行、隔离槽位、事务写入、身份校验和至少 350 tic 续跑对照 |
| 音频 | `-nosound`、禁用 SDL_mixer，`build_info.audio=false` | 实际声音/音乐、更新时序、暂停/退出清理；不能只把开关改为 true |

以上是M0实施前基线，不描述当前M1缺口。历史证据入口：`etndoom_mod/native/m0_core.c:30,41,62`；`native/m0_observer.c:17,30`；`m0/session.gd:43,158,198`；`m0/screen.gd:173`；`native/CMakeLists.txt:6,12`（后续路径均相对于 `etndoom_mod/`）。

## 4. Delivery Order / 推荐执行顺序

1. **A：固定起点并打通流程控制**。承接 M0，建立 M1 构建身份/本地证据目录；先修完整 gamestate 观察、显式世界代次和流程请求执行，保留软件画面。
2. **B：完成一条可操作流程**。在已获准用途内接通新游戏、死亡重开、暂停、返回；继续接普通出口、结算确认与跨图。缺少可用样本时登记缺口，不伪造过关。
3. **C：补齐玩法观察与媒体**。实体/动态地图/资源导出与音频接入，逐项验证代表性战斗/机关；不要等最终俯视才首次验证。
4. **D：存档恢复与特殊流程**。完成封套、恢复状态审计、续跑对照、秘密出口与结束；对输入/事件/声音清理统一收口。
5. **E：真实发布版收口并交接 M2**。重复建销、安装更新、失败返回、人工完整流程及全量数据消费验证；附证据和未覆盖范围。

以上为工作依赖，不表示并行启动多个代理或同时运行隔离测试。复用同一隔离工程的测试监督器按项目约定串行运行。

## 5. Completion / 完成判据与待明确项

**M1 完成**必须同时满足 [验收文档 §6](M1_VALIDATION.md#6-gates--阶段出门门槛) 的 M1-G1–M1-G6：核心单人流程无关键空实现，接口可消费，原规则代表用例有证据，存读档续跑通过，音频可用，退出/重进与真实宿主人工验收通过。缺少关键流程样本或只实现 API 均不能标为已完成。

当前既有加载许可不重复申请；新增 WAD、受控派生文件或扩大自动玩法用途，在相关测试执行前补齐明确许可。已知缺口：现存自制 `MAP01.wad` 的 M0 初态仅有玩家；MAP02/NoBorder 等历史样本当前不在 `etndoom_mod/wad/`，不能写成可直接执行的回归。详见验收样本表。

实施前待明确项及当前落点：

| 项目 | 当前建议/已知边界 | 最迟处理点 |
|---|---|---|
| 代表性战斗/机关/流程的自动样本 | Doom/DSS 正常运行回归已获准，先从中落实具体覆盖；其它新增样本另落实 | 执行对应测试前 |
| Doom、第三方与扩展特征实测 | Doom/DSS 两种组合为必须回归项；DSS 的超限/节点特征待核实，不能预设其类别或从 Doom II 外推 | 宣布相应支持范围前 |
| 音频具体后端 | 已冻结 SDL_mixer 2.8.1 + OPL2，保留原生选声/音乐 | 见平台/音频 §7 |
| 存档缺失状态 | 已补 RNG、定点精度、thinker/碰撞链次序、按钮/机关及可变难度表 | 见流程/存档 §8及续跑证据 |
| ABI、槽位数、字节容量 | ABI2、8槽、单读1MiB、原生8192事件、宿主256事件 | 见桥接 §8 |
| 正式组合发布授权 | G1 待裁定，不改变本地技术推进 | 正式发布前 |

阶段成果按“设计 / 实现 / 自动 / 真实发布版人工”分别更新。2026-11-18 仅形成设计文档，未追加 `WORKLOG.md`；2026-11-19 新增资源许可属于用户明确修订，按项目约定另记 Correction。SUPERSEDED: 此前“尚未运行”的历史状态；2026-11-19 已实施并执行自动回归，当时未提交或推送。2026-11-22 用户确认阶段1（M1）实现完成、验收未完成，并要求将实现与文档作为一个 Commit 提交至 `Rev`；人工验收仍待完成，推送由用户执行。

## 6. Working Entry / 当前可运行入口

```powershell
py -3 etndoom_mod/build_native.py --all
py -3 etndoom_mod/build_m1.py
py -3 tests/run_m1_checks.py --zip-b etndoom_mod/build/m1_update/etndoom_m1.zip
py -3 tests/run_m1_negative_checks.py
py -3 tests/run_m1_manual.py --resource doom
py -3 tests/run_m1_manual.py --resource dss --episode 2
```

上面的更新回归要求先用 `build_m1.py --output etndoom_mod/build/m1_update --build-id <另一构建ID>` 生成更新测试包。人工入口及控制详见 [M1_MANUAL_VALIDATION.md](M1_MANUAL_VALIDATION.md)。`tests/` 的脚本、截图、公开输入、存档和逐tic原始证据全部为本地回归文件，不进入Git。M1 ZIP不包含WAD；DSS只使用内嵌DEHACKED。

M2消费入口为 [M1_DATA_SCHEMA.md](M1_DATA_SCHEMA.md)：地图BSP/拓扑、实体/引用、动态机关、最终资源目录及有界lump读取均来自内核。最终俯视与Momoi表现仍归M2，通用资源选择界面归M3；本次没有恢复旧ETN玩法求解器。
