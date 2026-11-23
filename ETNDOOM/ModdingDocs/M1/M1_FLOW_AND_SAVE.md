# M1 Flow and Save / M1 完整流程与存读档

> Date / 日期：2026-11-19。
> Status / 状态：ABI 2 流程控制与存档封套已实现，最终存档/控制专项已通过，见 §8.3；完整阶段由统一验收记录收口，**人工尚未验收**。SUPERSEDED: 2026-11-18 的全项待实施状态；下文原设计保留，实际接口以 §8 为准。
> Source / 来源：code（固定 Crispy 的 `g_game/wi_stuff/f_finale/p_saveg/p_extsaveg` 及 M0 包装）；控制面和封套为设计建议。
> Navigation / 导航：[M1 总览](README.md)、[桥接](M1_BRIDGE_CONTRACT.md)、[验收](M1_VALIDATION.md)。下文 `src/` 锚点对应本仓 vendor 包中的固定 Crispy commit。

## 1. Flow States / 两套状态分别表达

桥接生命周期使用 `READY → CREATING → ACTIVE → CLOSING → READY`，污染会话进入 `FAILED`；宿主暂停是 ACTIVE 的原因集合，不与内核 `gamestate` 混为一谈。内核仍持有 `GS_LEVEL/GS_INTERMISSION/GS_FINALE/GS_DEMOSCREEN` 与 `gameaction`。

| 流程 | 必须保留/对接的行为 | 完成观察 |
|---|---|---|
| 新游戏 | 显式难度、起始图、规则配置，经内核初始化；最小入口可继续直接开局 | 实际 skill/map/episode、玩家初态及新世界代次 |
| 死亡/重生 | 上游 playerstate、死亡视角/计时、合法 use 等输入及 `G_DoReborn` 路径 | 死亡状态、实际重建和恢复初态；不能靠关闭 DLL 代替这一测试 |
| 主动重开 | 明确“重新开始整局”与“重开当前关卡”的语义 | 使用上游相应新游戏/重生路径；携带/清空项目有记录，不手填 health/ammo |
| 普通出口 | 由真实特殊线/动作触发 `G_ExitLevel` 等路径 | completed、统计、结算、下一图与跨图携带 |
| 秘密出口 | 由内核确定秘密路线和之后返回路线 | 秘密标志、实际目标图、后续路线；不能用调试跳图替代 |
| 结算 | `WI_Start/WI_Ticker` 的统计/计时/确认 | 在对应阶段确认生效；同次按键不能连跳两阶段 |
| 结束 | `F_StartFinale/F_Ticker/F_Responder` 等对应游戏模式逻辑 | 文本/演示/结束状态可观察、必要输入有效、返回 ETN 可用 |
| 暂停/失焦 | 宿主停止模拟时钟，媒体暂停，控制面继续工作 | 恢复不追赶暂停 wall time、不重放按键 |
| 返回与再进入 | 有效或 FAILED 会话均可关闭，按所有权恢复 ETN | 鼠标、音频、场景与输入恢复，再建会话等价新初态 |

M0 `screen.gd:173` 的按钮执行 close→create，从固定 MAP01 新开；这只证明完整会话重建。M1 中应为用户明确区分整局重新开始和当前关卡死亡重开。

非关卡流程需要独立快照：不存在有效玩家实体或地图时仍能显示状态与可用动作。保留原版 framebuffer/HUD/结算画面；新增必要按钮/状态文字即可，不把重做全部菜单或中文化上游画面设为 M1 门槛。

## 2. Control Actions / 流程请求与输入路由

每个请求携带唯一 `request_id`、当前 session/world 身份及动作参数。接受不等于完成；在安全边界执行并给出最终状态。新游戏、读档、重开等会替换世界的请求互斥，前一个未决时拒绝冲突请求；关闭始终可中止并清理。

| 操作 | LEVEL 活跃 | LEVEL 宿主暂停 | INTERMISSION / FINALE | FAILED / 无会话 |
|---|---|---|---|---|
| gameplay 命令 | 按内核状态处理 | 不消费 | 只允许映射为上游所需确认/动作的输入 | 拒绝 |
| 结算/结束确认 | 不适用 | 不适用 | 走该状态真实输入路径，仍服从宿主暂停 | 拒绝 |
| 保存 | 活着、有效世界、无换图请求时接受 | 同条件，在控制边界完成 | 首版拒绝并说明；不产生不可恢复的流程档 | 拒绝 |
| 读取合法槽位 | 接受并串行替换 | 可执行，完成后保持原宿主暂停原因 | 允许回到所存关卡 | FAILED 先关闭并新建；无会话可建会话后加载 |
| 新游戏/主动重开 | 明确参数并串行执行 | 可执行，暂停原因按约定保留 | 可开始新游戏；当前图重开仅在仍有明确有效目标时开放 | FAILED 先关闭；READY 可创建 |
| 返回/关闭 | 可执行 | 可执行 | 可执行 | 可执行、幂等 |

建议首版仅保存有效 LEVEL 中存活玩家，保留活跃敌人/弹射物/机关；死后、装图中和结算档不支持时必须明确提示，不能悄悄存出另一状态。这是 M1 建议的保存入口范围，未被用户确认为永久产品限制。

控制泵不依赖实时 gameplay step：暂停时也必须能保存、加载、关闭和解除暂停。建议在完整 tic 之后、下一 tic 之前处理控制事务，复用原生保存/读取函数及其状态机职责，防止为了执行保存偷偷跑一帧 AI。具体切口先通过窄探针核实，不能直接调用缺少前置条件的内部函数。

**保存请求的已知陷阱**：`src/doom/g_game.c:2579` 的 `G_SaveGame()` 仅写槽位/描述并设 `sendsave=true`；该标志在 `G_BuildTiccmd` 的 `:944` 转成特殊按钮。当前 `native/m0_core.c:62` 直接构造命令并调用 RunTic，且 `buttons` 仅允许 0..127。因此 M1 不能只导出 `G_SaveGame` 就宣布接通保存。须显式桥接请求消费/保存调度并验证完成通知；也不能粗暴放宽所有按钮位，令普通 gameplay 输入绕过控制面校验。

最终画面/菜单确认按实际 responder 或 ticcmd 路径路由；不能假定所有阶段的 Enter、fire、use 都等价。游戏内 `paused` 如被保留，由适配器统一协调并在快照中可见，避免“宿主已恢复、内核仍暂停”的双状态。

## 3. Pause and World Changes / 暂停与世界重建

暂停原因至少区分 `user/focus/operation/overload`。失焦后重新聚焦只撤销 focus 原因，不自动撤销用户暂停；超限暂停沿用 M0 的重开/返回策略，不通过普通继续丢弃欠账。

正常暂停清持有按键、一次性武器/确认请求和实时输入队列，重置 wall-time 基准。保存/读档期间阻止新 gameplay 输入；事务完成后按原有宿主暂停原因恢复。菜单和退出不受 `SceneTree.paused/Engine.time_scale` 阻断。

世界重建从内核实际装图/恢复完成处显式通知：新地图、同图死亡重建、同图主动重开、同图读档均更新 world_epoch。M0 `session.gd:158` 的地图名/leveltime 观测只保留作诊断交叉检查，不能作为唯一来源。

在重建边界：停止当批 tic → 清旧输入与旧世界待处理请求 → 停旧声音与失效事件/句柄 → 发布新代次和完整快照 → 允许新输入。宿主输出序号保持单调；core tic/leveltime 的恢复值另行记录。存档中不持久化旧 session/world 身份供恢复后复用。

## 4. Save Envelope / 独立存档封套

采用上游基础/扩展载荷，加 ETNDOOM 独立封套和经审计的补充状态；不序列化 Godot 镜像替代内核归档。目录放在该 Mod 的隔离 `user://` 下，不能写入本体 `PlayerData.res`、`config.ini` 或用户独立 Crispy 配置目录。

| 字段组 | 建议内容与校验 |
|---|---|
| 容器 | magic、schema、各段长度/哈希；限制总尺寸与声明长度，先校验再分配/调用内核 |
| 内核 | Crispy commit、修改补丁/规则身份、ABI/存档扩展 schema；默认严格匹配 |
| 资源 | 有序文件内容哈希、角色及实际解析配置；路径只用于定位提示，不决定内容相同 |
| 游戏 | game mode、episode/map、skill、jump 与其它影响规则的配置 |
| 上游载荷 | 基础 savegame 与扩展信息完整保留，明确格式/长度 |
| 补充状态 | RNG、时钟/调度及其它实际缺失状态，按 §5 审计后写入；不先假定只有 RNG |
| 描述 | 槽位、用户可见描述、创建时间；UTF-8 长度明确，适配上游短描述限制 |

存档资源身份是防止载错文件的最小保护，不能扩成 D08 的通用资源发现/ETNINFO 产品功能。跨端口、跨规则或跨资源默认拒绝；若后来支持迁移，另立迁移版本和验证矩阵，不自动忽略不匹配。

## 5. Restore Audit / 确定性恢复审计

已确认：上游 `G_DoLoadGame` 经 `G_InitNew` 清 RNG，而 `p_extsaveg.c:469` 的扩展表未保存三组 RNG 索引，见 [M0 源码审计 §3](../M0/M0_SOURCE_AUDIT.md#3-save-identity--存档审计结论与-m1-实现要求)。其余项目当前是**审计清单，不是已确认缺失字段**：

| 状态类别 | 审计与恢复要求 |
|---|---|
| RNG | `rndindex/prndindex/crndindex` 逐项保存；装图/恢复中的随机调用结束后，在继续模拟前恢复正确边界值 |
| 时钟/调度 | gametic/leveltime/total time、与模运算有关的相位、未决 gameaction；区分持久模拟值与宿主队列序号 |
| 玩家 | 武器 psprite、弹药/钥匙/powerup、计时、输入锁存如 attack/use；回放后续命令时不能莫名重触发 |
| thinkers/实体 | 创建/遍历次序、state/tics、动量/追踪与 target/tracer；用保存期序号映射，禁止持久化地址 |
| specials/世界 | 门/平台/压碎机/灯光、按钮计时、sector soundtarget、贴图动画和计时；非 mobj thinkers 必须纳入 |
| 配置/扩展 | skill、jump/critical 配置、Crispy 扩展归档、MUSINFO 等会影响续跑的状态 |
| 观察/音频 | 恢复后重新分配观察 ID、建立旧载荷序号→新实体映射；旧播放实例失效，音乐/持续声按状态重建 |

每一项最终记录“上游已保存 / 封套补足 / 无需持久化并给原因”，附函数锚点和用例。恢复后的 ID 允许不同，但引用关系、thinker 次序与模拟状态必须可规范化比较。无法满足等价续跑的缺口仍归 M1，不用“原版也这样”把既定验收移走。

## 6. Transactions / 保存与读取事务

**保存**：锁定 tic 边界和身份 → 在独立暂存路径生成上游载荷与补充状态 → 验证所有段和哈希 → 写完临时容器并关闭句柄 → 同目录原子替换槽位 → 返回 completed。只有最后一步成功才显示保存成功。单容器是优先方案；采用 sidecar 时必须有提交清单，避免新载荷配旧封套。

上游 `G_DoSaveGame` 自带临时文件/恢复路径，M1 要把这些路径限制在模组隔离目录并审计其失败回退；不能假定它自动完成外层封套的原子提交。权限/磁盘/替换失败保留旧有效槽位，清理本事务临时文件时不得误删其它槽位。

**读取**：读取并校验封套/身份/长度/哈希 → 拒绝时保持当前世界 → 进入不可并发的恢复事务 → 调上游装图/反序列化/引用修复 → 恢复补充状态 → 提交新 world_epoch、全量快照和媒体重建 → 返回 completed。预检成功不保证原生恢复必成功；若恢复中出错且不能回滚，标 FAILED，提供关闭/重进，不继续半恢复世界。

当前单内核会话结构不预建第二份世界用于事务回滚。保存读取不会绕过既有 WAD 许可；缺资源时提示具体缺项，不自动搜索其它文件顶替。

## 7. Continuation Proof / 续跑验证

每个获准确定性用例在同一 tic 边界分为：A 不保存不中断；B 保存后继续；C 保存→同会话读取→继续；D 保存→销毁/重建会话→读取→继续。四条支路执行相同后续命令，至少 **350 tic**，同时比较保存动作本身是否扰动 A/B。

比较玩家/武器/物品、thinker 与 specials、动态世界、三组 RNG、流程及语义事件序列；规范化 session/world/entity 观察身份，不忽略真实引用或事件时序。音频设备波形/播放进度不要求样本级一致，逻辑选声、停止、音乐切换与影响 RNG 的决策仍应按冻结配置一致。

至少覆盖静止、战斗中、机关运动中、临近出口四类保存点；同图恢复只比初帧不算通过。现有样本不足时保持对应项待样本，不虚构运行结果。

## 8. Implemented ABI 2 / 实际控制与存档（2026-11-19）

Source / 来源：code（本节接口与审计）、test（本地 `tests/m1_results/save/summary.json` 首轮结果）。这些是实现/自动证据，不代表人工体验通过。

- `native/m0_core.h` 保留历史文件名并提升 `abi=2`；`m1_create(iwad,pwad,savedir,skill,episode,map,jump)` 中 `episode=0` 表示 Doom II，`1..4` 表示 Doom 章节。创建后复核真实 `gamemode/episode/map`，允许已获准 PWAD 的内嵌 DEHACKED；不添加外部 DEH 参数。
- `native/m0_core.c:m1_control` 接受 `new_game(skill,episode,map)`、`restart_level`、`reborn`、`pause(bool)`、`save(slot)`、`load(slot)`、`confirm`。请求 ID 使用单调 `uint64`，JSON 中为十进制字符串；重复 ID 拒绝。除确认输入外，控制调用在同一安全边界返回最终结果，不隐式推进 `gametic/leveltime`。
- `confirm` 在 INTERMISSION/FINALE 走真实上游输入，返回 `accepted=true, completed=false, queued=true`；下一正常 tic 消费后，`m1_control_status()` / 快照 `control` 更新为 `completed=true`。暂停或换世界取消待确认输入时返回 `cancelled_request_id`。暂停原因集合仍由宿主保存，核心只接收聚合暂停状态。
- 宿主换世界先发布 `world_changed`，再发布带原请求 ID 的 `request_cancelled`，最后发布本次操作完成，避免取消通知被旧世界队列清理吞掉。实际 E1M1 正常退出至结算后，确认排队→读取先前存档已验证返回字段及取消事件顺序；本地证据 `tests/m1_results/cancel_after_world_final_20261119.json`。
- `restart_level` 与 `reborn` 经 `G_DoReborn → G_DoLoadLevel`，后者要求玩家已死亡。`new_game` 经 `G_DeferedInitNew → G_DoNewGame`。它们均不卸载 DLL；与整会话关闭后再进入分开验证。
- 世界代次由 `P_SetupLevel` 的真实 begin/commit 钩子发布；读档在外层包裹嵌套事务，等上游装图、归档恢复、补充状态恢复都结束后一次提交。旧输入/事件/观察 ID 由宿主和观察器按重建边界清理。

### 8.1 Container and Transaction / 容器与事务

实现入口为 `native/m1_save.c:65,199,216`。槽位为 `0..7`，文件名 `m1-slot-N.etns`，位于调用方指定的 Mod 隔离存档目录。单容器使用 `ETNM1SV` magic、schema 1、固定头长度、原生载荷长度、补充段长度及整容器 SHA-256；总尺寸上限 64 MiB，thinker 补充上限 100,000。

身份包括 IWAD/PWAD **有序内容 SHA-256**、当前核心 DLL SHA-256 与 jump 规则。即使路径变了，只要获准资源内容顺序一致仍可定位；不同核心二进制、资源内容/顺序或规则严格拒绝。补充段结构采用当前 Windows x64 ABI 布局，因此不声明跨构建/平台可移植，DLL 哈希是强制校验。

保存直接调用 `P_WriteSaveGameHeader → P_ArchivePlayers/World/Thinkers/Specials → P_WriteSaveGameEOF → P_WriteExtendedSaveGameData`，不经过 `G_SaveGame` 的 `sendsave` 输入路径，也不让 `G_DoSaveGame` 修改玩家提示或上游快速存档名。原生载荷先写同隔离目录事务文件；封套写到同目录 `.tmp`，关闭/校验写入状态后使用 `MoveFileExW(REPLACE_EXISTING|WRITE_THROUGH)` 原子替换目标。写入或替换失败保留原有槽位。

加载在修改世界前核验 magic/schema/长度/hash、资源/核心/规则身份、原生头版本/单人配置/地图存在性、补充段大小及全部补充引用索引。损坏或不匹配只返回拒绝。通过后才写隔离原生载荷并调用 `G_DoLoadGame`；恢复阶段错误由原生恢复边界标记会话失败，不继续半恢复世界。未自动搜索替代 WAD。

### 8.2 Restore Audit / 实际恢复审计

| 状态 | 原生载荷职责 | M1 补充与原因 |
|---|---|---|
| RNG/时钟 | 原生保存 24 位 leveltime、扩展保存 totalleveltimes | 补三组 RNG、完整 gametic/leveltime/totalleveltimes、demostarttic、oldleveltime 与 validcount，见 `m1_save.c:capture/restore` |
| 玩家 | 武器、弹药、护甲、钥匙、powerup、psprites、attack/use/refire 等原字段 | 补完整 Crispy player 扩展，包括 jumpTics、btuse/btuse_tics、bob2、负生命、视角/反冲等；mo/attacker/psprite state 用索引重建，声音源使用新世界对象 |
| mobj | 位置/动量/state/tics、target/tracer 与基础规则字段 | 补原生未归档的插值字段，并恢复 sector/block 链的实际顺序；持久化引用使用索引，不保存可复用的旧指针 |
| thinkers | 按 mobj 与 specials 分组归档 | 补原始 thinker 全局遍历顺序、活动 ceiling/plat 数组位置；不让读档的分组顺序改变下一 tic 执行顺序 |
| sector/side/line | 基础几何动态值、动作、材质、扩展 soundtarget/oldspecial | 原生将高度和 offset 右移 FRACBITS 后写 16 位；M1 补完整定点高度/偏移、动态字段、soundtraversed/validcount、thinglist/specialdata 与动画 translation 表 |
| specials | 门、地板、平台、压碎机、闪灯/strobe/glow；扩展保存 fire flicker | 保留上游每类序列化、对象创建与引用修复；补 thinker 顺序。未知活动 thinker 明确拒绝保存，不静默遗漏 |
| buttons / Brain | 扩展保存按钮 line/where/texture/timer 与 Brain 序号/目标 | M1 补 buttonlist 的完整槽位/空洞顺序和声音原点索引，避免原生恢复压紧数组影响未来空槽分配；另补 `A_BrainSpit` 的 easy 相位，保留低难度产怪节拍 |
| MUSINFO | 扩展记录当前曲目 | 补 mapthing/lastmapthing 的对象索引、tics、完整 items/current_item 与 from_savegame |
| 跨图流程 | 当前关卡的规则计数由装图/扩展载荷恢复 | 补 `wminfo` 上一次结算数据，使跨图后的同/跨会话读档保留一致流程快照；仅允许 LEVEL 存档，未保存进行中的结算状态机 |
| 可变规则表 | `G_InitNew` 按难度设置 Nightmare/fast 配置 | 补 `S_SARG_RUN1..S_SARG_PAIN2` 的实际 tics 与三种弹射物速度；避免保存后先切 Nightmare 再读档时，上游整数位移还原丢失 DEH 奇数/1tic 的原值。正常新游戏规则仍使用上游原路径 |
| 提示/界面缓存 | 状态栏由 `ST_Start/HU_Start` 重建 | 玩家 `message/centermessage` 为瞬时 UI 字符串，不持久化旧指针；它们不参与玩法求解。宿主输入、观察 ID、wall-time 欠账、音频设备播放进度不恢复旧实例 |

原生载荷与补充都是从当前真实内核状态取得，未通过回放输入来伪造存档恢复。补充索引预检见 `m1_save.c:preflight`；存档有效状态限定为 LEVEL、`gameaction=ga_nothing` 且玩家存活。

### 8.3 Automatic Evidence / 自动证据

本地命令：`py -3 tests/m1_save_checks.py`。首轮 `tests/m1_results/save/summary.json` 中 `ok=true`，包含 fixture 原规则、fixture jump、纯 Doom E1M1、DSS E2M1、DSS E4M1 五组；每组分别运行 A 不保存、B 保存继续、C 同会话加载、D 销毁重建加载，**每条支路继续 350 tic**。除世界/观察身份与控制请求状态外，玩家、实体关系、动态世界、specials、RNG 和流程快照逐字段比较；实体引用必须存在，不能将未知非零 ID 归零掩盖差异。每个子进程销毁后跟踪分配归零。

首轮还验证中文/空格存档路径、暂停中的保存/加载不走 tic、损坏截断/hash 拒绝保持旧世界、临时写入失败保留旧档、同图重建。扩展反例以及最终固定绘图构建、自然机关运动/临近出口保存点在最终汇总中单列，不把首轮结果外推为未执行项通过。

**最终专项补充（2026-11-19）**：统一核心 SHA-256 为 `0d0db6de55a422186ff28457269eb8d365842de614e29ad20453dc13e0988f26`，测试从 `tests/m1_results/native_snapshots/20261119_162529_final3_783428` 的冻结 DLL 加载，不与构建并发覆盖。

| 专项证据 | 已执行结果 |
|---|---|
| `tests/m1_results/save_final2_20261119/summary.json` | `ok=true`；fixture纯静止、fixture原生跳跃、Doom E1M1战斗、DSS E2M1/E4M1五组 × A/B/C/D/E ×350 tic全部一致；E覆盖Nightmare难度往返恢复规则表。另13类反例覆盖损坏/截断/hash/schema/身份/长度/原生头/引用索引、写入与原子替换失败、重复控制请求 |
| `tests/m1_results/save_routes_final2_20261119/summary.json` | `ok=true`；真实 E1M1 输入路线的运动门 tic180、出口前 tic720、实际进入 E1M2 后 tic780，三个保存点分别 A/B/C/D ×350 tic 全状态一致；包含动态平台出现、真实结算与跨图 |
| `tests/m1_results/save_button_final2_20261119/summary.json` | `ok=true`；E1M1 真实 SR 按钮 tic140 保存，包含计时回弹；A/B/C/D 与新增 E（保存后先切 Nightmare 新游戏再加载）各350 tic 一致 |
| `tests/m1_results/control_final2_20261119/summary.json` | `ok=true`；真实死亡 tic779 后保存拒绝，暂停 reborn 恢复100生命且不增加 tic；真实结算 tic722 保存拒绝，confirm accepted→completed、暂停/读档取消确认均通过 |
| `tests/m1_results/lifecycle_final2_20261119/summary.json` | `ok=true`；同进程50次 DSS→纯 Doom 交替建销，完整初态/资源/规则表哈希各自稳定；所有销毁跟踪分配0，句柄增长0；末10次相对暖机中位工作集增加763,904字节，private commit增加1,966,080字节 |

运动机关首轮曾发现跨进程新建平台的 inactive `count` 导出随机内存值。该字段在 `status=down` 尚无规则含义，观察器现按真实状态输出 `valid_mask`，保留活动计数精确比较；原失败证据继续保留，最终上述运动路线已通过。音频 SR 按钮回弹对设备实际播放进度的依赖已由双方相同适配去除，详见平台/音频文档；不能通过忽略 RNG 消除差异。
