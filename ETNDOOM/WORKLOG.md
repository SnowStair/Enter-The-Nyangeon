> Current Workspace / 当前工作区（2026-11-23）：`E:\Enter-The-Nyangeon-ETNDoom` 的 `Rev` 分支；现行入口与迁移结果见 [MIGRATION.md](MIGRATION.md)。下方日期、路径及验证结果保留为历史证据。

> History / 历史迁移（2026-10-30）：ETNDOOM 当时开发根目录为 `E:\ETN_DOOM`。本文历史记录中的 `E:\Enter-The-Nyangeon` 路径保留作为当时证据；当时迁移报告见 [Legacy/MIGRATION.md](Legacy/MIGRATION.md)。

# Worklog / 改动记录

> Scope / 范围：保存 ETNDOOM 新增的本地改动记录，不复制 `docs/WORKLOG.md` 的完整历史。
> Maintenance / 维护：仅在用户敲定改动、明确要求记录或确认修正时追加，不自动逐次记录。
> Source / 来源：用户 2026-10-23 指定本地保存位置；2026-10-22 的 D04 条目承接自 `docs/WORKLOG.md` 的未提交新增内容。
> History / 历史说明：D04 条目中的 `docs/` 路径保留原记录含义；自 2026-10-23 起，对应新增内容保存在本目录同名文件。
>
> Entry format / 条目格式：
> ```
> ## YYYY-MM-DD — <title / 标题>
> - Files / 涉及文件: path, path
> - Summary / 改动摘要: ...
> - Reason / 原因: ...
> - Systems / 影响系统: ...
> - Docs synced / 文档同步: ...
> ```
> 用户修正记录使用 `Correction: <原结论> → <新结论>（来源：user）`。

## 2026-10-22 — 确认阶段 0 开发者入口 D04
- Correction: D04 仍并列考虑 Mod entry、独立调试脚本和场景切换 gate → 确认使用独立测试 Mod entry，D04 决策已完成（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 将 D04 移入已确认决策，明确安装启用后重启、entry 资源约定、`--stage0=0.1/0.2` 参数及异常处理、延迟切场景、日志验证、源码与导出运行命令，并同步实施闸门。
- Reason / 原因: 用户确认独立测试 Mod 入口方案，要求将前述讨论细节写入文档。
- Systems / 影响系统: 阶段 0 开发规划及入口验收约定；本次仅更新文档。
- Docs synced / 文档同步: 阶段 0 文档 §1、§3.1、§6、§7–9；`docs/LEARNINGS.md` 新增 D04 确认记录。D05–D10 及 Runtime 目录变化归因继续保留待确认。

## 2026-10-23 — 将 ETNDOOM 新增记录保存到本地同名文件
- Correction: ETNDOOM 新增经验与改动记录仅保存在 `docs/` → 保存到 `ETNDOOM/LEARNINGS.md` 和 `ETNDOOM/WORKLOG.md`，避免随远端更新被覆盖（来源：user）。
- Files / 涉及文件: `ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`。
- Summary / 改动摘要: 保存 Runtime 目录变化待确认、D04 入口确认、场景复用范围三条经验及 D04 确认记录，新增本地保存约定，并在阶段 0 文档中补充本地记录入口。
- Reason / 原因: 用户指出 `docs/` 下的修改会随远端更新被覆盖，明确要求在 `ETNDOOM` 下创建同名文件保存新增内容。
- Systems / 影响系统: ETNDOOM 本地知识库及改动记录。
- Docs synced / 文档同步: 本目录 `LEARNINGS.md`、`WORKLOG.md` 与阶段 0 开发细化文档。

## 2026-10-23 — 收窄阶段 0 场景节点复用讨论
- Correction: 原清单将 Momoi 子树列为优先讨论对象，并笼统排除原版滚动背景 → Momoi 有关节点退出当前讨论，特效/伤害跳字/光照/HUD 阶段 0 不引入，glow 与场外滚动背景按低成本条件继续评估（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_NODE_REUSE_CANDIDATES.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 核对纯色底、滚动 shader、静态渐变与场地图像的分工，补充 glow 和滚动背景的节点/资源规模，纠正 glow 等同于描边的旧说明；保留旧角色盘点为历史附录，记录用户对后续重新加入、DOOM 光照方向及 HUD 重做可能性的说明。
- Reason / 原因: 用户逐项补充阶段 0 需求，并要求复用判断关注节点数量与节点规模。
- Systems / 影响系统: 阶段 0 节点复用规划；仅更新文档，没有改动原版场景、脚本或项目设置。
- Docs synced / 文档同步: 本目录经验库、节点候选清单及开发细化文档 §7。D05 整体场景方案及两项候选是否启用仍待确认，C02 和 D06/D07 不在本次另行裁决。

## 2026-10-23 — 确认 D05 场景节点带入与不带入清单
- Correction: 全局泛光与场外滚动背景仅为候选、D05 仍待确认 → 两项均复用，接受其余场景节点取舍，D05 已决策；`ChipHud` 后续可重新加入或弃用重做 → 阶段 0 不引入，后续会加入并修改（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_NODE_REUSE_CANDIDATES.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 将候选表改为确认带入/不带入清单，确认 10 个场景节点及必要资源；无 HUD 需求对应的两个 `CanvasLayer` 归入不带入。D05 收束为重建独立测试场景、按清单复用部分节点与资源，并移入已确认决策、更新实施闸门；保留先前讨论及角色盘点历史。
- Reason / 原因: 用户明确要求将其余建议全部确认为节点取舍，只为必须由用户裁决的节点保留未决状态；核对后当前场景清单无此类遗留节点。
- Systems / 影响系统: 阶段 0 场景结构与表现规划、后续 `ChipHud` 接入方向；仅更新文档，没有开始功能实现。
- Docs synced / 文档同步: 节点清单 §1–§6、开发细化文档 §1–§2、§7–§8、本目录经验库。D06–D10 继续待确认，不将历史角色盘点升级为已批准方案。

## 2026-10-23 — 补充 D06 的 Momoi 玩家实体定位
- Correction: 角色复用仅表述为“外观资产和场景基础” → 明确阶段 0 复用 Momoi 玩家实体验证移动，包含实际位置、速度与物理移动能力；具体技术方式仍待确认（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_MOMOI_ANALYSIS.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 记录用户补充的实体定位，补充原版选角/生成、子状态机驱动、移动参数、碰撞与外观分工、根逻辑硬引用和全局信号依赖的代码分析。
- Reason / 原因: 用户要求围绕 D06 分析原游戏如何处理 Momoi。
- Systems / 影响系统: 阶段 0 角色复用规划；仅更新文档，未改动功能代码，未裁定 D06 或其余待决项。
- Docs synced / 文档同步: 开发细化文档 §1、§7、角色分析全文及本目录经验库。

## 2026-10-24 — 补充阶段 5/7 敌怪重做与实体管理范围
- Correction: 实体管理评估偏重接管和迁移原版实体的成本 → 阶段 5/7 敌怪为适配 DOOM 地图与逻辑必然大幅重做或新设计，无需以整体接管原版敌怪行为为目标，按此基准评估管理职责的增量成本（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/ENTITY_MANAGEMENT_RECOMMENDATION.md`、`ETNDOOM/ModdingDocs/ETN_ENTITY_MANAGEMENT.md`、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 将敌怪重做记为用户明确的设计前提，同步阶段 5 测试敌人和阶段 7 刷怪调度的范围；补充实际复用部分的隔离边界、素材按需复用及成本评估基准，保留旧讨论历史。
- Reason / 原因: 用户指出后续敌怪必需的重做使整体接管原版实体行为失去意义，要求补充到相关文档。
- Systems / 影响系统: 后续敌怪与实体管理架构评估；仅更新文档，未修改功能代码。
- Docs synced / 文档同步: 实体管理建议 §1.1、§6–§7，原版管理分析 §7，新模式草案 §1、§4.2 及本目录经验库。全面实体管理架构未裁定，阶段 0 的 Momoi 要求与 D06 状态不变。

## 2026-10-24 — 确认 D06 的 Momoi 实体接管方案
- Correction: D06 仅有入树前适配与模组自有最小根逻辑的推荐，采用待确认 → 用户确认全部建议为实际决策，D06 标记已决策并移入已确认决策（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_MOMOI_ANALYSIS.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_NODE_REUSE_CANDIDATES.md`、`ETNDOOM/ModdingDocs/ENTITY_MANAGEMENT_RECOMMENDATION.md`、`ETNDOOM/ModdingDocs/ETN_ENTITY_MANAGEMENT.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 确认固定实例化原 Momoi 场景，入树前处理旧信号、玩法子树和组，提取基础移动参数并由自有 `CharacterBody2D` 根逻辑控制同一物理体；明确移动基线、朝向、保留范围与碰撞切换。更新 Gate A 的 D06 状态及 MapBounds 隔离方式，将经验条目移入已确认记录，保留旧讨论与修正历史。
- Reason / 原因: 用户明确要求将上一轮建议落地为实际决策，并标记 D06 为已决策。
- Systems / 影响系统: 阶段 0 玩家复用与运行时隔离约束；仅更新文档，未修改功能代码或进行运行验收。
- Docs synced / 文档同步: 开发细化文档 §1、§3.2–§3.4、§7–§8，Momoi 分析 §6、§8.3，实体管理建议 §6–§7、原版管理分析 §7、场景节点清单及本目录记录。D07–D10 与全面实体管理架构仍未裁定。

## 2026-10-24 — 确认 D07 阶段 0 独立相机
- Correction: 阶段 0 相机复用方式仍待确认 → 确认由测试场景独立持有 `Camera2D`，不复用 Momoi 子树中的原版相机（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_NODE_REUSE_CANDIDATES.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_MOMOI_ANALYSIS.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 将 D07 移入已确认决策，规定相机显式跟随阶段 0 玩家、初始观察中心对应 D02 映射后的出生点，0.1/0.2 共用配置；不带入原版准星前导、偏移、镜头/震屏信号、黑幕遮罩或 `"PlayerCamera"` 组。补充原版相机信号连接、准星前导阈值与比例、独立震屏偏移、演出锁定/zoom、位置平滑及 Momoi 偏移的代码分析，并更新人工验收、自动断言和实施闸门状态。
- Reason / 原因: 用户依据 D06 的 Momoi 生命周期边界确认推荐方案，并要求将 D07 落地及补充此前的原版相机分析。
- Systems / 影响系统: 阶段 0 测试场景的相机归属、生命周期隔离与验收约定；仅更新文档，未修改功能代码或运行验收。
- Docs synced / 文档同步: 开发细化文档 §1、§3.3.2、§4.1–4.3、§7–9，节点复用清单 §1、§6，Momoi 分析 §1、§7，经验库新增 D07 确认条目。D08–D10 仍待确认。

## 2026-10-24 — 确认 D08 阶段 0 越界判定标准
- Correction: D08 仍待确认 → D08 已决策，由 D01、D02、D03、D06 共同收束（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 将 D08 移入已确认决策，明确采用坐标映射后的逻辑矩形，边界线不算地图外；0.1 按玩家根节点严格越界并在外侧停留判定，0.2 按实际根碰撞形状及其偏移核对物理阻挡。同步验收、开放决策表与 Gate A，保留旧状态并注明替代关系。
- Reason / 原因: 用户明确确认 D08，并要求标明 D01、D02、D03、D06 的共同收束关系。
- Systems / 影响系统: 阶段 0 地图边界、越界和静态碰撞验收契约；仅更新文档，未修改功能代码或进行运行验收。
- Docs synced / 文档同步: 开发细化文档 §1、§3.3.1、§3.3.3、§4.2–4.3、§5.1–5.3、§7–§9，经验库新增 D08 确认记录；当前仅 D09、D10 待确认，D10 仍为实现前必须确认的待决项。

## 2026-10-24 — 确认 D09 自动截图与像素级回归
- Correction: D09 可在基础自动回归后再决定是否追加截图校验 → 0.1、0.2 自动回归必须生成完整视口截图并执行像素级机器校验，人工检查不得替代或省略自动步骤（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_NODE_REUSE_CANDIDATES.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 将 D09 移入已确认决策；为 0.1 和 0.2 明确完整视口截图状态、截图像素机器断言、时变画面的采样/容差要求及失败证据，并明确人工验收仅作补充。同步 glow 截图条件、待决表和实施闸门，保留并标记已过时的 D09 未决状态。
- Reason / 原因: 用户明确纠正 D09 的自动回归验收要求。
- Systems / 影响系统: 阶段 0 自动回归、地图显示与碰撞边界的视觉验收；仅更新文档，未修改功能代码或实现回归测试。
- Docs synced / 文档同步: 开发细化文档 §1、§2.1、§3.3.2–3.3.3、§4.3、§5.3、§6.1、§7–§8，节点复用清单 §3.1、§6，经验库新增 D09 确认记录；当前仅 D10 待确认。

## 2026-10-24 — 确认 D10 阶段 0 Mod 开发源目录
- Correction: 阶段 0 原型地图使用 `ETNDOOM/ModdingDocs/Stage0/` 同目录的 `MAP01.wad`，D10 的源码/地图位置仍待确认 → 开发中的 MOD 相关源码、文件、资源和地图统一放在 `E:\Enter-The-Nyangeon\etndoom_mod\`，当前 WAD 位于其 `wad\` 子目录（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_NODE_REUSE_CANDIDATES.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_MOMOI_ANALYSIS.md`、`ETNDOOM/ModdingDocs/ENTITY_MANAGEMENT_RECOMMENDATION.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 将 D10 移入已确认决策，修正 D01/D02、地图读取、人工入口、Gate A 和证据路径；保留 PCK 内部 `res://mods/<mod_id>/` 资源约定，并同步阶段 0 关联文档中的当前状态。
- Reason / 原因: 用户明确补充开发中的 MOD 相关内容统一归档在 `etndoom_mod`，原“与本文档同目录”的地图路径已失效。
- Systems / 影响系统: 阶段 0 开发源边界、WAD 资源路径、Mod 打包/安装说明及实施闸门；仅更新文档，未修改功能代码或进行运行验收。
- Docs synced / 文档同步: 阶段 0 开发细化文档 §1、§3.1、§3.3.1、§4.1、§6.2、§7–§8，节点复用清单、Momoi 分析、实体管理建议、ETNDOOM 本地经验库。

## 2026-10-24 — 确认 Gate A 完成并整理阶段 0 实施文档
- Correction: 阶段 0 文档仍以开发草案和开工前闸门表述，旧待决状态混入实施主线 → 用户确认全部待决事项已决策、Gate A 已完成，可进入 0.1 实现；Gate B–D 的功能与验收仍待交付（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`STAGE_0_DECISION_HISTORY.md`、`STAGE_0_MOMOI_ANALYSIS.md`、`STAGE_0_NODE_REUSE_CANDIDATES.md`；`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`MODDING_SUMMARY.md`；`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 将现行决策、运行约束、两模式验收、测试契约、交付顺序及闸门分层组织；旧决策记录原文归档。统一 Mod ZIP 与地图 ZIP 的范围、Momoi 入树前隔离及相机移除语义，修正负坐标合法性、UI 移除要求及 Gate C 先实现后验证的顺序；同步关联文档的失效状态与路径。
- Reason / 原因: 用户要求在开始阶段 0 实现前，消除多次对话造成的逻辑不连续与混乱。
- Systems / 影响系统: 仅文档与实施交接约束；未开始功能实现，未进行游戏运行验收，未修改原版代码或场景。
- Docs synced / 文档同步: 阶段 0 主文档与历史附录、Momoi 分析、节点清单、总规划与索引、ETNDOOM 本地经验库。沿用已确认的本地记录位置，不复制本体 `docs/` 历史。

## 2026-10-24 — 迁移模组自动回归设计到 ETNDOOM 本地知识库
- Correction: 模组装载与无人值守回归分析写入 `docs/LEARNINGS.md`、`docs/MOD_TESTING.md` → 撤销 `docs/` 新增内容，迁移到 `ETNDOOM/LEARNINGS.md` 和新建的 `ETNDOOM/MOD_TESTING.md`（来源：user）。
- Files / 涉及文件: `ETNDOOM/LEARNINGS.md`、`ETNDOOM/MOD_TESTING.md`、`ETNDOOM/WORKLOG.md`；撤销 `docs/LEARNINGS.md`、`docs/MOD_TESTING.md` 的本次新增内容。
- Summary / 改动摘要: 保存 ETN 启动时扫描/挂载、PCK 不支持运行期卸载、MOD 页只退出不自动拉起新进程，以及「外部监督 + 同一隔离 user:// + 两次启动」的无人值守回归设计。
- Reason / 原因: 用户再次明确 `docs/` 会随远端更新被丢弃，ETNDOOM 相关新增知识必须保存在 `ETNDOOM/` 下同名文件。
- Systems / 影响系统: 仅 ETNDOOM 本地知识库和自动回归设计；未修改功能代码、测试代码或项目设置。
- Docs synced / 文档同步: 本目录 `LEARNINGS.md`、`MOD_TESTING.md`、`WORKLOG.md`。

## 2026-10-26 — 确认阶段 0.1/0.2 人工验收并推进 Gate 状态
- Correction: Gate B、Gate C 仍待 0.1/0.2 人工验收，Gate D 等待基线验收 → 用户确认 0.1 与 0.2 均已达到预期；Gate B、Gate C 已完成，Gate D 除外，阶段 0.3 正在进行（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`STAGE_0_IMPLEMENTATION.md`、`STAGE_0_3_VIEW_CONTRACT.md`、`STAGE_0_MOMOI_ANALYSIS.md`、`STAGE_0_NODE_REUSE_CANDIDATES.md`、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`MODDING_SUMMARY.md`、`Stage1/STAGE_1_MAP_CONTRACT.md`、`ETNDOOM/LEARNINGS.md`。
- Summary / 改动摘要: 标记 Gate B（0.1）和 Gate C（0.2）已完成，注明自动、像素和用户人工验收通过；Gate D 保持未完成，阶段 0.3 标为进行中。同步阶段 0.3 的阶段定位、总规划顺序和阶段 1 交接说明。
- Reason / 原因: 用户确认两模式人工验收达到预期，并说明阶段 0.3 正在进行。
- Systems / 影响系统: 阶段 0 验收状态和 0.3 到阶段 1 的交接记录；未修改实现、自动测试或本地测试产物。
- Docs synced / 文档同步: 阶段 0 主文档及其实施/视角/角色/节点子文档、ETNDOOM 总规划和结论摘要、阶段 1 合同头部、ETNDOOM 本地经验库。

## 2026-10-27 — 确认 V06 自然深度遮挡架构与测试图
- Correction: V06 的遮挡架构仍是待裁定建议 → 确认平面逻辑/碰撞保持在 2D `(u,v)`、独立高度 `h` 留在逻辑数据，表现采用正交 `Camera3D` 和逐像素深度缓冲；不引入 3D 物理，可读性策略继续单独待裁定（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 更新 V02 坐标链和 V06/V07 架构边界，明确 0.1/0.2 的 `Camera2D` 仅适用于旧基线；记录 `MAP01_BackWall.wad` 与 `MAP01_FrontWall.wad` 的相同测试几何、相反侧出生点、透明 `MIDGRATE` 遮挡验收及 SHA-256，并注明当前矩形 reader 尚不支持。未修改运行时代码或测试实现。
- Reason / 原因: 用户确认逻辑 2D + 3D 表现是更合适的遮挡方案，并要求将两张专用遮挡测试 WAD 补充到文档。
- Systems / 影响系统: 阶段 0.3 的坐标职责、自然深度遮挡设计和后续 WAD reader/验收前置条件；未修改原版场景、项目设置或运行逻辑。
- Docs synced / 文档同步: 阶段 0.3 视角契约、阶段 0 开发细化文档、ETNDOOM 本地经验库及本地工作日志。

## 2026-10-28 — 排除阶段 0 的 V06 可读性补偿策略
- Correction: V06 可读性策略仍待单独裁定 → 阶段 0 不考虑 `cutaway`、`dither`、`wall pull`、`upright hiding` 及之后所有用于提高可读性的同类策略；自然深度遮挡核心保持已裁定（来源：user）。
- Implementation note / 实现注记: V04 已规定阴影的逻辑脚底锚点，V06 文档未规定阴影参与深度测试的具体做法；按自然遮挡规则在实现时解决阴影深度测试与共面冲突。
- SUPERSEDED: 2026-10-29 用户裁定阶段 0 不实现或验收阴影；其几何与深度关系延后开发，不再属于 V06 阶段 0 待明确的实现细节。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/ModdingDocs/ISODOOM_SECTOR_WALL_RENDERING_REFERENCE.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 在 V06 明确标记上述策略不实现、不配置、不验收；补充阴影深度测试及共面冲突处理属于实现细节，并将 isodoom 相关选项限定为参考信息。
- Reason / 原因: 用户明确裁定这些策略和后续同类可读性策略不是阶段 0 需要考虑的内容，并询问 V06 是否仍有未裁定项。
- Systems / 影响系统: 阶段 0.3 遮挡设计范围与文档状态；仅更新文档，未修改运行时代码或测试实现。
- Docs synced / 文档同步: 阶段 0.3 视角契约、isodoom sector/wall 渲染参考、ETNDOOM 本地经验库。

## 2026-10-29 — 明确 V06 阶段 0 阴影范围与角色精灵基线
- Correction: V06 仍待明确阴影与深度缓冲的关系 → 阶段 0 不创建或渲染阴影；角色暂按透明像素丢弃和竖直 billboard 实现，需人工确认；精灵高度 `56mu`、脚底对齐逻辑锚点、纹理等比缩放适配高度；墙体可以遮挡角色全部高度区域（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 修正 V06 状态与验收范围，明确阶段 0 阴影延期及精灵暂定规则；新增深度写入/测试、共面几何处理和基于最终相机空间包围范围计算 `near/far` 的实现建议。该建议尚待实现核验，具体 near/far 值须待 V07 取景冻结。
- Reason / 原因: 用户裁定阶段 0 的阴影及角色表现范围，并要求为深度相等与精度问题给出具体实现细节。
- Systems / 影响系统: 阶段 0.3 V06 渲染契约与自然遮挡验收；仅更新设计文档和本地经验，无运行时代码或测试实现改动。
- Docs synced / 文档同步: 阶段 0.3 视角契约、阶段 0 开发细化状态、本地经验库及本地工作日志。

## 2026-10-29 — 裁定 V06 深度比较与相机裁剪规则
- Correction: V06 的深度比较、双面 linedef 面选择、z-fighting 处理和 `Camera3D.near/far` 仍属建议 → 用户确认采用默认相机空间深度比较；双面 linedef 仅输出朝相机的一侧；因 WAD 墙边和地面边不重叠，阶段 0 不预先增加 z-fighting 修复，若复现再调试；near/far 按已给出的相机空间范围与 margin 公式计算（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 将 V06 深度规则和相机裁剪算法标为已决策，具体 near/far 数值留待 V07 固定取景后代入；统一使用“双面 linedef”称呼，明确边缘无重叠且不做预防性深度偏移。
- Reason / 原因: 用户确认前一轮提出的第 6 项实现建议，并要求澄清双面 linedef 术语及不对理论上不会发生的边缘 z-fighting 作提前修复。
- Systems / 影响系统: 阶段 0.3 V06 渲染契约与回归判据；仅更新文档，无运行时代码或测试实现改动。
- Docs synced / 文档同步: 阶段 0.3 视角契约、阶段 0 开发细化状态、本地经验库及本地工作日志。

## 2026-10-29 — 决策阶段 0.3 V08 入口与回归范围
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 将 V08 裁定为已决策；阶段 0.3 的自动与人工验收固定使用 `--stage0=0.3 --stage0-collision=on`。0.1/0.2 的既有证据保留但不再重跑，`--stage0-collision=off` 不列入测试项；同步入口参数约束、证据目录和失败证据要求。
- Reason / 原因: 用户于 2026-10-29 明确收窄 V08 回归范围，并确认其余入口校验、显式解析和证据隔离建议作为决策采用。
- Systems / 影响系统: 阶段 0.3 的 Mod entry、自动回归、人工验收和本地知识库；本次仅更新文档，没有修改实现代码或 `tests/`。
- Docs synced / 文档同步: 视角与投影契约 V08、阶段 0 开发细化 §1、§2、§3.1、§6.1–§6.2，以及本地 `LEARNINGS.md`。


## 2026-10-29 — 阶段 0.3 全部决策完成
- Correction: 0.3 文档仍混有设计未决状态 → 用户确认全部待确认决策已完成；V01–V08 可进入实现，实机校准与人工验收仍须完成，Gate D 不提前关闭（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DECISION_HISTORY.md`、`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md`。
- Docs synced / 文档同步: 总规划、sector 墙体参考、`ETNDOOM/LEARNINGS.md`；历史状态保留在决策历史附录 §C。

## 2026-10-30 — 将 docs 本地修改迁回 ETNDOOM 同名文档
- Correction: 阶段 0 新增经验与工作记录再次写入 `docs/` → 按用户要求统一迁入 `ETNDOOM/` 同名文档，`docs/` 恢复到 Git HEAD，避免远端更新覆盖本地记录（来源：user）。
- Files / 涉及文件: `ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`；迁移后恢复 `docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 补齐 V04 碰撞与锚点、V05 采样与墙面范围、V05/V06 WAD 回归矩阵和 V07 相机决策；测量结论并入已有条目，全部决策完成记录去重保留，历史状态及 SUPERSEDED 说明一并保留。
- Verified / 验证: 迁移内容、重复条目、UTF-8 与源文档恢复逐项核对；仅调整文档，未修改功能代码或测试，未提交。

> Migration / 迁移（2026-11-13）：本次承接 `docs/WORKLOG.md` 相对 Git HEAD 的全部未提交新增内容；本体原文仍见 [`docs/WORKLOG.md`](../docs/WORKLOG.md)。旧记录中的 `docs/` 路径表示当时写入位置，不据此恢复旧维护方式。

## 2026-10-31 — 阶段 1 承接阶段 0 完成状态
- Correction / 修正: 阶段 1 初稿仍按阶段 0 未完成设置前置空栏，并将已有投影/单位列为待决 → 阶段 0.1–0.3 已完成，Gate A–D 已关闭；阶段 1 承接已验收基线，只继续裁定新增地形、玩法与正式格式（来源：user）。
- Docs synced / 文档同步: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`（基线、映射、工作包、待决项与交接）、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`docs/PROJECT_MAP.md`。原型高差仍只作显示，未将其记为真实地形运动能力。

## 2026-11-01 — 阶段 1 地形表示与实时跨步修正
- Correction: 规则地形网格候选、地图外/内洞分别表示、固定 8mu 高度等级、显式楼梯连接授权或预写邻接通行标签 → 保留精确 sector 区域与直接 mu 高度，无 sector 区域统一为无地面，玩家最大向上跨步 24mu，在尝试移动时结合当前脚底高度和接触几何判定；鼠标射线参考 isodoom（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`docs/PROJECT_MAP.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 保留旧方向的 SUPERSEDED 历史说明，同步 D01–D03 及 D04/D07/D10 的关联约束、示例与验收项；记录两张 MAP02 的精确字段、24mu 跨步判例、isodoom 地面射线及无命中兜底行为。方向已修正，完整契约与鼠标细则尚未冻结。
- Verified / 验证: 直接解析两张 WAD 的目录、顶点、边界与 sector 高度；只读核对 DOOM `P_CheckPosition/PIT_CheckLine/P_TryMove` 和 isodoom `CursorGround` 及调用方。仅文档修正，未修改 WAD/功能代码，未做新功能运行验收。
- Docs synced / 文档同步: 上述阶段契约、总规划、项目索引与经验库。

## 2026-11-03 — D01 查询细化与鼠标职责修正
- Correction: D01 的说明停留在精确坐标/统一无地面前提，并继续展开鼠标命中 → D01 必须具体回答 sector 覆盖查询与共享边/顶点归属；鼠标反投影、射线命中及兜底规则全部移入 D06（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`docs/PROJECT_MAP.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 更新决策表和接口映射；补充区域拓扑、候选筛选/精确包含、共享边与顶点的半开归属、接触集合、数值精度及有限体型分工的讨论方案。该算法方案未获用户裁定，D01 保持未完成；本条仅记录用户已明确的职责与回答范围修正。
- Verified / 验证: 使用分数运算的只读探针对两张 WAD 的内部点、共享边、三 sector 顶点、细小偏移和斜边两侧复核覆盖/接触信息；半开 owner 列为规则推导，未冒充运行实现。仅更新文档。
- Docs synced / 文档同步: 阶段契约、总规划、项目索引及经验库。
- Correction（同日补充）: 边界说明仅展开通用符号扰动候选 → 用户补充应考虑经典 WAD 的有向 linedef 及 Front/Back 信息，并提出顶点随机扰动、空值或之前值供讨论（来源：user）。源码核对与建议追加于契约 §3.1.6；固定 Front 与顶点回退为 AI 建议，未作为用户已选决策，D01 仍未冻结。

## 2026-11-04 — 确认 WAD 预存 BSP 作为后续查询基础
- Correction: 是否采用 BSP 尚待裁定、曾建议评估项目导入预处理构建器 → 用户确认 ETNDOOM 使用 BSP，节点由 WAD 提前保存，项目不引入 BSP 构建器（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`docs/PROJECT_MAP.md`、`docs/ARCHITECTURE.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 同步已确认方向并保留历史；新增 D01 的 BSP/覆盖/边界建议、D02 的共享 sector 高度与实体支撑建议、D03 的完整占地扫掠与实时跨步建议。这些新细则仍待用户裁定，未把采用 BSP 等同于完整 D01–D03 已冻结。
- Verified / 验证: 只读整数叉积探针检查当前 MAP02 的一个内部点、一个共享边点、一个多 sector 顶点和一个场外点；仅验证候选遍历及 seg 半平面覆盖，未作完整几何校验或游戏运行验收。没有修改功能代码或 WAD。
- Docs synced / 文档同步: 上述契约、总规划、架构方向、项目索引与经验库。

## 2026-11-04 — D01、D02、D03 正式决策
- Correction: BSP 已采用但 D01–D03 新建议仍待裁定 → 用户明确接受建议，正式选定 D01 的 BSP/真实覆盖/确定性边界、D02 的 mu/binary64 与独立支撑状态、D03 的完整占地扫掠/实时 24mu 跨步/ceiling 净空（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 将三项方案改为正式决策，记录用户确认日期与来源；明确接受 BSP 重建导致的零面积边界 owner 差异，旧候选保留历史；以依赖表列出 D04–D10 仍需补齐的运动/实体参数、攻击、格式等事项，不另行臆定数值。
- Reason / 原因: 用户要求将上一轮认可的建议落地为 D01、D02、D03 决策。
- Systems / 影响系统: 后续地图加载、空间查询、高度状态、地形运动及导航契约；此次无功能代码或 WAD 修改。
- Docs synced / 文档同步: 阶段 1 契约 §3、§3.1.10、§3.2.1、§3.3.1，总规划、架构、项目索引及经验库。

## 2026-11-04 — 补充 D03 阻挡响应的决策边界
- Correction: D03 正式确认后未单列阻挡响应缺口 → 用户指出不可跨台阶等情形仍须定义实际碰撞行为；原有查询、跨步和连续检测语义保持已决策，具体滑动与停止规则仍需补充（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 记录缺口，并将 BLOCKMAP 价值与碰撞响应建议明确标为待裁定；只读复核 MAP02 的 BLOCKMAP 基本结构与第四阶边界，不代表覆盖完整性验证或游戏内验收。未修改功能代码或 WAD。
- Docs synced / 文档同步: 阶段 1 契约 §3.3.2、经验库。

## 2026-11-04 — 暂不引入 BLOCKMAP
- Correction: BLOCKMAP 是否采用待裁定 → 用户决定暂不引入，即使 WAD 已含 BLOCKMAP 数据也不使用（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`docs/ARCHITECTURE.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 同步空间索引决策，保留历史评估和 WAD 原数据；碰撞响应的具体建议单列为尚未确认，不作为本次已敲定规则。未修改功能代码或 WAD。
- Docs synced / 文档同步: 阶段 1 契约 §3.3.2–3.3.3、架构方向、经验库。

## 2026-11-04 — D03 接地碰撞响应正式决策
- Correction: 接地停止/滑动、多接触和速度处理仍为推荐方案 → 用户在 DOOM 源码对照后确认将推荐方案落地为正式决策（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/DOOM_MOVEMENT_REFERENCE.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 将契约 §3.3.3 转为正式决策，确认完整扫掠、最早接触推进、沿边滑动、同时约束、独立速度、合法跨步状态更新、数值边界、异常终止及唯一求解器；纯试算与玩法事件分离。同步入口和参考状态，保留历史，不扩大为 D04–D10 全部冻结。
- Reason / 原因: 用户明确接受当前推荐方案。
- Systems / 影响系统: 后续地形移动及查询契约；本轮仅改文档，尚未实现或运行验收。
- Docs synced / 文档同步: 上述七份文档；未修改功能代码或 WAD，未提交。

## 2026-11-05 — D04 跳跃参考来源修正
- Correction: D04 的“原版闪避跳跃”未明确区分参考系统 → 经典 DOOM 无主动跳跃，ETN 本体闪避跳跃另属本体实现；D04 可取用用户指定 UZDoom 的跳跃代码（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`docs/DOOM_MOVEMENT_REFERENCE.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 澄清术语并记录 UZDoom 起跳、重力、落地、撞顶、空中控制及 tic 单位的源码入口；保留 D04 参数与能力待裁定边界。仅源码核对与文档更新，未移植实现或进行游戏验证。
- Docs synced / 文档同步: 阶段 1 契约 §3.6、移动参考 §5、经验库。

## 2026-11-05 — D04 当前方向与阶段范围修正
- Correction: 玩家能力和跨越无地面仍全部待定，D04/阶段 1 验收包含第一版测试敌人，取用 UZDoom 的边界宽泛 → 玩家可跳上平台、主动跳下，不能跨越 D01 无 Sector；跳跃沿用 UZDoom 思路，主动跳下与落地沿用经典 DOOM；第一版测试敌人不属于阶段 1（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`docs/DOOM_MOVEMENT_REFERENCE.md`、`docs/PROJECT_MAP.md`、`docs/ARCHITECTURE.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 同步当前方向、源码分工、阶段依赖与玩家判例；保留历史对照，跳跃数值、支撑转换及接触细则仍待裁定，未将当前想法记为 D04 整体冻结。仅修改文档，未移植代码或运行游戏。
- Docs synced / 文档同步: 阶段 1 契约 §3、§3.6、§5，移动参考 §5–6、项目入口、架构方向、经验库。

## 2026-11-05 — D04 前四项确认、极弱空中推力与 60mu 跳高修正
- Correction: D04 前四项仍待选，建议 36mu 跳高与 0.5 空中控制 → 用户确认第 1/2/4 项方案，将真实跳高改为 60mu，并明确选择保留 UZDoom 的 1/256 极弱输入推力；强空中控制会改变内容约束，不应因操作弱而增强（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`docs/DOOM_MOVEMENT_REFERENCE.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/SYSTEMS.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 正式记录 60mu/1225mu/s²/约383.405790mu/s、按住连跳/落地等待0.2s、1/256加性空中推力及仅接地24mu跨步；保留旧建议并标记取代。第5–7项及体高依赖未冻结；恰好60mu登台边界交支撑/组合接触补齐。另按用户要求核对本体跳跃装饰，仅列姿态、光环、烟尘/音效候选，未决定移植。
- Reason / 原因: 用户确认与修正；空中控制以保持内容约束为目标。
- Systems / 影响系统: 阶段1地形运动契约、后续阶段4表现；仅文档修改，未移植功能或运行游戏。
- Docs synced / 文档同步: 契约§3.6.1–3.6.2、移动参考§8、系统§5.1.1、架构、入口及经验库。

## 2026-11-05 — D04 四项跳跃表现正式确认
- Correction: ETN 跳跃表现仅为候选、尚未选定 → 用户确认移植跳跃姿态、光环滞后跟随、起跳烟尘和音效四项，其余不移植（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`docs/SYSTEMS.md`、`docs/DOOM_MOVEMENT_REFERENCE.md`、`docs/PROJECT_MAP.md`、`docs/ARCHITECTURE.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 契约 §3.6.2 转为正式决策，同步实现边界及验收要求；表现读取真实状态，起跳烟尘/音效只由成功起跳触发，旧高度/免伤/计时逻辑及未选装饰不移植。
- Systems / 影响系统: 后续阶段 4 跳跃表现；本轮仅文档修改，未实现、未运行游戏、未提交。
- Docs synced / 文档同步: 契约 §3.6.2、系统 §5.1.1、移动参考 §8、架构、入口和经验库。

## 2026-11-05 — D04 第 5/7 项方向补充
- Correction: 第 5/7 项完全待定 → 用户明确占地完全离开高台才下坠，落地本身不修改水平速度且组合接触正常走碰撞；前四项已决策，第 6 项另议（来源：user）。
- Files / 涉及文件: 阶段 1 契约、`docs/DOOM_MOVEMENT_REFERENCE.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 同步用户方向并补经典源码依据；支撑边/点、同刻接触、剩余时间和恰好 60mu 登台列为待确认建议，未将建议标成正式决策。仅文档与只读源码核对，未实现、未运行游戏、未提交。
- Docs synced / 文档同步: 契约 §3.6、§3.6.3，移动参考 §9、架构与入口、经验库。

## 2026-11-05 — D04 第 5/7 项正式决策
- Correction: 第 5/7 项已有方向但支撑与组合接触细化仍为建议 → 用户确认全部建议落地为正式决策（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`docs/DOOM_MOVEMENT_REFERENCE.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 确认完整占地支撑、边/点相切、实际离台时刻、落地水平速度保持、侧碰独立裁剪、同刻联合约束、剩余时间及 60mu 等号登台判例；同步状态与交叉引用，保留历史。第 6 项继续另议，不扩大为 D04 整体冻结。
- Systems / 影响系统: 阶段 1 地形运动契约；仅修改文档，尚未实现或进行游戏验证，未提交。
- Docs synced / 文档同步: 契约 §3.6–3.6.3、移动参考 §9、架构、项目入口及经验库。

## 2026-11-05 — D04 第 6 项边界前提修正
- Correction: 无 Sector 边缘笼统按可定义的悬崖/部分悬空讨论 → 正常边缘大多由单面 linedef 完整体积阻挡，无 Impassable 也阻挡；缺线导致轮廓不闭合的异常 WAD 不能预设存在严格有/无 Sector 分界（来源：user）。
- Files / 涉及文件: 阶段 1 契约、`docs/DOOM_MOVEMENT_REFERENCE.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`。
- Summary / 改动摘要: 记录用户说明与 NoBorder 静态字段；发现除缺边外还有 SEGS[24]→linedef 30 越界引用。提出正常单面线阻挡与异常加载校验的分工，未将拒绝异常地图的建议标成正式决策，未运行游戏或修改 WAD/功能代码。
- Docs synced / 文档同步: 契约 §3.6.4、移动参考 §10、经验库与入口；第 6 项仍待确认，未提交。

## 2026-11-05 — D04 第 6 项无效引用拒绝加载决策
- Correction: 无效引用拒绝加载尚为建议、异常 WAD 的引擎容忍范围不明确 → 用户补充严格 Source Port（如 PrBoom）会报错，并正式决定 ETNDOOM 检测到无效引用即拒绝加载并报错（来源：user）。
- Files / 涉及文件: 阶段 1 契约、`docs/DOOM_MOVEMENT_REFERENCE.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/LEARNINGS.md`、`docs/WORKLOG.md`。
- Summary / 改动摘要: 记录用户 PrBoom-Plus-RT 截图与 SEGS[24]→linedef 30 一致的报错，确认 NoBorder 为错误引用拒绝加载判例，区分合法无引用哨兵。其它覆盖异常/兼容建议不自动转为决策。仅文档更新，未修改地图或加载器、未运行游戏、未提交。
- Docs synced / 文档同步: 契约 §3.6.4、移动参考 §10、架构与项目入口、经验库。

## 2026-11-05 — D04 第 6 项开放轮廓处理范围收窄
- Correction: 引用有效但轮廓开放需另定专项拒绝/兼容/兜底规则 → 用户明确这是罕见 WAD 制图失误，不属 ETNDOOM 正常考虑范围，不作特殊处理（来源：user）。
- Files / 涉及文件: 阶段 1 契约、移动参考、架构、项目入口、经验库及本记录。
- Summary / 改动摘要: 记录 NoBorder2 静态引用/开放轮廓证据及用户关于引擎容忍行为的补充；明确不引入专项闭合性拒绝、修复、回位或兼容机制，原建议标记取代。无效引用拒绝加载保持有效，D01 增加范围说明避免重新引入该项要求。仅修改文档，未改地图/运行代码，未运行游戏，未提交。
- Docs synced / 文档同步: 契约 §3.1.10、§3.6.4，移动参考 §11、架构与项目入口、经验库。

## 2026-11-05 — D04 整体确认已决策
- Correction: D04 部分已决策、整体未冻结 → 用户明确要求 D04 整体标为已决策（来源：user）。
- Files / 涉及文件: 阶段 1 契约、新模式与地图总规划、项目入口、架构、移动参考、经验库及本记录。
- Summary / 改动摘要: 同步 D04 总状态、决策表和跨文档入口，标明历史待决状态已取代；不改已选行为与参数。体高依赖留在 D05/D10，实现/容差/运行验收交阶段 4；阶段 1 整体未冻结。仅文档修改，未改运行代码或 WAD，未提交。
- Docs synced / 文档同步: 契约 §3、§3.6–3.6.4，总规划状态，PROJECT_MAP、ARCHITECTURE、DOOM_MOVEMENT_REFERENCE、LEARNINGS。

## 2026-11-05 — D05 经典墙体前提与讨论范围修正
- Correction: 独立有限高度墙块/障碍、额外天花板行为及玩家体高继续列为阶段 1 待选 → 用户明确以经典 sector/linedef 语义核对，独立障碍归实体且不在阶段 1，玩家体高 56mu，天花板当前无碰撞以外行为（来源：user）。
- Summary / 改动摘要: 读取引用对话并核对经典字段、移动、射线和 missile 源码；补齐 ML_BLOCKING 也挡怪物、无 flag 仍查开口、中间贴图不挡射击但地形/实体仍可阻挡等限定。不自动将整个 D05 标为已决策。
- Docs synced / 文档同步: 契约 §3.7 与 D05 条目、移动参考 §12、项目入口、经验库。仅文档修改，未改运行代码或地图，未运行测试，未提交。

## 2026-11-06 — 天空表面分类修正与攻击方案
- Correction: 将天空 Ceiling 和 linedef 天空部分笼统称为天空碰撞 → 按用户修正分开描述，并记录 hitscan 穿过两者、弹射物穿过天空线但碰天空 Ceiling 删除的 ETNDOOM 提案（来源：user）。
- Summary / 改动摘要: 复核渲染源码，补充经典双面 upper texture 隐去需两侧 ceiling 都为 sky；区分穿透继续查询、终止无特效及删除对象。D05/D06 整体状态未改为已决策，未改运行代码或地图，未运行游戏，未提交。
- Docs synced / 文档同步: 契约 §3.7.1、移动参考 §14、经验库及本记录。

## 2026-11-06 — 天空分类与 D06 特殊飞行状态决策
- Correction: 天空线分类待定，穿过后继续普通碰撞，弹射物碰天空 Ceiling 立即删除 → 双面两侧天空的上部高差墙面才属天空部分，单侧按普通线、单面无天空部分；弹射物遇任一天空面后进入无碰撞飞行状态并计时删除，hitscan 后段无碰撞延伸至最大距离（来源：user）。
- Summary / 改动摘要: 将分类写为 D05 正式子项，将攻击状态补入 D06 正式子项；标记旧提案取代，保留历史与经典源码事实。计时器时长留 D06 补齐，不擅自赋值；未改变整个 D05/D06 的冻结状态。
- Docs synced / 文档同步: 契约 §3.7.1/§3.8 与决策表、移动参考 §15、项目入口、经验库。仅修改文档，未改运行代码或地图，未运行游戏，未提交。

## 2026-11-06 — D05 整体确认已决策
- Correction: D05 前提/天空分类已明确但整体仍未决 → 按用户条件授权复核，D05 无剩余未决设计项，正式标为已决策（来源：user）。
- Summary / 改动摘要: 同步契约总状态、D05 决策表与正文、总规划和知识库入口；标明历史未决状态取代。D06 计时器时长、攻击/瞄准及后续格式、实现、验收不阻塞 D05；未扩大已定规则或阶段范围。
- Docs synced / 文档同步: 阶段 1 契约、NEW_MODE_MAP_PLAN、PROJECT_MAP、ARCHITECTURE、DOOM_MOVEMENT_REFERENCE、LEARNINGS。仅修改文档，未修改运行代码或地图，未运行游戏，未提交。

## 2026-11-11 — D06 逐项确认与阶段 1 实体范围修正
- Correction: 将弹射物、爆炸、拾取和主动交互的完整规则均列为阶段 1 必决/验收项 → 弹射物/爆炸来源/拾取物属于实体，阶段 1 不考虑；当前也没有特殊 linedef/可交互机关，D06-07/09/10/11 移出本阶段（来源：user）。
- Correction: D06-01–14 全部待决、天空计时未定 → 01–06、12–14 按推荐确认，默认天空计时 2.0 秒及覆盖/暂停/寿命接管规则已定；03/12 无敌对实体时实战验证后移，不能因缺少测试消费者重新列为未决设计（来源：user）。
- Summary / 改动摘要: 读取近战参考后，更新 D06-08 为玩家参考 ETN 并补高度/遮挡/实体去重/即时命中的 AI 推荐，尚待用户裁定。保留排除项旧建议及 Imp 火球研究为历史/后续参考；D06 整体未冻结。
- Files / 涉及文件: 阶段 1 契约、NEW_MODE_MAP_PLAN、docs/PROJECT_MAP.md、docs/ARCHITECTURE.md、docs/DOOM_IMP_FIREBALL_REFERENCE.md、docs/LEARNINGS.md、docs/WORKLOG.md。
- Docs synced / 文档同步: 契约 §3.4/§3.8–3.10/§5、总规划与知识库入口及上述参考。仅文档修改，未修改功能代码或地图，未运行游戏，未提交。

## 2026-11-12 — D06 采用 ETN 近战并整体确认
- Correction: D06-08 待裁定、D06 仅部分已决策 → 用户确认 08 采用 ETN 近战，D06 整体标为已决策（来源：user）。
- Summary / 改动摘要: 确认短窗口多目标范围近战及真实高度/遮挡、实体去重、即时命中适配；按用户要求移除未采用的近战研究、比较段落和引用。2026-11-11 记录中的待裁定状态仅为历史，已由本条取代。
- Files / 涉及文件: 阶段 1 契约、NEW_MODE_MAP_PLAN、docs/PROJECT_MAP.md、docs/ARCHITECTURE.md、docs/LEARNINGS.md、docs/WORKLOG.md；移除未采用的近战独立参考文档。
- Docs synced / 文档同步: D06 总状态、决策表、§3.9/08 与验收说明及知识库入口。07/09/10/11 的范围排除与后续实体验证边界保持；仅修改文档，未修改功能代码或地图，未提交。

## 2026-11-12 — D07 特殊节点诊断与开放轮廓条件式加载拒绝修正
- Correction: 附加特殊节点有经典节点可用时默认忽略 → 检测到扩展、压缩或 GL 节点须告警并说明实际使用的数据；可否加载仍按支持范围和校验结果判断（来源：user）。
- Correction: 引用有效但轮廓开放一律强调不作特殊处理、不增加闭合性拒绝 → 若加载阶段可定位明确异常点，则归入一般几何错误拒绝加载（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/DOOM_MOVEMENT_REFERENCE.md`、`docs/LEARNINGS.md`。
- Summary / 改动摘要: 保留旧说明并标注 SUPERSEDED，记录 NoBorder2 静态端点探针；补充 REJECT 源码语义及 D06 关联待裁定事项。D07 整体未确认，D06 现行决策未改动，无功能实现或运行验证。
- Reason / 原因: 用户修正 D07 输入诊断范围，并询问 REJECT 对视线的影响。
- Systems / 影响系统: 地图加载契约、几何校验、后续视线输入。
- Docs synced / 文档同步: 契约 §3.6.4、§3.11、D06-12；架构与项目索引、移动参考 §11、经验库。

## 2026-11-12 — 阶段 1 不使用 REJECT，移出 D06-12 决策
- Correction: REJECT 是否使用待裁定、D06-12 保留三点视线等已定规则且仅测试后移 → 阶段 1 不使用 REJECT，D06-12 的决策、接口要求和验收一并排除，后续敌对实体接入时重新讨论（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/LEARNINGS.md`、`docs/DOOM_IMP_FIREBALL_REFERENCE.md`。
- Summary / 改动摘要: 更新 D06 总表、12 状态、D07 REJECT 状态、阶段验收和交接；旧规则以 SUPERSEDED 保留历史，不再作为阶段 1 约束。D06 其它条目维持，D07 整体未确认。
- Reason / 原因: 阶段 1 没有敌对实体，REJECT 与 D06-12 无法在本阶段测试中体现。
- Systems / 影响系统: 阶段 1 地图输入与视线契约范围。
- Docs synced / 文档同步: 契约 §3.9/D06-12、§3.11、§5，总规划、架构、项目索引及经验库。仅文档修改，无功能代码删除/回退，未运行游戏、未提交。

## 2026-11-12 — D07 地面编码采用修正后的推荐并整体确认
- Correction: D07 剩余推荐未确认、输入节点清单与区域表达待裁定 → 用户确认剩余推荐，D07-01–09 合并已定修正后整体已决策（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`ETNDOOM/ModdingDocs/MODDING_SUMMARY.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/LEARNINGS.md`。
- Summary / 改动摘要: 新增 §3.12 的三层数据、地面片字段语义、原始边来源、高度/精度、输入支持表、重叠与校验、辅助数据及无持久缓存决策；合并特殊节点警告、开放端点一般错误拒绝、阶段 1 不使用 REJECT 与 D06-12 移出。同步 D07 状态、D08 衔接和旧 JSON 地形建议的替代说明。
- Reason / 原因: 用户正式接受其余推荐。
- Systems / 影响系统: 阶段 1 地形数据契约，后续地图加载与查询架构。
- Docs synced / 文档同步: 契约总表、§3.12、§4，总规划、项目索引、架构、经验库。D08–D10 与完整格式/示例仍待收束；未改功能代码、地图或本地工具状态，未实现、未运行游戏、未提交。

## 2026-11-12 — D08 内容来源说明修正
- Correction: 旧说明仅强调外部 IWAD 素材依赖，未明确完整 IWAD 可单独提供地图与资源 → 用户明确 `DOOM2.WAD` 自身资源完备，常见第三方地图在基础 IWAD 上叠加 PWAD；外部文件边界不表示 IWAD 自身缺资源（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`docs/ARCHITECTURE.md`、`docs/LEARNINGS.md`。
- Summary / 改动摘要: 修正资源来源说明及 §1.2 过时的 WAD 输入待决描述，记录目录核对和阶段 0 双文件限制；§3.13 给出 D08 推荐，未标为已决策。
- Reason / 原因: 用户补充 IWAD/PWAD 内容加载模型并要求推荐。
- Systems / 影响系统: 地图加载、资源来源、包身份与依赖契约。
- Docs synced / 文档同步: 契约 §1.2/§3.13、架构、经验库。本条仅记录用户来源修正，新增推荐未获确认；未改功能代码或 WAD，未运行游戏、未提交。

## 2026-11-12 — D08 包与资源采用推荐并整体确认
- Correction: D08-01–08 为推荐、包/资源/身份/版本待裁定 → 用户接受全部推荐，D08 整体已决策（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`ETNDOOM/ModdingDocs/MODDING_SUMMARY.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/LEARNINGS.md`。
- Summary / 改动摘要: §3.13 正式记录用户确认，采用 WAD 容器、单 IWAD/有序 PWAD、覆盖与整组地图选择、资源解析、可选 ETNINFO、身份/依赖/版本和诊断；同步总表、原型映射、格式草案及关联状态，保留历史。
- Reason / 原因: 用户要求采用推荐并标记 D08 已决策。
- Systems / 影响系统: 阶段 1 地图包与资源契约、后续地图加载。
- Docs synced / 文档同步: 契约 §1.2/§3/§3.13/§4、总规划、摘要、架构、项目索引和经验库。D09/D10 及阶段 1 整体尚未冻结；本轮仅文档变更，未改代码或 WAD，未运行游戏、未提交。

## 2026-11-12 — D09 最小出生配置确认
- Correction: 最小出生标签尚待选择、总规划将刷怪区域列为最小必需信息 → 最小地图必须含玩家出生点，其它出生点/区域/用途标签均非必需（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`docs/LEARNINGS.md`。
- Summary / 改动摘要: D09-01 标为已确认，新增 §3.14 区分已定要求和剩余建议；同步总规划及字段草案。
- Reason / 原因: 用户明确最小地图出生要求并询问剩余决策。
- Systems / 影响系统: 阶段 1 出生与示例契约。
- Docs synced / 文档同步: 契约 §3/§3.14/§4、总规划和经验库；D09 整体未决。本轮仅修改文档，未改代码或 WAD、未提交。

## 2026-11-12 — D09 不检测出生合法性并整体确认
- Correction: 建议检查出生完整占地/净空并拒绝非法出生、D09 仅部分确认 → 不检测玩家出生合法性以兼容特殊 WAD，其余推荐采用，D09-01–06 整体已决策（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md`、`ETNDOOM/ModdingDocs/MODDING_SUMMARY.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/LEARNINGS.md`。
- Summary / 改动摘要: 修正 D09-02/03/04/06 及早期出生检查、查询与验收条款，确认读取、数量选择、其它 THINGS 与示例范围；同步总表及关联状态，保留修正历史。
- Reason / 原因: 用户明确特殊 WAD 兼容性政策并接受其余建议。
- Systems / 影响系统: 阶段 1 出生契约、后续加载与初始化接口。
- Docs synced / 文档同步: 契约 §1.2/§3/§3.14/§4/§5、总规划、摘要、架构、项目索引及经验库。D10 与完整字段/示例尚待收束；仅文档变更，未修改功能代码或 WAD，未运行游戏、未提交。

## 2026-11-12 — D10 出生初始化采用 UZDoom 高度处理
- Correction: D09 禁止自动抬升、D10 出生高度与异常状态尚待决策 → 采用 UZDoom 占地抬高及撞顶下压，允许初始重叠和卡住；出生中心无真实地面时告警后取玩家高度 0mu，不伪造地面或支撑（来源：user）。
- Files / 涉及文件: 阶段 1 地图契约、总规划、模组摘要、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/DOOM_MOVEMENT_REFERENCE.md`、`docs/LEARNINGS.md`。
- Summary / 改动摘要: 新增契约 §3.15 的三项出生决策和设计判例，修正 D09 关联限制，保留历史及不检测出生合法性的原则；区分出生高度调整与运行期跨步、真实地面与玩家高度回退。
- Reason / 原因: 用户明确采用引用聊天中的 UZDoom 初始化处理，并确定无真实地面的兼容回退。
- Systems / 影响系统: 阶段 1 出生契约与后续运动初始化。
- Docs synced / 文档同步: 契约 §3.14–3.15、知识库与入口已同步；D10 统一查询契约及完整示例仍待整理。本轮仅文档变更，未改功能代码或 WAD，未运行游戏、未提交。

## 2026-11-12 — 阶段 1 决策状态校正与契约整理
- Correction: D10 部分已决策、统一查询与其它关联项仍作为待裁定状态 → 用户确认待确认决策全部完成，D01–D10 均已决策；查询语义按既定规则汇总，字段实例、示例交付与运行验收分别跟踪（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md`、新增 `STAGE_1_DECISION_HISTORY.md`、总规划、模组摘要、`docs/ARCHITECTURE.md`、`docs/PROJECT_MAP.md`、`docs/LEARNINGS.md`。
- Summary / 改动摘要: 正文保留现行规则、判例和阶段边界，历史讨论完整归档；整理决策索引、数据/查询汇总和交付状态，清除出生、开放轮廓及已排除实体规则的过期表述。主要决策/章节编号保留，修正关联入口。
- Reason / 原因: 用户说明决策已全部完成，并要求开始后续工作前整理多轮对话累积的逻辑、冗余与混乱。
- Systems / 影响系统: 仅阶段 1 契约与知识库，没有修改功能代码或 WAD。
- Docs synced / 文档同步: 契约、历史、项目索引、架构、总规划、摘要及经验库；本条记录用户状态修正，不代表阶段交付或游戏验收通过。

## 2026-11-13 — 阶段 1 文档与知识增量迁入 ETNDOOM
- Correction: 阶段 1 新增研究及知识增量再次写入 `docs/` → 新增文档整份移入 `ETNDOOM/`，已有文档仅将未提交改动迁入同名文件，后续维护位置同步到 `AGENTS.md`（来源：user）。
- Files / 涉及文件: `ETNDOOM/DOOM_MOVEMENT_REFERENCE.md`、`ETNDOOM/DOOM_IMP_FIREBALL_REFERENCE.md`、`ETNDOOM/ARCHITECTURE.md`、`ETNDOOM/PROJECT_MAP.md`、`ETNDOOM/SYSTEMS.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`、阶段 1 契约与历史、`AGENTS.md`。
- Summary / 改动摘要: 迁入两份完整研究文档及五份文档共 567 行新增内容；同名经验库与工作记录保留原内容并追加，架构/项目索引/系统补充新建。有效链接改指新位置，历史路径标明当时含义，本体原理引用仍指 `docs/`。
- Reason / 原因: 用户说明 `docs/` 的本地修改会随远端更新被覆盖，要求统一保存到 ETNDOOM。
- Docs synced / 文档同步: 专属知识库、契约引用与根目录维护约定；迁移前文件及差异保存在本地 `.migration/docs-to-etndoom-20261113/`。仅文档迁移，不修改功能代码或地图，不创建提交。

## 2026-11-13 — 阶段 1 文档准备完毕，准备实现阶段 1
- Files / 涉及文件: `AGENTS.md`、`ETNDOOM/` 阶段契约与知识库、`etndoom_mod/wad/MAP01.wad` 及六份 `MAP02*.wad`。
- Summary / 改动摘要: 用户确认当前仓库名为 `ETN_DOOM`，要求以“阶段 1 文档准备完毕，准备实现阶段 1”保存当前快照；D01–D10 决策、历史研究、知识库迁移及讨论地图作为实现输入。
- Reason / 原因: 保存进入阶段 1 实现前的里程碑。
- Systems / 影响系统: 文档与自制地图输入；不表示新增运行功能或运行验收已经完成。地图中的异常样本保留为错误判例，不自动修复。
- Docs synced / 文档同步: 阶段 1 契约及项目索引已标注当前里程碑；字段实例、完整示例及后续验收仍按契约跟踪。

## 2026-11-14 — 准备从旧方案阶段1开始迁移主要实现方案为移植DOOM
- Correction: 准备按旧方案继续实现阶段 1，是否转向移植尚未决定 → 准备从旧方案阶段1开始迁移主要实现方案为移植DOOM（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/DOOM_CORE_ROUTE_EVALUATION.md`、旧方案总规划、模组摘要、阶段 1 地图契约、`ETNDOOM/PROJECT_MAP.md`、`ARCHITECTURE.md`、`SYSTEMS.md`、`LEARNINGS.md`、`WORKLOG.md`。
- Summary / 改动摘要: 按更新后的 Git 状态重建路线评估，统一迁移准备里程碑；明确目标为还原 DOOM 玩法，先支持原版与 limit-removing，再考虑 Boom/MBF21。保留旧契约及历史，将其定位为迁移对照，记录复用成果、冲突规则、候选内核及后续验证顺序。
- Reason / 原因: 用户要求重新依据当前仓库状态修改文档并提交一次里程碑快照。
- Systems / 影响系统: 仅文档。起点 `57f4cdf`、本轮初始工作区干净；当前没有上一轮临时阶段 1 运行时模块，运行功能仍为阶段 0。本轮未删除、回退或恢复功能代码，不把过去临时实现的回归结果算作当前能力。
- Docs synced / 文档同步: 项目索引、总规划、阶段契约、模组摘要、架构、系统与经验库一致标注“迁移准备”；内核选型、接入方式及规则差异未敲定，未执行新内核构建或游戏回归。本次按用户明确指令提交文档，推送由用户手动执行。

## 2026-11-16 — 确认 M0 迁移策略、资源许可与验收边界
- Correction: 迁移矩阵全部仍为待裁定建议、旧规则可能继续约束原规则基线 → M0 以“ETN 中能运行一个移植 DOOM”为基本需求，用户指定的玩法项继承选定 Source Port；旧命中决策不带入 B0，旧天空与自研导航/刷怪/突袭决策丢弃，弹射物/爆炸/拾取/特殊线/视线保留 B0；原矩阵不改，另加裁定补充表（来源：user）。
- Correction: 旧真实跳跃整体作为待实现 ETN 增量 → 丢弃旧跳跃方案、不移植 ETN 跳跃；Source Port 原生支持则原样移植验证，不支持则功能保持 B2，ETN 姿态/光环滞后/起跳烟尘/音效始终 B2；其余 ETN 规则增量延期 M3（来源：user）。
- Correction: D08 资源语义及 PWAD 覆盖测试列为 M0 必需 → D08 整项 B2，通用 PWAD/其它资源加载不带入 B0；M0 严格限于用户明确给定并允许的 WAD，清单尚未给定，本地 DOOM2.WAD 也禁止未经允许加载（来源：user）。
- Correction: 旧样本槽位与自动对照作为统一验收规划 → Stage0 显示/移动为 B1，供 M2 俯视消费；M0 后复杂地图更多依赖人工验收，MAP02/NoBorder 保留基本可验证的自动回归，地图特例永远优先级最低；原规则基线与可发布边界采用推荐策略（来源：user）。
- Files / 涉及文件: `ETNDOOM/ModdingDocs/M0/` 六份文档、`ETNDOOM/ModdingDocs/DOOM_PORT_DEVELOPMENT_ROADMAP.md`、`ETNDOOM/LEARNINGS.md`、`ETNDOOM/WORKLOG.md`。
- Summary / 改动摘要: 保留原迁移表并新增 §2.1 当前裁定，更新四组决策和测试预期；同步总览、资源/运行时/接口边界及探针样本门槛。未重裁的 D05 主项与 D07 缓存子项继续标为建议；Source Port 及版本行为仍待核实。
- Reason / 原因: 用户按 M0 基本需求明确裁定迁移去向，要求补表而非改写原矩阵。
- Systems / 影响系统: 仅文档与后续实施约束；未改功能代码、未加载 WAD、未运行游戏或构建，未创建提交。
- Docs synced / 文档同步: 当前策略与历史建议分开记录；M0 尚未通过，文档中的加载限制不代表代码已经实现限制。

## 2026-11-16 — 明确最终内核与旧端口切换目标
- Correction: GZDoom/UZDoom 仅作为不确定的远期候选，首版单内核建议可能被理解为永久限制 → 最终使用 GZDoom/UZDoom，支持切换至之前已移植的 Source Port；第一版须满足 M0–M1（来源：user）。
- Files / 涉及文件: `ModdingDocs/DOOM_PORT_DEVELOPMENT_ROADMAP.md`、`ModdingDocs/DOOM_CORE_ROUTE_EVALUATION.md`、`ModdingDocs/M0/README.md`、`ModdingDocs/M0/M0_SELECTION_AND_BUILD.md`、`ModdingDocs/M0/M0_BRIDGE_CONTRACT.md`、`LEARNINGS.md`。
- Summary / 改动摘要: 同步用户明确的长期方向及四候选范围；选型页另记 Crispy Doom 7.2 的建议与源码证据，未将推荐当作已确认选择。
- Systems / 影响系统: 仅文档；未构建、未加载 WAD、未运行游戏，切换粒度及正式候选版本尚未冻结，未创建提交。

## 2026-11-16 — 确认首个内核并收敛桥接设计
- Correction: Crispy Doom 仍为首版候选建议 → 用户确认 Crispy Doom 为首个内核，提供工作区源码 `E:/crispy-doom`（来源：user）。
- Correction: 为多端口预建完全公共桥接接口及各端口通用适配器 → 支持端口数量有限，可能仅 Crispy 与 GZDoom/UZDoom；先按 Crispy 实际需求接入，不追求过度通用化，后续按真实差异复用或调整（来源：user）。
- Files / 涉及文件: `ModdingDocs/M0/README.md`、`ModdingDocs/M0/M0_SELECTION_AND_BUILD.md`、`ModdingDocs/M0/M0_BRIDGE_CONTRACT.md`、`ModdingDocs/DOOM_PORT_DEVELOPMENT_ROADMAP.md`、`ModdingDocs/DOOM_CORE_ROUTE_EVALUATION.md`、`PROJECT_MAP.md`、`LEARNINGS.md`。
- Summary / 改动摘要: 同步选型与设计裁定，保留被替代的建议历史；只读核实本地 HEAD 为 `35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2`，describe 为 `crispy-doom-7.2-1-g35b49519`，工作区干净，相对 7.2 仅多一项 Hexen 指针初始化修复。源码身份不等同于完整构建锁或 M0 验收。
- Systems / 影响系统: 仅文档；未修改 Crispy 或 ETN 功能代码，未加载 WAD、未构建、未创建提交。

## 2026-11-17 — 重申 Crispy Doom 7.2 并给定 M0 WAD 允许清单
- Correction: 本对话仍将试验内核列为待确认 → 用户重申已在其它对话确认为 Crispy Doom 7.2；不重复请求选型（来源：user）。
- Correction: M0 WAD 清单尚未给定、DOOM2.WAD 未获准 → 允许 `E:\ETN_DOOM\etndoom_mod\wad\MAP01.wad` 作为 PWAD，依赖同目录 `DOOM2.WAD` 作为 IWAD，用于自动回归和人工验证；另允许单独加载 `DOOM2.WAD`，主要人工验证，自动回归用于正确加载检查（来源：user）。
- Files / 涉及文件: `ModdingDocs/M0/README.md`、选型/迁移/运行时/探针文档、`ModdingDocs/DOOM_PORT_DEVELOPMENT_ROADMAP.md`、`PROJECT_MAP.md`、`LEARNINGS.md`、`WORKLOG.md`。
- Summary / 改动摘要: 新增探针 §4.1 权威许可清单，按两种组合分别记录用途，消除当前清单缺失的过期状态；保留 7.2 tag 与本地 HEAD 的身份差异及历史记录，未将特定 PWAD 许可扩展为通用资源功能。
- Systems / 影响系统: 仅知识库与实施输入；两份文件存在，未加载 WAD、未构建或运行游戏、未修改功能代码或地图、未创建提交。工作区既有 WAD 删除状态未作处理。

## 2026-11-17 — 清理选型文档的过期候选表述
- Correction: 选型文档仍将 Crispy 写为“首轮主候选之一”“建议首选”，仅靠补充声明覆盖旧正文 → 正文、角色表与决策记录直接统一为 Crispy Doom 7.2 已确认；GZDoom/UZDoom 为最终方向，其它端口仅保留对照和历史取舍定位（来源：user）。
- Files / 涉及文件: `ModdingDocs/M0/M0_SELECTION_AND_BUILD.md`、`WORKLOG.md`。
- Summary / 改动摘要: 同步当前选型状态、实施审计措辞及版本身份，历史变化以 SUPERSEDED 保留；明确未完成的是构建锁与运行验证，不再将内核选择写成待定。
- Systems / 影响系统: 仅文档；未修改功能代码或地图，未构建、未创建提交。

## 2026-11-17 — 明确 G1 授权待裁定
- Correction: G1 授权仍仅作为待核实条件、可能随技术验收被误判已闭合 → 用户明确答复授权尚未确定，标记待裁定；技术实现与本地回归可以继续，但不宣布 G1 或 M0 全部门槛通过（来源：user）。
- Files / 涉及文件: `ModdingDocs/M0/M0_SELECTION_AND_BUILD.md`、`ModdingDocs/M0/M0_SOURCE_AUDIT.md`、`ModdingDocs/M0/README.md`、`LEARNINGS.md`。
- Summary / 改动摘要: 同步本次授权状态确认，不替用户选择项目许可证、不作公开发布；本条仅记录授权裁定，不作为整轮实现结案。
- Systems / 影响系统: M0 G1 与正式组合交付边界。

## 2026-11-18 — M0 完成并通过人工验收，确认 Rev 提交
- Correction: M0 技术实现与自动回归完成、人工体验待确认 → 用户确认预期内 M0 行为全部完成，人工验证通过，M0 已完成；G1 组合发布授权继续待裁定（来源：user）。
- Correction: Obsidian 只忽略部分状态文件、其余配置与主题继续跟踪 → 用户要求忽略整个 `ETNDOOM/.obsidian/`，已跟踪文件只移出 Git 索引，本地文件和用户修改保留（来源：user）。
- Correction: 10 张历史 WAD 的既有删除排除在 M0 提交外 → 用户明确要求纳入本次提交，并确认完成这两项调整后创建 Commit；旧 Stage0 部分夹具已缺失，M0 获准资源与验收不受影响（来源：user）。
- Files / 涉及文件: `etndoom_mod/` 的 M0 构建、原生内核、GDExtension、entry/session/screen、固定源码包与许可证；`ETNDOOM/ModdingDocs/M0/`、移植路线、项目索引、架构/系统增量、经验库及忽略规则。
- Summary / 改动摘要: M0 以 Crispy Doom 7.2-1 固定 commit 接入真实 ETN 发布版；主回归 11 用例 2881 断言、负例 5 类 27 断言通过，700+70 tic 与独立参考逐字段一致。用户本次确认人工通过，更新交付索引并保留原自动快照；保留可复用的人工入口和冻结构建包，清理已被正式入口/最终回归替代的临时探针产物、重复输出及缓存，补齐本地生成物忽略规则。清理共 13 个目标、727 个文件、100.29 MiB，逐文件清单留在本地 `tests/m0_cleanup_20261118/manifest.json`；清理后 47 项构建身份/正式源码/证据/人工入口完整性检查全部通过。
- Reason / 原因: 用户明确敲定 M0 预期行为与人工验收，要求记录完成状态、清理冗余并准备 Rev 分支上的单个 Commit。
- Systems / 影响系统: M0 内核/桥接/宿主接入及后续 M1 交接；本次验收收尾不改运行代码、不重新构建已验收二进制。G1 授权仍待裁定；完整战斗/机关/流程/存档/音频属 M1，最终俯视属 M2。
- Docs synced / 文档同步: M0 总览、人工记录、探针、路线和项目索引统一为“已完成、人工通过”；Git 边界见 `etndoom_mod/README.md`。用户已确认本次 Rev 提交，范围包含整个 Obsidian 文件夹停止跟踪和 10 张历史地图删除；提交信息为“feat: 完成M0内核接入并通过自动与人工验收”，推送由用户手动执行。

## 2026-11-19 — 确认 M1 新增 Doom/DSS 回归资源与补丁边界
- Correction: M1 的 Doom/第三方回归资源尚未落实 → 用户明确允许并要求 `doom.wad` 单独正常运行，以及以其为 IWAD 加载 `dss/DSS.wad` 正常运行；DSS 使用 Crispy 默认读取的内嵌 DEHACKED，外部 `DSS.deh` 仅参考、正常情况下不加载（来源：user）。
- Files / 涉及文件: `ModdingDocs/M1/README.md`、`M1_VALIDATION.md`、`M1_IMPLEMENTATION_PLAN.md`、`M1_PLATFORM_AND_AUDIO.md`、`M1_BRIDGE_CONTRACT.md`（后四项同目录）、`ModdingDocs/DOOM_PORT_DEVELOPMENT_ROADMAP.md`、`PROJECT_MAP.md`、`LEARNINGS.md`。
- Summary / 改动摘要: 新增 M1-W01/W02 与仅参考 M1-R01，记录文件及内嵌补丁哈希，补 V20–V22 正常运行/补丁生效/会话污染回归与阶段门槛。静态确认 DSS 包含 E2/E4 替换地图和 DEHACKED，现有 M0 `-nodeh` 会禁用该默认读取路径，列入 M1 接入任务。
- Reason / 原因: 用户明确补充允许资源与回归要求，替代此前样本待落实状态。
- Systems / 影响系统: M1 资源 profile、Doom episode/map、内嵌补丁、参考构建与回归计划；通用资源功能仍归 M3。本轮仅修改文档并做静态核对，没有修改运行代码、加载游戏或宣称回归通过。
- Docs synced / 文档同步: M1 总览/实施/接口/平台/验收、上位路线、项目索引、经验库与本条 Correction。

## 2026-11-22 — 完成阶段1实现并确认 Rev 提交，验收未完成
- Correction: M1 实现与自动回归交付、人工待验收，尚未提交 → 用户确认阶段1（M1）实现完成，但验收未完成，要求先将本阶段成果作为一个 Commit 提交至 Rev（来源：user）。
- Files / 涉及文件: `etndoom_mod/` 的 M1 构建、ABI 2 内核/桥接、entry/session/screen、流程/存档/观察/资源/音频及锁定依赖；`ETNDOOM/ModdingDocs/M1/`、移植路线、项目索引、架构/系统增量、经验库与开发入口。
- Summary / 改动摘要: 完整单人流程、8 槽事务存档与确定性续跑、地图/BSP/实体/资源接口及 SDL_mixer/OPL2 音频已实现。最终自动回归通过 6102 条宿主/负例断言、39354 tic 独立参考对照、50 次建销与 30 分钟专项；最终包和五组人工入口已准备，证据索引为本地 `tests/m1_results/final_delivery_20261119/delivery.json`，统一人工入口为 `tests/m1_manual/启动M1人工验证.cmd`。
- Reason / 原因: 用户明确要求先提交一个 Commit 到 Rev，并确认当前仅实现完成、验收未完成；本次提交不代替人工验收或宣布 M1 全部门槛结案。
- Systems / 影响系统: M1 原生运行时、GDExtension 桥接、真实 ETN 宿主、构建依赖与 M2 数据交接；M0 历史 ABI 1 入口与源码保留，G1 组合发布授权继续待裁定。
- Docs synced / 文档同步: M1 总览、实施、验收、上位路线、项目索引和开发入口统一阶段状态；提交信息为“feat: 完成阶段1（M1）实现，验收未完成”。本地测试、WAD、构建产物和编辑器配置保留且不纳入提交，推送由用户执行。
