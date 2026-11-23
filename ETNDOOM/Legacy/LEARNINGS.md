> Migration / 迁移（2026-10-30）：ETNDOOM 当前开发根目录为 `E:\ETN_DOOM`。本文历史记录中的 `E:\Enter-The-Nyangeon` 路径保留作为当时证据；现行目录与运行入口见 [`docs/MIGRATION.md`](../docs/MIGRATION.md)。

# Learnings / 经验库

> Scope / 范围：保存 ETNDOOM 新增的本地经验，不复制 `docs/LEARNINGS.md` 的完整历史。
> Maintenance / 维护：`docs/` 下的本地修改可能随远端更新被覆盖；后续 ETNDOOM 经验写入本文件，已敲定的修正与改动记录写入同目录 `WORKLOG.md`。
> Source / 来源：用户 2026-10-23 指定本地保存位置；以下原有条目从 `docs/LEARNINGS.md` 的未提交新增内容承接。
> Date / 日期：2026-10-23
>
> Entry format / 条目格式：
> ```
> ### [System] One-line conclusion / 一句话结论
> - Evidence / 证据: path:line
> - Notes / 说明: ...
> - Source / 来源: code | user | test
> - Date / 日期: YYYY-MM-DD
> ```
> 用户说明优先于代码推断；修正不删史，高影响但低置信的结论放入「待确认 / To Confirm」区。

### [Stage0/Measurement] 用真实碰撞接触帧估算 WAD mu 与旧原型逻辑单位
- Evidence / 证据: `etndoom_mod/stage0/stage0_player.gd:16`；`tests/stage0_checks.gd:261`；`tests/stage0_checks.gd:222`；`tests/stage0_results/20261026_124953/edge_measurement/edge_measurement.json`
- Notes / 说明: Stage0.2 使用实际 Mod entry 和 `move_and_slide()`，固定 `60Hz` 从 MAP01 出生点 `(-128,0)` 向东/西各走到距出生点 `512mu` 的墙，两向均在第 `201` 帧（`3.350s` 游戏物理时间）首次接触。计时和实际离散积分模型给出 `0.995036–1.000081 logical units/mu`；接触位置加根圆半径 `7` 另作核验，得到约 `0.999988`，与旧 Stage0 精确 `1:1` 坐标映射一致。连续加速度公式会漏掉“每帧先更新速度再移动”的离散积分偏移；结合接触位置做末帧插值也不能称为独立的纯计时精度。
- Supplement / 补充: 用碰墙时间换算尺度时，应逐帧累加目标位移，并补回实际形状半径及偏移；首次碰墙只给出一个物理帧区间，位置辅助的末帧插值须另标口径。用户据此确认 V03 后续采用 `1 logical unit = 1mu`，逻辑长度、速度和加速度直接使用 `mu`。详细推导见 `ETNDOOM/ModdingDocs/Stage0/STAGE_0_IMPLEMENTATION.md` §3.1。
- Source / 来源: code + test + user
- Date / 日期: 2026-10-26

## 待确认 / To Confirm

### [Stage0/Mod] 重启后 Runtime 哈希目录变化的来源未确认
- Evidence / 证据: 用户提供路径 `C:\Users\雪楼梯_IceStair\AppData\Local\EnterTheNyangeon\Runtime\ca776eddf163632cefff941c9545f9b4f345368c01c2a195dccb710dca545f22`
- Notes / 说明: 用户确认安装 Mod 后需重启，并观察到重启后该目录会发生变化；尚不确定是否由 Mod 加载导致。不要将目录变化单独当作 Mod entry 或阶段 0 已运行的证据；需通过 Mod 加载日志、entry 参数日志和测试场景断言验证。
- Source / 来源: user
- Date / 日期: 2026-10-22

## Confirmed Notes / 已确认记录

### [Stage0/View] 俯视原型与总体等距目标之间缺少明确的转换验收
- Evidence / 证据: `ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md` §3.1、§4.2；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md` D02、§4.1.2–§4.1.3；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` D01；`etndoom_mod/stage0/stage0_map_view.gd:13`；用户 2026-10-25 的视角说明。
- Notes / 说明: 总规划要求等距投影，0.1/0.2 细化与当前实现则直接按 `(wad_x,-wad_y)` 显示正上方俯视。阶段 1 提到投影/反投影、阶段 4 包含角色表现，所以不能说后续完全没有投影要求；实际缺口是未指定转换步骤、参数、墙面/遮挡与验收。用户预期侧方正交俯视下的菱形方盒；0.1/0.2 自动通过不代表这一视觉目标已经完成。新增 0.3 草案用于讨论，编号、顺序和具体参数仍待确认，不能当作用户已批准的新实施契约。
- Source / 来源: code | user
- Date / 日期: 2026-10-25
- SUPERSEDED: 2026-10-26 用户确认阶段 0.3 正在进行，V01–V04 已裁定；视角转换参数已写入 `STAGE_0_3_VIEW_CONTRACT.md`。当前仍待定的是 V05–V08、V04 数值尺寸和实现验收，0.1/0.2 已验收视角仍须保留为旧基线。（来源：user）
- SUPERSEDED: 2026-10-26 用户后续将 V04 数值尺寸明确为逻辑 `RectangleShape2D(size=Vector2(32,32))`，单位为 `mu`；V04 平面形状/尺寸不再待定，碰撞中心偏移和实现验收仍待补充。0.1/0.2 的旧碰撞基线不变。（来源：user）

### [Stage0/Adaptation] 只断开旧根脚本回调，保留引擎内部连接交由析构维护
- Evidence / 证据: `etndoom_mod/stage0/stage0.gd:98`；`tests/stage0_results/20261024_final/stage01/result.json`；原 Momoi 的四个序列化连接位于 `scenes/player/momoi/momoi.tscn:445`。
- Notes / 说明: 遍历全部 signal 时不能无差别 disconnect 所有连接；Container 会在移除子节点时自行撤销内部布局连接，预先断开会触发不存在连接的错误。适配只清指向旧 Momoi 根的回调，其余不保留子树同步 free；保留子节点移除旧脚本与玩法组后才入树。两模式已验证原玩法节点未 ready、保留子树没有原版全局事件订阅。
- Source / 来源: test
- Date / 日期: 2026-10-24

### [Stage0/Rendering] HDR 2D 视口读回需要保留浮点精度并显式转成 sRGB
- Evidence / 证据: `tests/stage0_checks.gd:277`；`tests/run_stage0_checks.py:119`；`tests/stage0_results/20261024_final/stage01/initial.json` 与 `pixels.json`。
- Notes / 说明: 本机 Forward+、hdr_2d 下完整视口 readback 为 RGBH（每像素 3×float16），直接 save_png 会把线性值当显示颜色，导致图片过暗；先保存原始 RGBH，再由机器编码为 sRGB。世界→截图坐标须包含 stretch×canvas，本项目实际截图 1280×720、逻辑视野 640×360。地图/角色像素均需真实比对，glow 与时间背景用明确区域掩码处理，不能关闭已确认表现。两模式初始截图逐像素一致。
- Source / 来源: test
- Date / 日期: 2026-10-24

### [Stage0/Testing] 源码回归使用独立导入缓存，目录隔离先于 ModManager 启动
- Evidence / 证据: `tests/run_stage0_checks.py:49`；`tests/isolated_godot.py:43`；`tests/stage0_results/20261024_final/restart.json` 与 `summary.json`。
- Notes / 说明: 复用旧 .godot 缓存会缺失当前分支新增资源/全局类。测试复制源码到本地 fixture，独立导入；仅副本排除缺失的 godot_ai 本地 autoload，原 project.godot 不改。启动前重定向 APPDATA/LOCALAPPDATA/XDG_DATA_HOME，并用探针断言真实 user:// 位于临时目录；安装进程以 75 和随机票据退出，同一用户目录的下一进程验证 PCK 挂载/entry。原自定义鼠标在可视进程退出时会产生 RenderingServer 析构错误；本地驱动退出前清空 custom cursor 后该错误消失，不需要修改本体。
- Source / 来源: test
- Date / 日期: 2026-10-24

### [Stage0/Testing] Windows Godot console 程序会转发到实际游戏子进程
- Evidence / 证据: `tests/run_stage0_checks.py:26`；`tests/run_stage0_manual.py`；`tests/stage0_results/20261024_final/manual_entry_smoke.json`；烟测观察到 console PID 36104 的实际子进程 PID 30400，均已结束。
- Notes / 说明: 使用 Godot `_console.exe` 的外部监督器不能只记录转发程序 PID。当前本地 runner 优先选择同目录实际 `.exe`，直接重定向 stdout/stderr 并持有实际 PID；两模式正常主场景入口均已通过限帧退出烟测。该处理只作用于测试工具，不更改游戏可执行文件或注册表。
- Source / 来源: test
- Date / 日期: 2026-10-24

### [Stage0/Readiness] Gate A 已完成，历史待决状态不再阻塞 0.1
- Evidence / 证据: 用户 2026-10-24 明确确认所有待决事项已决策、Gate A 已完成；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md` §1、§7–§8。
- Notes / 说明: Gate A–C 已完成：0.1/0.2 的自动回归、完整截图像素断言与人工验收均通过，人工结果由用户于 2026-10-26 确认。阶段 0.3 正在进行，Gate D 保持未完成；此前“Gate B–D 仍待人工验收”仅为历史状态，由本次用户确认更新。主文档旧 §7 原文迁入 `STAGE_0_DECISION_HISTORY.md`，新 §7 为交付顺序；D10 路径以主文档 §4.1、§6.2 为准。Runtime 目录变化归因是独立调查项，不属于 D01–D10。
- Source / 来源: user
- Date / 日期: 2026-10-24

### [Stage0/D10] 开发中的 MOD 相关内容统一放在 `etndoom_mod`
- Evidence / 证据: 用户 2026-10-24 明确确认；`E:\Enter-The-Nyangeon\etndoom_mod\wad\MAP01.wad`；`E:\Enter-The-Nyangeon\etndoom_mod\wad\DOOM2.WAD`；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md` §1、§4.1、§6.2、§7–§8。
- Notes / 说明: 阶段 0 开发中的 MOD 相关源码、文件、资源和地图统一以 `E:\Enter-The-Nyangeon\etndoom_mod\` 为开发源目录；当前两份 WAD 位于其 `wad\` 子目录。PCK 内部仍按 `res://mods/<mod_id>/` 组织，开发源目录与最终安装包不是同一层级。该决定只确定开发文件边界，不表示功能已经实现或完成运行验收。
- Source / 来源: user
- Date / 日期: 2026-10-24

### [Stage0/D09] 自动回归必须生成完整截图并执行像素级机器校验
- Evidence / 证据: 用户 2026-10-24 明确要求 D09 自动回归包含完整截图与像素级校验，不能以人工检查省略自动步骤；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md` §1、§4.3、§5.3、§6.1、§8。
- Notes / 说明: 0.1、0.2 自动回归均须保存完整游戏视口截图，并从截图像素执行可重复的机器断言，覆盖地图素材/纹理位置、玩家可见状态及相对逻辑/碰撞边界的位置；记录采样区域、时机、阈值/容差和失败像素证据。人工验收只可补充，不能替代、豁免或延后自动截图及像素校验。对滚动背景和 glow 等时变/后处理画面须定义确定性采样条件，不得据此取消像素断言。要求已确认，功能和回归尚未实现；D01–D10 当前均已确认。
- Source / 来源: user
- Date / 日期: 2026-10-24

### [Stage0/D08] D08 已确认，由 D01、D02、D03、D06 共同收束
- Evidence / 证据: 用户 2026-10-24 明确确认 D08 并指定共同收束关系；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md` §1、§3.3.3、§4.2–4.3、§5.1–5.3、§7–§8；`scenes/player/momoi/momoi.tscn:33-34,260-272`。
- Notes / 说明: 以 D02 映射后的 WAD 逻辑矩形为准，边界线本身不算地图外。0.1 使用玩家 `CharacterBody2D.global_position` 严格越界并在外侧停留作为断言；0.2 按实际根碰撞圆（半径 `7`、局部偏移 `(0,-6)`）与边界内侧的物理接触判定，不只检查根节点未出界。纹理像素、墙带外沿、背景覆盖范围和脚底锚点不作为逻辑真源；详细契约以开发细化文档为准。该条记录时 D09、D10 尚待确认；功能尚未实现。
- Source / 来源: user
- Date / 日期: 2026-10-24
- SUPERSEDED: 2026-10-24 本条记录中的“D09、D10 尚待确认”仅表示 D09 确认前；D09 已按本文件及开发细化文档 §6.1 执行，D10 现已由用户确认，当前 D01–D10 均已确认。（来源：user）
- SUPERSEDED: 2026-10-24 本文件早期 D04、D05、D06、D07 条目中的“D08–D10 仍待确认”及“Gate A 仍需 D08、D10”仅表示当时状态，现由本条及开发细化文档 §8 替代；旧调查事实与既有决策继续有效。（来源：user）
- SUPERSEDED: 2026-10-24 本文件其它历史条目中的“仅 D08–D10 待确认”或“D10 待确认”均表示 D10 裁定前的状态；用户随后确认开发源目录为 `E:\Enter-The-Nyangeon\etndoom_mod\`，当前 D01–D10 均已确认。（来源：user）

### [Stage0/D07] D07 已确认：阶段 0 相机由测试场景独立持有
- Evidence / 证据: 用户 2026-10-24 明确要求将推荐方案落地为 D07 决策；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md` §1、§3.3.2、§4.2–4.3、§8–9；`scenes/player/momoi/momoi.tscn:420-421`；`scenes/game_camera/gamecamera.tscn:59-88`；`scenes/game_camera/gamecamera.gd:26-89`；`script/GameEvents.gd:56-59,661-672`。
- Notes / 说明: 阶段 0 测试场景创建并持有独立 `Camera2D`，显式跟随阶段 0 玩家，初始观察中心为按 D02 映射后的出生点；0.1 与 0.2 共用同一相机配置。相机不挂入 Momoi 子树，不继承原版 `(0,-15)` 偏移、准星前导、全局镜头/震屏信号、黑幕遮罩或 `"PlayerCamera"` 组。原版相机脚本连接 `crosshair_position`、`camera_move`、`camera_reset`、`shake_screen`；正常跟随按逻辑视口中心 `(320,180)` 计算准星前导，演出时可锁定 `Marker2D` 并改变 zoom；场景还启用位置平滑（速度 10）。这些是原版代码事实，不属于阶段 0 契约。独立持有使相机不随 Momoi 场景或未来实体管理器重置；D10 已确认开发源目录，功能尚未实现。
- Source / 来源: user
- Date / 日期: 2026-10-24

### [Stage0/D06] D06 已确认：原 Momoi 场景入树前适配，由模组自有最小根逻辑独占移动
- Evidence / 证据: 用户 2026-10-24 明确要求将上一轮建议落地为实际决策并标记 D06 已决策；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_MOMOI_ANALYSIS.md` §6、§8.3；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md` §1、§3.3.1、§8；`ETNDOOM/ModdingDocs/ENTITY_MANAGEMENT_RECOMMENDATION.md` §6.1。
- Notes / 说明: 固定实例化原 Momoi 场景，保留同一物理体、根形状与必要外观，提取基础移动参数后移除旧 `Stats`；入树前处理旧根连接、玩法子树和原版玩法组，新根直接继承 `CharacterBody2D`，一个物理回调执行一次移动并更新必要表现。沿用基础速度 `155`、`SPEED_TIME=0.2`、每轴加减速、半径 `7`/偏移 `(0,-6)`，0.1 禁用碰撞、0.2 使用墙体 mask `256`；朝向按水平移动意图，停止或纯竖向移动保持上次朝向。阶段 0 不建设完整实体管理器，相机归 D07；验收 ETNDOOM 接管后的移动路径。D06 已移入已确认决策；Gate A 的 D08、D09、D10 前置条件均已满足，功能尚未实现。
- Source / 来源: user
- Date / 日期: 2026-10-24
- SUPERSEDED: 2026-10-24 本条原位于「待确认 / To Confirm」，来源为 code，表述为工程推荐；用户确认后移入已确认记录并将来源改为 user。后文旧条目中“D06 待确认/未裁定”的状态统一由本条及阶段 0 开发细化文档替代，原调查事实与讨论历史保留。
- SUPERSEDED: 2026-10-24 本条早期“Gate A 仍需 D07”的状态仅适用于 D07 未决阶段；用户已确认 D07，当前 Gate A 的未决阻塞项见阶段 0 开发细化文档 §8，D08、D10 仍须先确认。（来源：user）

### [Stage0/Mod] D04 已确认使用独立测试 Mod entry 作为开发者入口
- Evidence / 证据: 用户 2026-10-22 明确确认；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md:20`、§3.1、§6.2；`script/mod_manager.gd:89-105,1059-1079`。
- Notes / 说明: 安装并启用测试 Mod 后重启，entry 随 Mod 启动；唯一有效的 `--stage0=0.1/0.2` 才延迟切入测试场景，无参数、无效或重复参数均不接管。入口不依赖 COOP Mod，不走 `change_scene_gate`；D05–D10 的决策均已完成，Runtime 目录变化成因仍未确认。决策完成不表示功能已实现。entry 前已执行存档读取，自动回归必须在启动进程前隔离用户目录；完整约束以阶段 0 文档为准。
- Source / 来源: user + code
- Date / 日期: 2026-10-22

- SUPERSEDED: 2026-10-23 D05 已通过场景节点清单整体确认；本条原“D05–D10 仍未确认”改以 D06–D10 仍待确认为准，D04 入口契约不变。（来源：user）
- SUPERSEDED: 2026-10-24 D06、D07 已分别确认；本条历史状态中“D06–D10 仍待确认”不再代表当前状态，现仅 D08–D10 待确认，D04 入口契约不变。（来源：user）

### [Stage0/Scene] 场景需大幅重做，复用须区分容器、角色资产与玩法脚本
- Evidence / 证据: 用户补充 D01–D03 基本确认后场景需要大幅重做、可复用节点有限；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_NODE_REUSE_CANDIDATES.md`；`scenes/main/main.tscn:171-422`、`scenes/player/momoi/momoi.tscn:260-310,393-427`。
- Notes / 说明: D04 是已确认的测试 Mod 入口，节点取舍仍属未裁决的 D05，角色和相机方式分别属 D06/D07。`main.tscn` 自身没有相机；Momoi 的相机来自 `gamecamera.tscn`。待机/跑步动画在 `AnimatedSprite2D.sprite_frames`，两个 `AnimationPlayer` 是受击/踢击；根碰撞圆半径 7、偏移 `(0,-6)`，也不等于 HurtBox/PickBox。沿用空容器职责不代表要继承整张 main 场景或带入全局组与回合逻辑；候选详表见专题文档，不据此冻结保留清单。
- Source / 来源: user + code
- Date / 日期: 2026-10-23

- SUPERSEDED: 2026-10-23 用户明确 Momoi 有关节点不在阶段 0 节点复用讨论范围；上述角色细节仅保留为旧盘点事实，不再作为当前 D05 推荐。特效、伤害跳字、光照和 HUD 均不引入阶段 0；glow 与场外滚动背景按低成本条件保留候选，详见下方新记录。（来源：user）

### [Stage0/Rendering] 滚动背景与场地图像分开评估，glow 不等于实体描边
- Evidence / 证据: 用户 2026-10-23 对节点清单的七项反馈及 Momoi 范围说明；`scenes/main/main.tscn:37-66,176-239,315-338`；`shaders/scrolling_bkgd.gdshader:1-24`；`shaders/sprite_outline.gdshader:12-31`；`project.godot:252`。
- Notes / 说明: `Control/ColorRect` 是最底层纯色铺底，不负责矩形场内纹理；实际滚动核心是 `Control/TextureRect`，依赖 1 份材质、24 行 shader 和 `test_BG.png`，可连父节点与纯色底以共 3 个节点组织，无 GDScript/回合信号依赖。两个 `BackLayer` 渐变和 `MapTest2` 是上层静态场地表现，其中 `BackLayer/ColorRect` 实际为 `TextureRect`。滚动 shader 不感知 WAD 边界，复用须调整覆盖范围并明确场内遮盖/裁剪方式。`WorldEnvironment` 仅 1 节点 + 1 份含 3 项显式配置的资源，无脚本；glow 是亮部泛光，实体轮廓由各自材质生成，不能将全局 glow 说成“给所有实体描边”。两项成本低，按用户要求保留为可考虑候选，未据此批准启用。用户明确 `SELayer`、`ForegroundLayer`、`Light`、`ChipHud`（用户称 `ChipH`）阶段 0 不引入；后续特效/跳字可重新加入，光照很可能沿用 DOOM，HUD 可重新加入或弃用重做，具体后续方案未定。Momoi 有关节点退出当前讨论；既有角色约束及 D06/D07 不由本轮另行裁决。
- Source / 来源: user + code
- Date / 日期: 2026-10-23

- SUPERSEDED: 2026-10-23 用户后续确认全局泛光与场外滚动背景都复用，原“仅保留候选、未批准启用”已失效；`ChipHud` 后续明确会加入并修改，不再并列保留弃用方向。当前场景节点按确认清单执行，详见下方 D05 记录。（来源：user）

### [Stage0/Scene] D05 场景节点取舍已确认，泛光与场外滚动背景均复用
- Evidence / 证据: 用户 2026-10-23 明确“全局泛光与场外滚动背景都复用”，并接受其余带入/不带入建议；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_NODE_REUSE_CANDIDATES.md` §2–§6；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md` §1、§7–§8。
- Notes / 说明: D05 收束为重建独立测试场景，按清单复用根 `Node2D`、`YSort`、`YSort/PlayerRoot`、`BackLayer`、`FloorLayer`、`BattleRoom`、`Control`、`Control/ColorRect`、`Control/TextureRect`、`WorldEnvironment` 共 10 个节点及必要资源；原主场景脚本、地图几何、玩法系统与场景 HUD 不带入。glow 复用并启用；滚动背景沿用材质/shader/贴图，由上层 WAD 地面遮盖场内，覆盖范围按测试视野适配。容器挂载、尺寸适配及组名隔离属于实现工作，当前没有额外需用户裁决的场景节点。`ChipHud` 阶段 0 不引入，后续会加入并修改；具体修改内容留到后续阶段。Momoi 有关节点不在本次确认范围，D06–D10 的决策均已完成，未满足其余实施闸门前不开始功能实现。
- Source / 来源: user
- Date / 日期: 2026-10-23
- SUPERSEDED: 2026-10-24 本条记录时 D06、D07 尚未裁定；两项随后分别获用户确认，当前仅 D08–D10 待确认，D05 场景清单继续有效。（来源：user）
- SUPERSEDED: 2026-10-24 上述“当前仅 D08–D10 待确认”是 D08、D09、D10 确认前的历史状态；三项现均已确认，D05 场景清单继续有效。（来源：user）

### [Documentation] ETNDOOM 新增知识与改动记录保存在本地目录
- Evidence / 证据: 用户 2026-10-23 指出 `docs/` 下的修改会随远端更新被覆盖，要求在 `E:\Enter-The-Nyangeon\ETNDOOM` 下创建同名文件，写入新增内容。
- Notes / 说明: 本文件承接 `docs/LEARNINGS.md` 的 ETNDOOM 新增条目，同目录 `WORKLOG.md` 承接新增改动记录；后续 ETNDOOM 记录以本地同名文件为保存位置。本体 `docs/` 仍可作为参考资料，不据此复制或重写其完整历史。
- Source / 来源: user
- Date / 日期: 2026-10-23

### [Stage0/Player] D06 复用 Momoi 玩家实体验证移动，具体技术方式仍待确认
- Evidence / 证据: 用户 2026-10-23 明确 Momoi 是玩家可用角色中的一个实体、阶段 0 需要复用她验证移动；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_MOMOI_ANALYSIS.md`；`scenes/player/momoi/momoi.tscn:260-272,357-368`。
- Notes / 说明: 此前 Momoi 退出的是 D05 场景节点清单的讨论，不表示阶段 0 排除角色。D06 的对象是实际承载位置、速度及物理移动的 Momoi 实体，不应退化为只移动一张贴图。原版以 `CharacterBody2D`、根碰撞圆和通用 `Player` 脚本组成实体；原场景加载路径继续受 C02 约束，保留原逻辑并隔离、入树前适配或复制裁剪尚未选择。本次只补充定位与源码分析，没有批准实施。
- Source / 来源: user + code
- Date / 日期: 2026-10-23

### [Stage0/Player] 原版移动由子状态机驱动，删玩法节点必须同时处理根逻辑硬引用
- Evidence / 证据: `scenes/player/StateMachine.gd:4-22`；`script/player.gd:56-108,225-325,341-423`；`script/player_gun.gd:33-52`；`scenes/player/momoi/MomoiPS.gd:16-20`；`script/Stats.gd:31-32`；`scenes/player/momoi/momoi.tscn:33-34,270-272,360-368`。
- Notes / 说明: `StateMachine` 调用 `owner.get_next_state/transition_state/tick_physics`，移动不在玩家根的 `_physics_process` 中。平面移动按每轴 `move_toward` 更新速度，再 `move_and_slide()`；Momoi 基础速度 155、`SPEED_TIME=0.2`，根碰撞圆半径 7、偏移 `(0,-6)`。`move()` 的同名 `MAX_SPEED` 形参未用于目标速度，实际读取 `stats.MAX_SPEED`。待机/跑步仍访问枪、跳跃计时器、受击、光环和脚步；只删节点、隐藏武器、关闭根物理回调或限制状态都不足以完整隔离。关闭逐帧处理也不撤销 MomoiPS 等已连接的信号。详见角色分析，不把静态读取当作运行验收。
- Source / 来源: code
- Date / 日期: 2026-10-23

### [Stage0/Player] 根逻辑有多种调用入口，模组接管须在原就绪流程前准备并显式迁移配置
- Evidence / 证据: `script/player.gd:56-108,204-297`；`scenes/player/StateMachine.gd:4-22`；`script/player_gun.gd:33-52`；`scenes/player/momoi/momoi.tscn:445-448`；`script/mod_manager.gd:1059-1079`；Godot 官方文档 `Node`、`Object.set_script()`、`GDScript reference` 初始化顺序；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_MOMOI_ANALYSIS.md` §7–§8。
- Notes / 说明: Godot 分别触发根的就绪/输入和子节点的物理回调，状态机调用根的普通方法，全局信号另行调用已连接的方法。没有一个原版实体管理器统一运行根的全部逻辑。模组可提供自有脚本；若实例化原 Momoi 场景后替换根，须在入树前处理子树、组及序列化信号连接，并保存/显式赋予需要的配置。`set_script()` 丢弃旧脚本属性和状态，保留内建属性；`instantiate()` 阶段已可能执行 `_init()` 与导出赋值，不能称为完全无初始化。模组自有实体控制及管理分层仅为建议，D06 未确认，未验证该接管方案的实际运行。
- Source / 来源: code
- Date / 日期: 2026-10-23

### [WAD/Entities] 实体结构相似不等于地图行为兼容，调度与体型也会改变结果
- Evidence / 证据: `E:/DOOMSourceCode/linuxdoom-1.10/doomdata.h:203-210`、`p_mobj.c:753-796`、`p_enemy.c:1616-1722`、`p_tick.c:65-120`、`info.c:1124-1126`、`p_map.c:252-342`；`scenes/player/momoi/momoi.tscn:33-34,260-272`；`ETNDOOM/ModdingDocs/ENTITY_MANAGEMENT_RECOMMENDATION.md`。
- Notes / 说明: 经典 `THINGS` 只提供出生记录，类型和动作依赖引擎定义；DOOM II `MAP07` 还依赖特定 Boss 死亡与 tag 666/667 触发。thinker 中新对象可能同 tic 更新，改成统一帧末生成会改变顺序。Momoi 根圆半径 7、偏移 `(0,-6)`，DOOM 玩家 radius 16、height 56，且普通物体相互阻挡使用轴向范围判断；复用形状不等于复现 DOOM 通行。以上为源码事实与兼容风险推论，未运行对照；架构方案及 D06 仍待用户决定。
- Source / 来源: code
- Date / 日期: 2026-10-23

### [Entities/Ownership] 原版场景容器、组、池与活跃登记是不同集合，不能由新管理器自动接管
- Evidence / 证据: `scenes/main/main.tscn:295-318`；`scenes/player/utaha/UtahaPS.gd:59-74`；`scenes/manager/pick_item_manager.gd:51-69`；`scenes/manager/PoolManager.gd:125-136,140-169,257-288,427-447,485-519`；`script/map_bounds.gd:24-62`；`ETNDOOM/ModdingDocs/ETN_ENTITY_MANAGEMENT.md`。
- Notes / 说明: 原版由 Godot 调度节点，各类生成器、组件、对象池和清场代码分别管理业务，没有覆盖所有玩法实体的统一更新循环。`PlayerRoot` 还容纳召唤物，`CoinRoot` 还容纳医疗品；池中节点不等于活跃实体，`clear_pool/erase_pool/detach` 不释放节点，普通死亡回池也不同于回合清场释放。`MapBounds` 等全局消费者还会按原组和活跃敌人表直接改变位置，新管理器的登记本身不会隔离这些行为。详表与生命周期已上提至专题文档。
- Source / 来源: code
- Date / 日期: 2026-10-24

### [Entities/Clock] 普通战斗的 0.1 秒全局 tick 由 RoundTimer 场景产生，移除 HUD 场景需处理计时来源
- Evidence / 证据: `ui/round_timer.tscn:465-471`；`ui/round_timer.gd:132-137,508-509`；`script/GameEvents.gd:575-576`；`script/EnemyStateMachine.gd:12-33`；`scenes/main/test_room.gd:130-131`。
- Notes / 说明: `GameEvents` 只包装并广播 `global_time_count`；正常战斗由 `RoundTimer/GlobalTimer` 超时发信号，测试房另有 Timer。删掉承载该 Timer 的场景与仅隐藏 HUD 不同；继续复用依赖该信号的敌人、Buff、弹丸寿命等逻辑时，不能假定 autoload 会自行维持 tick。敌人状态机每 3 个全局 tick（约 0.3 秒）重评状态，但每个物理帧仍执行 `tick_physics()`；不能把这两种频率混为一谈。本轮仅静态核对，未验证独立模式计时。
- Source / 来源: code
- Date / 日期: 2026-10-24

### [Entities/Scope] 阶段 5/7 敌怪将大幅重做或新设计，实体管理不以整体接管原版敌怪行为为目标
- Evidence / 证据: 用户 2026-10-24 明确为适配 DOOM 地图与 DOOM 的逻辑，阶段 5 与阶段 7 的原版敌怪必然大幅重做，或者直接设计新的敌怪；`ETNDOOM/ModdingDocs/ENTITY_MANAGEMENT_RECOMMENDATION.md` §1.1、§6–§7；`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md` §1、§4.2；`ETNDOOM/ModdingDocs/ETN_ENTITY_MANAGEMENT.md` §7。
- Notes / 说明: 修正此前偏重原版实体接管与迁移成本的评估前提。新实体管理应服务于 ETNDOOM 重做或新设计的敌怪，无需将整体接管原版敌怪既有运行逻辑设为目标。新增管理器不会自动取得旧行为所有权的技术事实仍成立，仅用于实际复用部分的依赖和隔离分析；素材、独立配置可按需复用。成本以敌怪本就需要重做为基准，分别评估管理职责的增量成本与收益。全面实体管理架构尚未裁定，阶段 0 复用 Momoi 玩家实体验证移动的要求及 D06 状态不变。
- Source / 来源: user
- Date / 日期: 2026-10-24

### [Mod/Testing] MOD 页的「立即重启」只退出进程，无人值守回归必须由外部监督进程重启
- Evidence / 证据: `script/mod_option.gd:744-749`（确认后仅 `get_tree().quit()`）；`script/mod_manager.gd:89-105`（扫描/挂载只在 `_ready()`）；`script/mod_manager.gd:1425-1430`（启停只写状态）；`tests/isolated_godot.py:12-17,37-58`（隔离 `user://` 与预装 PCK）；`tests/run_coop_extension_contract_checks.py:36-45`（预装后新进程验证真实 ModManager/entry）。
- Notes / 说明: PCK 挂载后无法在当前进程卸载，`import_zip()` 也只交换磁盘目录，不会把新包补进本次启动的 `_mods` / 注册表。因此自动回归应采用「外部监督 + 同一隔离用户目录 + 两次启动」：第一进程安装并以明确退出码/票据请求重启，第二进程由 `ModManager._ready()` 自动扫描挂载，再检查 `enabled/mounted/error`、注册资源和 deferred entry。高频测试可直接预装包后单次启动，但这不会覆盖 ZIP 安装事务。不要依赖点击 UI，也不要把项目根 `mods/` 当作运行时安装目录。
- Source / 来源: code + user
- Date / 日期: 2026-10-24

### [Stage0/View] V06 采用逻辑 2D + 3D 表现，以深度缓冲实现墙体与角色的自然遮挡
- Evidence / 证据: 用户 2026-10-27 裁定；`E:/isodoom/src/Render/LevelCamera.cs:10,35`；`E:/isodoom/shaders/level.gdshader:6`；`E:/isodoom/shaders/sprite.gdshader:5`；`E:/isodoom/shaders/sprite.gdshaderinc:24-25`；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md` V06。
- Notes / 说明: 平面移动、碰撞、导航和距离继续在 `(u,v)` 2D 空间运行；V02 的独立高度标量 `h` 仍来自逻辑数据，0.3 不引入 3D 物理。表现层使用同一 WAD 轴向映射的 3D 世界和正交 `Camera3D`，地面、墙体与角色通过同一深度缓冲按相机空间逐像素深度测试自然遮挡；相机空间更近的片元胜出，不依赖绘制顺序或 `z_index`。双面 linedef 的两侧各使用自己的 sidedef/UV，但固定相机下由朝向/背面剔除仅让朝相机一侧输出。WAD 透明孔洞由 alpha cutout 丢弃且不写深度；角色透明像素拟按 alpha cutout 丢弃，阈值与可行性待人工确认，竖直 billboard 暂作阶段 0 基线。角色精灵高 `56mu`，脚底对齐逻辑锚点，源纹理等比缩放至目标高度，不限定像素尺寸；墙体自然遮挡角色完整高度，允许角色完全不可见。阶段 0 不创建或渲染阴影，V04 阴影锚点仅保留作后续接口。DOOM WAD 墙边与地面边没有重复区域，阶段 0 不加 z-fighting 预防偏移或额外几何，若实际出现再据复现调试。`Camera3D.near/far` 按最终相机空间几何范围和 V06 已确认的 margin 公式计算，具体值待 V07 相机取景冻结。用户于 2026-10-28 裁定阶段 0 不考虑 `cutaway`、`dither`、`wall pull`、`upright hiding` 及之后所有用于提高可读性的同类策略。`MAP01_BackWall.wad` 与 `MAP01_FrontWall.wad` 是专用遮挡夹具；当前 `stage0_wad.gd:102-103` 的四顶点/单 sector reader 尚不能加载它们。
- Source / 来源: user + code
- Update / 更新: 2026-10-28 确认不考虑可读性策略；2026-10-29 确认阶段 0 不实现阴影、角色精灵参数及 V06 深度比较/双面 linedef/Camera3D 范围规则，并规定 z-fighting 若出现再调试。（来源：user）
- Date / 日期: 2026-10-29

### [Stage0/V08] 阶段 0.3 回归固定为显式开启逻辑碰撞
- Evidence / 证据: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md` V08；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md` §3.1、§6.1–§6.2。
- Notes / 说明: V08 只验收 `--stage0=0.3 --stage0-collision=on`。0.1/0.2 的既有自动、截图和人工证据保留为历史基线，但本轮不再重跑；`--stage0-collision=off` 不列为测试项。入口仍需拒绝重复、混合、无值和非法参数；0.3 的实现应显式记录解析后的 `collision=on`，不能通过 stage 名称隐式推导。
- Source / 来源: user
- Date / 日期: 2026-10-29


### [Stage0/View] V04 已裁定逻辑空间 `32×32mu` 矩形碰撞与独立表现锚点
- Evidence / 证据: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md` §3.4（2026-10-29 重排后）；`scenes/player/momoi/momoi.tscn:270-272`；`etndoom_mod/stage0/stage0.gd:88-90`；`E:/DOOMSourceCode/linuxdoom-1.10/info.c:1125-1126`；`E:/DOOMSourceCode/linuxdoom-1.10/p_map.c:88,136-139,197`。
- Notes / 说明: 用户更正并确认 V04：Stage 0.3 的 Momoi 平面碰撞为逻辑轴对齐 `RectangleShape2D(size=Vector2(32,32))`，单位为 `mu`；实体根点、矩形中心与逻辑脚底锚点分别定义，脚底与阴影读取逻辑锚点后投影。`32×32mu` 匹配 DOOM `MT_PLAYER` 的名义平面包围范围（`radius=16mu`），但不代表复刻完整墙线/高度规则；`height=56mu` 仍需独立竖直规则。只覆盖 Stage0.3 适配实例；0.1/0.2 保持原根圆 `radius=7`、偏移 `(0,-6)`。
- Source / 来源: user + code
- Date / 日期: 2026-10-26
- SUPERSEDED: 2026-10-26 用户将此前采纳的“V04 使用逻辑圆形碰撞”更正为 `RectangleShape2D` 且完整尺寸 `32×32mu`；圆形方案不再是现行约束。（来源：user）


### [Stage0/View] V04 平面锚点与 V05 地面采样已裁定
- Evidence / 证据: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md` §3.4–§3.5（2026-10-29 重排后）。
- Notes / 说明: 用户于 2026-10-27 确认：Stage 0.3 中逻辑根点、`RectangleShape2D` 矩形中心和逻辑脚底锚点的平面偏移均为 `(0,0)`；V05 只确认地面按逻辑坐标采样，地面 UV 保持 WAD/逻辑平面坐标后再投影几何。墙面延展、闭合、厚度、顶面、墙面 UV 及 V06–V08 暂不决策，相关内容只能作为未决建议或 isodoom 参考。
- Source / 来源: user
- Date / 日期: 2026-10-27
- SUPERSEDED: 2026-10-28 用户进一步裁定 V05 墙体范围与纹理采样参数；旧的“墙体延展等均暂不决策”状态仅保留为当日历史记录，现行边界见下条。


### [Stage0/View] V05 墙面范围与纹理采样参数已裁定
- Evidence / 证据: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md` §3.5–§3.6（2026-10-29 重排后）；`ETNDOOM/ModdingDocs/ISODOOM_SECTOR_WALL_RENDERING_REFERENCE.md:71-83`。
- Notes / 说明: 用户于 2026-10-28 确认：阶段 0 只渲染 WAD linedef 对应的墙面本身，墙体延展、端部闭合、厚度和顶面均不考虑；当前单面墙的竖直渲染范围使用其 front sector 的 floor-to-ceiling 区间，但不把该显示范围当作通行高度。地面与墙面按源纹理原生尺寸 `1 texel/mu` 采样，nearest 过滤、启用 mipmap、不启用各向异性过滤，UV 越界按源纹理实际宽高 repeat。该方案锁定采样参数，不锁定通用墙面 UV 锚点、pegging 或双面 sector wall-section 规则；这些留给后续 DOOM WAD 读取阶段。
- Source / 来源: user
- Date / 日期: 2026-10-28

- SUPERSEDED: 2026-10-29 用户补充阶段 0 必须回归 `MAP01.wad`、`MAP01_BackWall.wad`、`MAP01_FrontWall.wad` 和 `MAP01_Texture.wad`；`textureoffset` 与 `Upper/Lower Unpegged` 不再视为未来阶段能力。现行夹具矩阵与 WAD 字段派生规则见下条。


### [Stage0/View] V05/V06 三类 WAD 回归矩阵已确定
- Evidence / 证据: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md` §3.5–§3.6（2026-10-29 重排后）；`ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md:14,203-219,436`；`ETNDOOM/ModdingDocs/ISODOOM_SECTOR_WALL_RENDERING_REFERENCE.md:3-6,72-86`；`etndoom_mod/wad/MAP01_Texture.wad`。
- Notes / 说明: 用户于 2026-10-29 确认，阶段 0 必须做三类 WAD 回归：`MAP01.wad` 最简地图；`MAP01_BackWall.wad` 与 `MAP01_FrontWall.wad` 墙渲染/自然深度遮挡；`MAP01_Texture.wad` 贴图属性。四张实际输入都必须从真实 WAD 字段驱动，不能用场景参数模拟。Texture 夹具覆盖 sidedef 三类纹理槽、统一 `textureoffset`/`rowoffset` 字段及 linedef 的 `Upper Unpegged`/`Lower Unpegged` flags；one-sided middle 的垂直锚点由 `Lower Unpegged` 决定，`Upper Unpegged` 必须正确读取且不能错误套用于 middle。Back/Front 夹具覆盖双 sector、双面 `MIDGRATE` 透明墙、sector 高差和近/远墙深度遮挡。完整双面 wall-section 组合、动态 sector、高度补面和 caps/lids 仍属于未来扩展，但不再把 `textureoffset`/pegging 从阶段 0 排除。
- Source / 来源: user + code
- Date / 日期: 2026-10-29


### [Stage0/View] V07 相机硬跟随、可变视野与 overview 取景已裁定
- Evidence / 证据: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md` §3.7（2026-10-29 重排后）。
- Notes / 说明: 用户于 2026-10-29 确认，Stage 0.3 游戏取景由独立正交 `Camera3D` 硬跟随逻辑脚底锚点；允许沿世界竖直方向固定上移，使相机中心对准 `56mu` 角色中心，默认偏置为 `28mu`。`Camera3D.size` 可在 `640..1600mu` 范围内按 `10mu` 调整；该值只改变可见范围，不改变逻辑坐标、UV 或碰撞。overview 使用同一相机的独立取景配置，按当前地图投影内容包围范围等比适配，所有内容必须完整入画，并以距离窗口边缘约 `10%` 为目标而非严格等式。阶段 0 回归视口固定为 `1600×900px`；overview 与跟随模式分别计算 `near/far`。`1600×900` 是窗口像素分辨率，不能写成逻辑 `mu` 尺寸。
- Source / 来源: user + code
- Date / 日期: 2026-10-29



### [Stage0/View] 0.3 设计已全部决策，坐标映射不得重复翻转 WAD Y
- Evidence / 证据: `ETNDOOM/ModdingDocs/Stage0/STAGE_0_3_VIEW_CONTRACT.md` §3.1–§3.2、§3.8、§4；`E:/isodoom/src/Render/LevelMesh.cs:544`；用户 2026-10-29 本轮说明。
- Notes / 说明: V01–V08 全部决策完成；角色透明边缘人工验收、常用视野和实际 near/far 校准属于实现工作，不再列作设计未决项，Gate D 仍待完成。逻辑 `v=-wad_y` 与既定 `world_z=-wad_y` 合并后为 `world=(u,h,v)`、逆向 `logical=(x,z,h)`；旧稿额外负号已修正。V08 只验收碰撞开启，0.1/0.2 证据保留不重跑。
- Source / 来源: user + code
- Date / 日期: 2026-10-29
- SUPERSEDED: 此前条目中的 V06–V08 未决状态仅作历史保留；现行规范与实现缺口统一见视角契约。

> Migration / 迁移（2026-11-13）：本次承接 `docs/LEARNINGS.md` 相对 Git HEAD 的全部未提交新增内容；本体原文仍见 [`docs/LEARNINGS.md`](../docs/LEARNINGS.md)。旧记录中的 `docs/` 路径表示当时写入位置，不据此恢复旧维护方式。

### [Stage0/Map] 原型 map_id 固定为 MAP01，不能直接用作正式地图身份
- Evidence / 证据: `etndoom_mod/stage03/wad.gd:48`（只查找 MAP01 marker）、`:128`（输出固定 map_id）；`etndoom_mod/stage03/stage03.gd:11`（五张夹具按文件名区分）。
- Notes / 说明: 当前读取器给不同夹具输出相同的 `map_id="MAP01"`，不能据此建立唯一地图目录或关联出生/遭遇配置。阶段 1 D08 须另定稳定身份及其与 WAD marker、文件名的关系；阶段 0 的固定内部字段不等于正式格式决策。
- Source / 来源: code
- Date / 日期: 2026-10-31

### [Stage1/Map] 精确 sector 与 mu 高度不能量化为网格/等级，跨步在移动时判定
- Evidence / 证据: 用户 2026-11-01 的 D01/D02 补充；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3.1–3.3；`etndoom_mod/wad/MAP02_UnstableMapBoundary.wad` 的 vertex 23（逻辑坐标 `(-610,482)`）、sector 0/5（floor 为 `1/25mu`）。
- Notes / 说明: SUPERSEDED: 上一轮讨论建议的规则地形网格候选、外部/内洞分型、`height_level×8mu` 和显式楼梯授权均被用户否定。保留精确区域和直接 mu 高度，无 sector 区域统一为无地面；静态楼梯只是不同高度的 sector，玩家最大向上跨步 `24mu`，移动时结合当前脚底高度与接触几何判定，不预写相邻区域可通行标签。因此无遮挡时 MAP02 的 24mu 高台、变体的 1→25mu 高台都满足跨步高度条件；不能强迫玩家只沿指定楼梯链。详细规则集中在阶段 1 契约，尚未实现。
- Source / 来源: user | code
- Date / 日期: 2026-11-01

### [Stage1/Cursor] isodoom 的 BSP 候选仍需地面覆盖验证，兜底点不代表有地面
- Evidence / 证据: 外部只读参考 `E:/isodoom/src/Render/CursorGround.cs:43,93`、`src/Game/LevelScene.cs:1518,2634`、`src/Render/PlayerSprite.cs:40`；参考版本与完整语义见阶段 1 契约 §3.4。
- Notes / 说明: 鼠标向下射线按实际地面高度依次求交，BSP 仅缩小候选，再验证地面三角形覆盖；仅取得 subsector/sector 不能证明该点有地面。未命中时用玩家当前表现脚底高度平面兜底，但返回 `Sector=-1` / `OnFloor=false`，不可当作可站立区域。该查询忽略墙面，输入只消费平面坐标；不自动定义子弹遮挡或垂直瞄准。用户指定参考 isodoom，具体忽略墙面和兜底行为仍待裁定；本地参考仓库不是构建依赖。
- SUPERSEDED: 2026-11-03，先前将鼠标命中/兜底作为 D01 子问题的归属有误；用户明确全部移入 D06。BSP 候选须核实实际覆盖仍是通用几何认知，鼠标如何使用查询结果由 D06 定义。
- Source / 来源: code | user
- Date / 日期: 2026-11-03（初记：2026-11-01）

### [Stage1/Contract] D01 须定义查询和边界归属，鼠标行为属于 D06
- Evidence / 证据: 用户 2026-11-03 修正；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3.1、§3.4。
- Notes / 说明: 精确 sector 坐标与无 sector 统一为无地面只是 D01 的前提；还必须回答如何验证覆盖、共享边/顶点如何确定采样归属。鼠标反投影、命中面选择、遮挡与无命中兜底归 D06，不能用展开鼠标规则代替 D01 的回答。§3.1.1–3.1.5 已给出具体算法、返回语义和两图判例作为讨论方案，尚未经用户裁定，不得记为 D01 已完成或已实现。
- Source / 来源: user
- Date / 日期: 2026-11-03

### [Stage1/Boundary] 有向 linedef 可定位两侧，但线上等号归属仍须明确
- Evidence / 证据: 用户 2026-11-03 关于 linedef 方向/Front/Back 的补充；外部只读 `E:/DOOMSourceCode/linuxdoom-1.10/p_setup.c:417`、`p_maputl.c:66`、`r_main.c:801`；阶段 1 契约 §3.1.6。
- Notes / 说明: 经典 WAD 按 v1→v2 与 sidedef 引用定义两侧；逻辑 v=-wad_y 后叉积符号反转。恰在线上时叉积为 0，仍需明确取侧约定。原版 `P_PointOnLineSide` 的水平/竖直特判和一般斜线相等分支不统一取 Front，`R_PointInSubsector` 实际按 BSP 分割线遍历。用户提出顶点随机扰动/空值/之前值并询问建议，尚未裁定；契约新增固定侧、确定性默认和有条件保留合法实体状态的建议，不能记为用户已选。裸 null 不宜同时表示“真实无地面”和“顶点尚未选侧”。
- Source / 来源: user | code
- Date / 日期: 2026-11-03

### [Stage1/Doom] 原版点归属由 BSP 确定，实体支撑高度另由接触边界修正
- Evidence / 证据: 外部只读 `E:/DOOMSourceCode/linuxdoom-1.10/r_main.c:162,801`、`p_map.c:375,451`、`p_maputl.c:396`、`p_mobj.c:216`；阶段 1 契约 §3.1.7。
- Notes / 说明: `R_PointInSubsector` 对线上/顶点也按确定性的 BSP 分支选叶，不随机、不返回旧 sector，也没有无地面返回；`R_PointOnSide` 含轴向特判与符号位快速分支，不能简化成所有共线点都取 Back。移动先由目标中心 sector 初始化高度，再按包围盒接触的 linedef 修正 floor/ceiling，因此 `thing->floorz` 不一定等于中心 sector floor；旧位置保留是移动失败未提交的结果。ETNDOOM 若采用 BSP 仍需真实覆盖校验以支持无地面；上一条所涉固定 Front/顶点回退是讨论建议，不是原版行为。
- Source / 来源: code
- Date / 日期: 2026-11-03

### [Stage1/Doom] BSP、BLOCKMAP 与 REJECT 分工不同，sector 归属还影响玩法
- Evidence / 证据: 外部只读 `E:/DOOMSourceCode/linuxdoom-1.10/r_bsp.c:497,552`、`r_segs.c:398`、`p_sight.c:257,300`、`p_maputl.c:743`、`p_map.c:1191,1321`、`p_enemy.c:106,165`、`p_spec.c:1009`；阶段 1 契约 §3.1.8。
- Notes / 说明: 原版直接用 BSP 做渲染遍历、点定位与视线检查；sector 归属间接影响精灵链表/亮度、生成与传送、地面伤害/秘密区域及 AI 声音传播起点。爆炸候选经 BLOCKMAP 收集，再查 BSP 视线；射击/自动瞄准/使用线主要走 BLOCKMAP 的 `P_PathTraverse`。BLOCKMAP 的 128mu 网格只是候选索引，不量化真实地形；REJECT 另作 sector 对视线快速排除。声音唤醒沿 sector 邻接传播，不遍历 BSP；自动地图的 `ML_MAPPED` 由墙段渲染路径写入。门和升降台改变高度时不重建二维 BSP，各查询读取当前 sector 高度。这些是原版源码结论，不能视为 ETNDOOM 已选方案。
- Source / 来源: code
- Date / 日期: 2026-11-04

### [Stage1/Doom] BLOCKMAP 静态线索引与运行时实体链表须区分
- Evidence / 证据: 外部只读 `E:/DOOMSourceCode/linuxdoom-1.10/p_setup.c:469`、`p_maputl.c:347,396,472,513,743`、`p_map.c:115,252,375,695,1023,1063,1130,1206,1321`、`p_pspr.c:483,515`。
- Notes / 说明: WAD 的 `BLOCKMAP` 保存网格原点、宽高及各格的 linedef 列表索引；动态实体不保存在该 lump 内，运行时另建同尺寸 `blocklinks`，按实体中心所在单格挂链，移动时解除/重挂，`MF_NOBLOCKMAP` 实体不入链。移动实体碰撞查询扩大范围以容纳邻格实体半径；射线查询则沿经过的格收集候选，再按交点参数处理。故其消费者还包括拾取、实体弹丸撞击、拳头/电锯、传送占位/踩杀及活动地板/天花板的高度适配与挤压。索引不定义地形网格或高度规则；漏线、实体挂链错误或经典查询的边界/遍历限制可改变实际判定，不能据“只是加速结构”断言重建后玩法必然逐位相同。此处仅说明经典 DOOM，不新增 ETNDOOM 采用决策。
- Source / 来源: code
- Date / 日期: 2026-11-04

### [Stage0/BSP] 已使用 BSP 构建地面，不等于已有运行时 BSP 空间服务
- Evidence / 证据: `etndoom_mod/stage03/wad.gd:102,113,125,128,183`；`etndoom_mod/stage03/map_view.gd:26,42`；阶段 1 契约 §3.1.9。
- Notes / 说明: 现有读取器解析 seg/subsector 和 NODES 以裁出地面多边形，最终 `data` 没有保留运行时 nodes/seg/subsector 结构；表现将这些多边形构建为 Godot 网格。后续引入 BSP 查询可复用部分解析/构建经验，仍需树的持久化、查询及非矩形/无地面验证，不能认为只开放查询函数即可完成。用户询问后续视线/爆炸机制的 BSP 价值，契约已记录静态几何查询后端的建议，尚未裁定采用。
- SUPERSEDED: 2026-11-04，用户随后确认使用 WAD 预存 BSP，ETNDOOM 不引入构建器；上句“尚未裁定采用”仅为历史状态。当前代码能力边界仍成立，D01–D03 新细则仍为待裁定建议，见契约 §3.1.10、§3.2.1、§3.3.1。
- SUPERSEDED: 2026-11-04（后续确认），用户接受建议并正式决策 D01、D02、D03，上句“新细则仍待裁定”不再是当前状态。正式规则见同上章节与 `docs/ARCHITECTURE.md` 的 `ETNDOOM BSP Direction`；旧半开/固定 Front 及顶点随机/旧值回退不作为点查询规则。设计已确定，当前运行时能力仍未实现。
- Source / 来源: code | user
- Date / 日期: 2026-11-04

### [Stage1/Collision] D03 的查询与跨步决策不等于完整阻挡响应，BLOCKMAP 不替代移动求解
- Evidence / 证据: 用户 2026-11-04 补充；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3.3.1–3.3.2；`etndoom_mod/stage03/player.gd:41`、`stage03.gd:139`；外部只读 `E:/DOOMSourceCode/linuxdoom-1.10/p_map.c:636,695`。
- Notes / 说明: D03 已规定最早接触/同时约束/剩余位移检查，但接触停止位置、滑动位移与速度、角点及终止细则仍需补齐。BLOCKMAP 只能提供候选，不能自动产生响应；当前 Godot `move_and_slide()` 只响应已有物理形状。MAP02 的 32mu 台阶低地侧为双面线，能否通过随当前脚底变化，不能永久静态封墙。具体响应方案与是否采用 BLOCKMAP 仍是建议，不能记为用户已选；详见契约评估，不宣称已经实现或测得性能收益。
- Source / 来源: user | code
- Date / 日期: 2026-11-04

### [Stage1/Index] 暂不采用 BLOCKMAP，WAD 已含数据也不启用
- Evidence / 证据: 用户 2026-11-04 明确决策；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3.3.2–3.3.3。
- Notes / 说明: SUPERSEDED: 上条“是否采用 BLOCKMAP 仍是建议”已由用户裁定为暂不引入；即使输入 WAD 含该 lump 也不使用，不删除原数据。BSP 静态查询方向不变；动态实体索引后续另定。停止/滑动/角点及唯一移动求解所有权当前仅为建议，不能记为用户已选。
- Source / 来源: user
- Date / 日期: 2026-11-04

### [Stage1/Doom] 原版滑墙会改写剩余动量，玩家跨步抬升晚于 XY 检查
- Evidence / 证据: 外部只读 `E:/DOOMSourceCode/linuxdoom-1.10/p_map.c:451,695,749,756,781`、`p_mobj.c:246,415`；完整对照见 `docs/DOOM_MOVEMENT_REFERENCE.md`。
- Notes / 说明: `P_TryMove` 检查目标盒，成功更新 floorz 而不改 z；玩家通常随后在 Z 阶段抬升。同一 XY 阶段多次试走不等价于每次成功都重置脚底。`P_SlideMove` 用三角点射线/单墙近似投影，退让是路径比例 1/32，最多两轮正常滑墙后先 Y 再 X 回退；正常滑动把剩余滑移写回动量，不能概括成仅裁掉原速度的法向分量。当前推荐的完整扫掠、同时约束、独立速度处理与原版有实际差异；尚无游戏轨迹对照，不宣称等价或已验证手感。
- Source / 来源: code
- Date / 日期: 2026-11-04

### [Stage1/Collision] 接地碰撞响应正式采用完整扫掠、同时约束与独立速度处理
- Evidence / 证据: 用户 2026-11-04 明确“将推荐方案落地为决策”；阶段 1 契约 §3.3.3；`docs/ARCHITECTURE.md` 的 `ETNDOOM BSP Direction`。
- Notes / 说明: SUPERSEDED: 上述 Collision/Index 条目中“停止/滑动/角点及唯一移动求解所有权仅为建议”的历史状态由本次确认取代。正式采用最早接触停止/沿边滑动、真实同时约束、位移与速度分别裁剪、合法中间支撑更新及模组唯一提交；不采用原版三角点射线、Y/X 回退、路径比例退让或剩余滑移写回动量。纯试算与玩法副作用分离。功能尚未实现；容差/预算交阶段 4 验证，空中/竖直运动及其它关联机制仍待补齐。暂不使用 BLOCKMAP 的决策不变。
- Source / 来源: user
- Date / 日期: 2026-11-04

### [Stage1/Jump] D04 主动跳跃参考 UZDoom，经典 DOOM 与 ETN 本体须分开
- Evidence / 证据: 用户 2026-11-05 补充；阶段 1 契约 §3.6；`docs/DOOM_MOVEMENT_REFERENCE.md` §5；外部只读 `E:/DOOM/UZDoom-trunk/wadsrc/static/zscript/actors/player/player.zs:1464`。
- Notes / 说明: 经典 DOOM 没有主动跳跃，但已有竖直重力/碰撞；契约中的旧“原版闪避跳跃”指 ETN 本体。本次明确可取用 UZDoom 实现，详细源码观察上提至主题参考文档；其 tic 单位、接地状态、落地延迟和地形查询必须一起适配，默认数值不自动成为 D04 决策。
- Source / 来源: user
- Date / 日期: 2026-11-05

### [Stage1/Jump] D04 玩家能力、代码来源与阶段范围收窄
- Evidence / 证据: 用户 2026-11-05 本轮补充；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3.6、§5；`docs/DOOM_MOVEMENT_REFERENCE.md` §6。
- Notes / 说明: 玩家可跳上平台、主动跳下，不能跨越 D01 的无 Sector 区域，腾空也不豁免。跳跃沿用 UZDoom 思路，主动跳下与落地沿用经典 DOOM；第一版测试敌人不在阶段 1 范围，不列为 D04 或阶段 1 验收前置。SUPERSEDED: 先前玩家能力/跨无地面均待定及泛指可取 UZDoom 落地的描述由本轮方向收窄；参数、有限占地失去支撑与接触细则仍待裁定，不表示 D04 全部冻结或功能已实现。
- Source / 来源: user
- Date / 日期: 2026-11-05

### [Stage1/Jump] UZDoom 空中也检查 24mu 跨步，默认跳高依赖离散更新顺序
- Evidence / 证据: 外部只读 `E:/DOOM/UZDoom-trunk/src/playsim/p_map.cpp:2427,2683`、`src/playsim/p_mobj.cpp:2958,3342`；`docs/DOOM_MOVEMENT_REFERENCE.md` §7。
- Notes / 说明: 普通玩家跨步没有 onground 前提，腾空脚底距台面不超过 MaxStepHeight 仍可能通过，所以自由跳高不等于可登台高度。35Hz 的 8mu/tic 起跳、每 tic 减 1 且先位移后重力，孤立自由跳高为 36mu；换算为 280mu/s 与 1225mu/s² 后用连续公式只有 32mu。D04 前四项建议单列为待裁定，不能把源码事实或调参建议写成用户已选规则。
- Source / 来源: code
- Date / 日期: 2026-11-05

### [Stage1/Jump] 保留极弱空中推力是内容约束，真实跳高改为 60mu
- Evidence / 证据: 用户 2026-11-05 接受第 1/2/4 项、纠正第 3 项，随后明确选择“保留 UZDoom 的 1/256 极弱输入推力”；阶段 1 契约 §3.6.1；`docs/DOOM_MOVEMENT_REFERENCE.md` §8。
- Notes / 说明: SUPERSEDED: 上条“D04 前四项建议待裁定”及旧 36mu/0.5 建议由本次确认取代。极弱空中控制本身就是用户要求，不能以易操作为由提高。当前为真实跳高 60mu、g=1225mu/s²、v0≈383.405790mu/s、按住连跳/落地等待 0.2s、1/256 推力、仅接地 24mu 跨步；第 5–7 项仍待定。ETN 本体 jump 姿态/光环随动等仅要求评估，尚未决定移植，见 SYSTEMS §5.1.1。
- Source / 来源: user
- Date / 日期: 2026-11-05

### [Stage1/Presentation] 跳跃装饰不能整体复用本体状态机，光环静态合成需单独适配
- Evidence / 证据: `script/player.gd:271,287,403`；`scenes/player/momoi/momoi.tscn:103,225`；`etndoom_mod/stage03/actor_view.gd:33`；`docs/SYSTEMS.md` §5.1.1。
- Notes / 说明: 本体跳跃姿态与旧精灵 Y 位移、免伤、计时滞空、声音及全局事件同处一套流程；Momoi jump 是单帧，旋转轨道属于踢击。Stage0.3 光环静态合成、主体逐帧归一化，不能仅恢复旧回调实现动态光环或姿态变形。事实和候选上提至系统说明；本轮未移植。
- Source / 来源: code
- Date / 日期: 2026-11-05

### [Stage1/Presentation] 跳跃表现正式选定四项，其余不移植
- Evidence / 证据: 用户 2026-11-05 确认；阶段 1 契约 §3.6.2；`docs/SYSTEMS.md` §5.1.1。
- Notes / 说明: SUPERSEDED: 此前仅列候选/尚未决定的状态由本次确认取代。只移植跳跃姿态、光环滞后跟随、起跳烟尘和音效；其余不移植。以真实状态/成功起跳事件驱动，不能带回旧精灵 Y 接地、提层、免伤或计时滞空，也不扩展其它装饰。决定范围不等于功能已实现。
- Source / 来源: user
- Date / 日期: 2026-11-05

### [Stage1/Jump] D04 第 5/7 项方向与落地水平速度边界
- Evidence / 证据: 用户 2026-11-05 本轮补充；契约 §3.6.3；`docs/DOOM_MOVEMENT_REFERENCE.md` §9。
- Notes / 说明: 用户明确前四项已决策，占地完全离开高台才下坠，落地不修改水平速度且同时碰到台沿/地板/天花板正常走碰撞逻辑；第 6 项稍后讨论。SUPERSEDED: 第 5/7 不再是完全未定方向，精确相切、支撑建立与组合时序细化仍为待选建议。经典 P_ZMovement 不改水平动量，侧碰和之后的接地控制另行处理；不可把用户要求误解为落地时忽略墙碰撞，也不把经典顺序 XY/Z 当作已选的连续联合求解。
- Source / 来源: user | code
- Date / 日期: 2026-11-05

### [Stage1/Jump] D04 第 5/7 项支撑与组合接触正式决策
- Evidence / 证据: 用户 2026-11-05 明确接受第 5/7 项建议；阶段 1 契约 §3.6.3；`docs/DOOM_MOVEMENT_REFERENCE.md` §9。
- Notes / 说明: SUPERSEDED: 上一条“精确相切、支撑建立与组合时序仍待选”由本次确认取代。选定完整占地最后支撑消失才下坠、边/点按进入与离开处理、落地保持水平速度、侧碰独立裁剪、同刻接触联合约束与剩余时间继续求解；恰好 60mu 顶点接触且向台内运动的合法登台判例一并确认。第 1–5、7 项已决策，第 6 项另议，体高仍依赖 D05/D10；尚未实现或运行验收。
- Source / 来源: user
- Date / 日期: 2026-11-05

### [Stage1/Boundary] 正常单面线阻挡与缺线异常地图须分开
- Evidence / 证据: 用户 2026-11-05 关于第 6 项的补充；契约 §3.6.4；`docs/DOOM_MOVEMENT_REFERENCE.md` §10；`MAP02_NoBorder.wad` 本次哈希与字段快照见该节。
- Notes / 说明: 单面 linedef 即使不设 Impassable 也须阻挡完整玩家碰撞体积；“单向”在此指 one-sided，不指单向通行。用户说明某些缺线 WAD 可被游戏容忍但出现显示/越界异常，开放轮廓不能假定仍有严格的真实地面分界。SUPERSEDED: 第 6 项不能笼统当作普通悬崖部分悬空问题。当前 NoBorder 同时含缺口与 SEGS[24] 引用不存在的 linedef 30，不是仅缺线的干净夹具；未运行游戏。拒绝无法确定真实覆盖的异常输入为当前建议，尚未确认。
- Source / 来源: user | code
- Date / 日期: 2026-11-05

### [Stage1/Validation] 无效地图引用拒绝加载，严格 Source Port 同样报错
- Evidence / 证据: 用户 2026-11-05 决策；用户截图 `D:/Temp/codex-clipboard-f549a192-bceb-4dc2-a599-a2c1fce3cd33.png`（PrBoom-Plus-RT）；契约 §3.6.4；移动参考 §10。
- Notes / 说明: SUPERSEDED: 先前无效引用拒绝加载为建议，现已正式确认；宽容引擎可能容忍错误不能推广到严格 Source Port。截图 `P_LoadSegs: seg 24 references a non-existent linedef 30` 与 NoBorder 静态字段一致。ETNDOOM 检测到 BSP、linedef、sidedef 等无效引用时拒绝加载并报错；按格式合法的无引用哨兵（如单面线缺 back sidedef）不能误拒。用户说明此类问题通常伴随无效引用，不等于所有覆盖异常必有越界引用；其它更广兼容建议未一并获选，尚未实现。
- Source / 来源: user
- Date / 日期: 2026-11-05

### [Stage1/Validation] 引用有效但轮廓开放的罕见制图错误不作特殊处理
- SUPERSEDED: 2026-11-12，用户允许加载阶段能定位异常点的开放轮廓按一般几何错误拒绝加载，见下方 `[Stage1/D07]` 修正；旧限制不再作为拒绝检查的依据。
- Evidence / 证据: 用户 2026-11-05 关于 `MAP02_NoBorder2.wad` 的补充；契约 §3.6.4；移动参考 §11 的字段与哈希快照。
- Notes / 说明: 用户指出此类输入可被所有 DOOM 引擎默许，但十分罕见、属于制图失误，不纳入 ETNDOOM 正常考虑范围，不作特殊处理。SUPERSEDED: 此前针对引用有效但覆盖开放的专项加载拒绝/兼容/运行兜底建议不采用；不把该项继续留为待裁定。无效引用仍拒绝加载；NoBorder2 所查非哨兵引用未见越界，外轮廓仍开放，孤立 linedef 30 两侧为 65535 且不被 seg 引用，不能把无引用哨兵当作越界目标。正常查询/移动规则保持有效，不承诺范围外地图结果。
- Source / 来源: user | code
- Date / 日期: 2026-11-05

### [Stage1/Contract] D04 跳跃与悬崖整体已决策
- Evidence / 证据: 用户 2026-11-05 明确要求“更改 D04 为已决策”；阶段 1 契约 §3.6.1–3.6.4。
- Notes / 说明: SUPERSEDED: 此前 D04 部分已决策、整体未冻结及第 6 项另议等状态由本次整体确认取代。第 1–7 项和四项 ETN 跳跃表现范围均按现有契约执行；正常单面边界完整阻挡、无效引用拒绝加载、引用有效但轮廓开放不作特殊处理。体高依赖归 D05/D10，算法/容差与运行验证交阶段 4，不使 D04 重新变成待决；未实现、未运行验收，阶段 1 整体仍未冻结。
- Source / 来源: user
- Date / 日期: 2026-11-05

### [Stage1/Wall] D05 按经典线与 sector 收窄，玩家体高明确为 56mu
- Evidence / 证据: 阶段 1 契约 §3.7；`docs/DOOM_MOVEMENT_REFERENCE.md` §12；外部只读 `E:/DOOMSourceCode/linuxdoom-1.10/p_map.c:211,214,899`、`info.c:1125`。
- Notes / 说明: SUPERSEDED: 此前独立墙块/障碍、额外天花板行为及玩家体高的泛化待选范围按用户输入收窄：独立障碍归实体且不在阶段 1，天花板当前只有碰撞，玩家体高 56mu。经典线无独立高度/站立顶面，地形支撑来自 sector floor；ML_BLOCKING 也挡怪物，无 flag 仍须查开口。middle texture 不挡 hitscan/missile，但单面、sector 几何和实体仍可阻挡。D05 整体不因源码核对自动标为已决策，尚未实现。
- Source / 来源: user | code
- Date / 日期: 2026-11-05

### [Stage1/Ceiling] 经典 hitscan 不直接求交水平天花板，天空导弹特例分 XY/Z 路径
- Evidence / 证据: `docs/DOOM_MOVEMENT_REFERENCE.md` §13；外部只读 `E:/DOOMSourceCode/linuxdoom-1.10/p_map.c:1062,956`、`p_mobj.c:173,328`。
- Notes / 说明: Linux DOOM 1.10 hitscan 只遍历 linedef/实体，在穿线时按开口斜率阻挡，无 sector 内水平 ceiling 最近交点；missile 则按 z+height 与 ceilingz 撞顶。XY 失败且 ceilingline 背面为 sky 时直接删除 missile，Z 撞顶分支没有 sky 例外仍爆炸；不能写成“天空一律不爆炸”或“天花板一律按三维射线命中”。动态压碎另由 sector 变化流程处理，不是普通碰顶自带伤害。源码研究未运行复现，未自动纳入 ETNDOOM 首版。
- Source / 来源: code
- Date / 日期: 2026-11-05

### [Stage1/Sky] 天空 Ceiling 与天空 Linedef 必须分开，攻击穿透不等于终止无特效
- Evidence / 证据: 用户 2026-11-06 修正；阶段 1 契约 §3.7.1；`docs/DOOM_MOVEMENT_REFERENCE.md` §14；外部只读 `E:/DOOMSourceCode/linuxdoom-1.10/r_segs.c:530`、`r_plane.c:396`。
- Notes / 说明: SUPERSEDED: 此前笼统称“天空碰撞”的表述应按 sector Ceiling 与 linedef 天空部分区分。经典 upper texture 隐去条件是双面线前后 ceiling 均为 sky，不能推广为一侧 F_SKY1 取消所有邻边上墙。用户提出 ETNDOOM hitscan 穿过两种天空面、弹射物穿过天空线但碰天空 Ceiling 删除；穿过须继续后续查询，不等于经典终止射线无 puff。天空线仅指相关部分，不放开整条线或玩家阻挡。提案已记录，尚未实现，D05/D06 整体未冻结。
- Source / 来源: user | code
- Date / 日期: 2026-11-06

### [Stage1/Sky] 天空分类确定，攻击首次遇天空后不再碰撞
- Evidence / 证据: 用户 2026-11-06 明确决策；阶段 1 契约 §3.7.1、§3.8；`docs/DOOM_MOVEMENT_REFERENCE.md` §15。
- Notes / 说明: 双面线仅两侧 Ceiling 都为 sky 时上部高差墙面按天空处理；单侧 sky 按一般线，单面无天空部分。SUPERSEDED: 上一条“穿过后继续查询、碰天空 Ceiling 删除弹射物”的提案被新决策取代：弹射物首次遇任一天空面即进入不再碰撞的持续飞行状态，计时到期删除；hitscan 天空之后的部分不再命中地形/实体，延伸至原最大距离。分类归 D05，状态与未给定的计时器时长归 D06；尚未实现。
- Source / 来源: user
- Date / 日期: 2026-11-06

### [Stage1/Contract] D05 墙体整体已决策，D06 参数不阻塞 D05
- Evidence / 证据: 用户 2026-11-06 要求无剩余未决项时标记 D05 已决策；阶段 1 契约 §3.7–3.7.1、§3.8。
- Notes / 说明: 复核普通墙体、flags/开口、56mu 玩家体高、实体范围、天花板约束及天空分类，无剩余 D05 设计分歧。SUPERSEDED: 此前 D05 整体未决状态由本次确认取代。天空攻击特殊状态已在 D06 确认，其计时器时长及普通攻击/瞄准仍归 D06；格式、数值容差、算法与运行验收按后续分工推进，不据此把 D05 重新列为未决。尚未实现，阶段 1 整体未冻结。
- Source / 来源: user
- Date / 日期: 2026-11-06

### [Doom/Projectile] Imp 火球的破裂无范围伤害，水平弹速不等于三维总速
- Evidence / 证据: 外部只读 `E:/DOOMSourceCode/linuxdoom-1.10/info.c:233,1914`、`p_mobj.c:90,889`、`p_map.c:299,323`；完整结论见 `docs/DOOM_IMP_FIREBALL_REFERENCE.md`；阶段 1 契约 §3.10。
- Notes / 说明: 用户选定 Imp 火球作为测试弹射物，尚未实现或批准全部原版参数。经典碰撞盒为 12×12×8mu，水平弹速 10mu/tic，另算 momz，出生底面抬高 32mu；破裂状态没有 A_Explode/P_RadiusAttack，不能因动画放大附加范围伤害。穿发射者、撞其他 Imp 则破裂不伤害，不能泛化为全敌方免伤或穿过同类。移植时须裁定三维速度与瞄准/过滤，不把经典离散碰撞顺序当作连续扫掠；天空始终按 ETNDOOM 已确认 §3.8，时长仍待裁定。
- Source / 来源: code | user
- Date / 日期: 2026-11-11

### [Combat/Melee] ETN 普通近战按短窗口收集 HurtBox 后统一结算，无墙体或高度重检
- Evidence / 证据: `script/kick.gd:15,29,46,55,61`；`script/kick.tscn:7,60,72,76`；`script/player.gd:219,269`；`scenes/player/momoi/momoi.tscn:225,423`。
- Notes / 说明: 普通 Kick 用 0.2 秒冷却与 0.1 秒检测窗口；开启偏移 (16,0) 的胶囊（radius=17、height=52），由来源侧 `area_entered` 收集并按 HurtBox 去重，窗口结束关闭形状并逐个 `hit_received.emit`。HitBox 的 `monitorable=false` 防止目标侧自动再结算；mask=24576 仅检测敌方与召唤物 HurtBox。没有退出移除、结算时重叠/视线/高度重检，所以窗口内碰到后已离开的有效目标仍会被提交伤害；同实体多个 HurtBox 不在此处按实体去重。每次攻击只 roll 一次基础暴击，但各目标仍走独立承伤管线。`sprite_2d.position.y == -17` 是起手姿态门槛，不是三维高度判定；Kick 会随准星更新方向，伤害包中的击退方向则在起手固定。上述结论限普通 `script/kick.gd`，特殊角色另有实现；不能直接当作 ETNDOOM D06-08 的既定规则。本轮仅静态核对源码。
- Source / 来源: code
- Date / 日期: 2026-11-11

### [Stage1/Scope] D06 已定查询不要求阶段 1 引入实体
- SUPERSEDED: 2026-11-12，用户随后正式决定阶段 1 不使用 REJECT，D06-12 决策及验收一并移出；下文涉及“保留视线设计约束/REJECT 待裁定/D06 不改动”的表述为历史，后续敌对实体接入时重新讨论，源码事实不变。
- Evidence / 证据: 用户 2026-11-11 对 D06-01–14 逐项反馈；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3.9、§3.10、§5；2026-11-12 用户确认 08 采用 ETN 近战及 D06 整体决策。
- Notes / 说明: SUPERSEDED: 先前将 07 弹射物、09 爆炸、10 拾取、11 主动交互均列为阶段 1 必决/验收项的范围过宽；前三者属于实体，阶段 1 也未引入特殊 linedef/机关，现移出。用户确认 01–06、12–14，包括默认 2.0 秒天空计时；03/12 无敌对实体消费者时仅保留设计/接口约束，实战验证后移，不借测试发射器扩大范围。Imp 火球选型留作后续意向。SUPERSEDED: 2026-11-12，08 已由用户确认采用 ETN 短窗口范围近战及高度/遮挡、实体去重、即时命中适配；D06 整体已决策，先前仅推荐的状态取代。未采用的近战研究已按用户要求清理。
- Source / 来源: user
- Date / 日期: 2026-11-11

### [Stage1/Contract] D06 采用 ETN 近战并整体已决策
- Evidence / 证据: 用户 2026-11-12 指令；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3.9、D06-08。
- Notes / 说明: D06-08 确认 ETN 短窗口多目标范围攻击及已提适配：真实高度、地形遮挡、按攻击/实体去重、首次有效接触即时结算、窗口跟随平面方向及允许腾空发起。具体范围/时序/伤害参数与实战验证交后续；07/09/10/11 仍在阶段 1 范围外。SUPERSEDED: 此前 D06 部分确认、08 待裁定的状态取代，D06 整体已决策；未实现，不代表阶段 1 整体冻结。
- Source / 来源: user
- Date / 日期: 2026-11-12

### [Doom/MapLoading] 经典地图的预存 BSP、加载派生引用与帧内 visplane 是不同层次
- Evidence / 证据: 外部只读 `E:/DOOMSourceCode/linuxdoom-1.10/doomdata.h:140,152,161`、`p_setup.c:357,499,649`、`r_bsp.c:497`、`r_plane.c:218`、`r_main.c:801`；经典源码 checkout 为 `a77dfb96cb91780ca334d0d4cfd86957558007e0`。
- Notes / 说明: SECTORS 不含轮廓顶点；经典 SSECTORS 只存 seg 数量和起始索引，没有直接 sector 字段。加载时 P_GroupLines 从首个 seg 的 sidedef 派生 subsector→sector，并建立 sector→linedef 列表、声音原点及 blockbox；该线表按原始线顺序收集，不是有序闭环。P_LoadLineDefs 另算方向差、斜率分类、bbox 和前后 sector 引用。NODES/SEGS/SSECTORS 已在制图阶段预生成，经典加载路径不重建 BSP，也不先生成全图地面三角网格；软件渲染按 subsector 的 seg 投影边界组织 visplane。visplane 按高度、材质、亮度查找并按屏幕覆盖拆分，不是 sector 身份或持久地面多边形。R_PointInSubsector 只沿树选叶，不验证真实地面覆盖。上述分层是 D07 参考，不改变 ETNDOOM 已定查询规则；本次为静态源码核对。
- Source / 来源: code
- Date / 日期: 2026-11-12

### [UZDoom/MapLoading] 玩法 BSP 与渲染 GL nodes 可分离，不能把渲染区域当作玩法归属真源
- Evidence / 证据: 外部只读 `E:/DOOM/UZDoom-trunk/src/maploader/glnodes.cpp:134,921,1227,1286`、`maploader.cpp:3033,3105,3163,2579,2779`、`renderinfo.cpp:251,715`、`src/gamedata/r_defs.h:1678`、`src/playsim/p_maputl.cpp:1946`、`src/rendering/hwrenderer/scene/hw_flats.cpp:191`；本地 UZDoom 为无 Git 元数据的源码目录，结论限本次读取版本。
- Notes / 说明: 当原始节点不满足 GL nodes 条件时，CheckNodes 可把原树/叶保存为 gamenodes/gamesubsectors，再加载或构建渲染节点；并非所有地图必有两套不同树。GL miniseg 没有真实 linedef，是补足子区域边界的划分边，不是新增墙。subsector 同时有 sector 与 render_sector，PrepareSectorData 按后者建立渲染分组。源码明确以兼容重叠 sector 制图技巧为保留原始玩法树的原因，不能据此推导任意重叠输入都合法或采用最高地面。玩法 PointInSubsector 仍走单一路径，并把 double 坐标转成 fixed 后判侧，没有 ETNDOOM 的真实覆盖/完整边界接触返回。UZDoom 还可重建缺失或不合要求的节点、按条件重建 BLOCKMAP、忽略过短 REJECT；这些兼容与修复能力不属于 ETNDOOM 已批准范围。D07/D08 仍未裁定，本次仅静态源码核对。
- Source / 来源: code
- Date / 日期: 2026-11-12

### [Stage1/D07] 特殊节点须告警，可定位的开放轮廓按一般几何错误拒绝
- SUPERSEDED: 2026-11-12，用户随后正式决定阶段 1 不使用 REJECT，D06-12 决策及验收一并移出；下文涉及“保留视线设计约束/REJECT 待裁定/D06 不改动”的表述为历史，后续敌对实体接入时重新讨论，源码事实不变。
- Evidence / 证据: 用户 2026-11-12 对 D07 推荐的第 1、2 项反馈；契约 §3.11、§3.6.4；`docs/DOOM_MOVEMENT_REFERENCE.md` §11。
- Notes / 说明: 检测到扩展、压缩或 GL 节点须报告格式及实际处理，不能静默忽略；有经典节点可用也须告警，只有不支持节点可用时仍应报错拒绝。引用有效但轮廓开放，若加载时能找到明确异常点，则归入一般几何错误拒绝；SUPERSEDED: 2026-11-05 的“不增加闭合性检测/拒绝”限制取代。异常检测须依据真实边界，不能将经典 subsector 的不完整 seg 环误当制图错误。D07 整体、REJECT 使用仍未确认；用户询问影响不等于改动 D06 决策。
- Source / 来源: user
- Date / 日期: 2026-11-12

### [Doom/REJECT] 拒绝位能直接屏蔽几何通视，零位只放行后续检查
- SUPERSEDED: 2026-11-12，用户随后正式决定阶段 1 不使用 REJECT，D06-12 决策及验收一并移出；下文涉及“保留视线设计约束/REJECT 待裁定/D06 不改动”的表述为历史，后续敌对实体接入时重新讨论，源码事实不变。
- Evidence / 证据: `E:/DOOMSourceCode/linuxdoom-1.10/p_sight.c:313`、`:320`、`:346`；`p_enemy.c:188,201,532`；`p_map.c:1191`；`E:/DOOM/UZDoom-trunk/src/g_levellocals.h:436`、`src/playsim/p_sight.cpp:861`、`src/maploader/maploader.cpp:2779`；本次只读解析 `etndoom_mod/wad/MAP02_NoBorder2.wad`。
- Notes / 说明: REJECT 以 sector 对存位，大小为 ceil(N*N/8) 字节；位 1 直接不可见，位 0 才进入后续几何检查。合法且保守的预计算表用于优化；任意错误/人为置位会改变可见结果，影响调用视线函数的 AI/攻击条件及经典爆炸，并非所有 hitscan 都读取它。UZDoom 对缺失、过短及全零表禁用预筛选；不能把空 lump 当作经典引擎安全可读的完整全零表。ETNDOOM 是否消费仍待用户裁定，三点视线不自动改动。另核对 NoBorder2：sector 0 排除同 sector 内部线后的真实边界在 vertex 4 (-640,-64)/linedef 2、vertex 27 (-640,64)/linedef 29 各只有一条关联边，可定位开放端点；非游戏验证。
- Source / 来源: code
- Date / 日期: 2026-11-12

### [Stage1/Scope] 阶段 1 不使用 REJECT，D06-12 决策与验收一并排除
- Evidence / 证据: 用户 2026-11-12 明确决策；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3.9/D06-12、§3.11、§5。
- Notes / 说明: 阶段 1 无敌对实体，用户认为 REJECT 和 D06-12 均无法在本阶段测试中体现，故阶段 1 不使用 REJECT，D06-12 原已确认的视线算法、参数、接口要求与验收一并移出。SUPERSEDED: 先前“保留三点视线契约，仅实战验收后移”及“REJECT 使用仍待裁定”状态取代；历史规则保留但不作为当前约束，后续敌对实体阶段重新讨论，不自动采用。D06 其余条目维持，D07 整体未确认；不代表永久禁用 REJECT。仅修改文档，没有删除或回退功能代码。
- Source / 来源: user
- Date / 日期: 2026-11-12

### [Stage1/Contract] D07 采用修正后的推荐并整体已决策
- Evidence / 证据: 用户 2026-11-12 指令“剩余D07决策项使用你推荐的内容”；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3.12；`docs/ARCHITECTURE.md` 的 ETNDOOM BSP Direction。
- Notes / 说明: D07-01–09 采用三层数据、subsector 关联有效地面片、真实线来源保留、sector 统一高度、经典地图/节点首版范围、重叠冲突拒绝、分层校验和原始索引诊断、辅助 lump 范围及加载时派生无持久缓存。合并已确认特殊节点警告、可定位开放轮廓一般错误拒绝及阶段 1 不使用 REJECT/D06-12 移出。SUPERSEDED: 上方历史记录中 D07 整体待确认、节点清单仅推荐的状态已取代，正式条目以契约 §3.12 为准。D08 包/资源/版本、D09 出生与示例、D10 查询接口仍待裁定；仅文档落地，不表示后续加载或运动功能已实现。
- Source / 来源: user
- Date / 日期: 2026-11-12

### [Stage1/WAD] 完整 IWAD 可独立提供内容，双文件是原型限制
- Evidence / 证据: 用户 2026-11-12 对 D08 的补充；`etndoom_mod/stage03/wad.gd:4,44`；阶段 1 契约 §3.13；本轮本地 `etndoom_mod/wad/DOOM2.WAD` 目录只读检查。
- Notes / 说明: `DOOM2.WAD` 本身包含地图、纹理、精灵及声音等基础内容；相对于模式包的外部依赖不表示 IWAD 自身还缺一套素材。常见第三方地图加载 IWAD 后叠加 PWAD，PWAD 也可带自己的资源或另有依赖。当前原型固定 IWAD + PWAD 并从第二包读 MAP01，不能据此规定完整 IWAD 必须搭配 PWAD 才能选图。静态检查确认 2,919 个 lump、MAP01–MAP32 及资源目录，未验证全图运行。D08 推荐与用户已确认的来源事实分开，推荐尚待裁定；资源完备不等于 ETNDOOM 已支持全部玩法。
- Source / 来源: user | code | test
- Date / 日期: 2026-11-12

### [Stage1/Contract] D08 包与资源采用推荐并整体已决策
- Evidence / 证据: 用户 2026-11-12 指令“使用你推荐的内容，完成后标记D08为已决策”；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3.13。
- Notes / 说明: D08-01–08 全部确认：WAD 原生容器、一个 IWAD + 零到多个有序 PWAD、按命名空间覆盖资源及整组选择地图、经典资源解析、可选 ETNINFO、作者稳定身份与裸 WAD 快照身份、显式依赖、schema=1、版本分层及来源链错误诊断。SUPERSEDED: 上方历史记录中的 D08 推荐尚待裁定、包/资源/版本未决状态由本次确认取代。D07 输入范围及阶段 1 边界保持；D09/D10、完整字段示例及整体契约仍待收束，加载功能尚未实现。
- Source / 来源: user
- Date / 日期: 2026-11-12

### [Stage1/Spawn] 最小地图仅要求玩家出生点，其它出生配置非必需
- Evidence / 证据: 用户 2026-11-12 明确说明；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3.14/D09-01；`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md` §2–3。
- Notes / 说明: SUPERSEDED: 原最小图出生标签全部待定、总规划要求刷怪区域的描述由 D09-01 取代。最小地图必须有玩家出生点，enemy_spawn、raid_entry 等其它出生配置均非必需；几何/资源/格式合法性要求仍按已有契约。SUPERSEDED: 2026-11-12，后续用户决定不检测出生合法性并接受其余推荐，D09-01–06 整体已决策，取代本条此前“其余仅列建议、整体未决”的状态；详见下条。
- Source / 来源: user
- Date / 日期: 2026-11-12

### [Stage1/Spawn] 不检测玩家出生合法性，D09 整体已决策
- Evidence / 证据: 用户 2026-11-12 决策“不检测出生合法化”，其余采用推荐并要求标记 D09 已决策；阶段 1 契约 §3.14。
- Notes / 说明: 为兼容特殊 WAD，不检测玩家起点的占地、地面覆盖、墙体重叠、支撑、净空或可达性，不因这些条件拒绝出生或自动挪位。缺少 type 1 仍拒绝，结构/格式/资源/几何引用校验仍有效。其余采用 type 1 位置/朝向与 flags 规则、多个告警取最后一个、其它 THINGS 保留不生成、无需全图可达及最小图/验收示例区分。SUPERSEDED: 原完整体型校验、非法出生拒绝、局部合法性必检及 D09 部分未决状态均由本次决策取代。SUPERSEDED: 2026-11-12，用户随后按契约 §3.15 确认 UZDoom 占地抬高/撞顶下压、接受卡住与无地面告警后玩家高度 0mu；原初始化待决及禁止抬升不再有效。不检测出生合法性仍保持；未实现或验证特殊 WAD 运行。
- Source / 来源: user
- Date / 日期: 2026-11-12

### [Stage1/Spawn] 经典与 UZDoom 出生高度不同，均无真实覆盖的无地面返回
- Evidence / 证据: `docs/DOOM_MOVEMENT_REFERENCE.md` §16；`E:/DOOMSourceCode/linuxdoom-1.10/p_mobj.c:519,664`；`E:/DOOM/UZDoom-trunk/src/playsim/p_mobj.cpp:5519,6344,6494`。
- Notes / 说明: 经典首次出生直接取中心 BSP sector 地板；UZDoom 默认 PlayerPawn 会查询占地涉及的双面开口高度，并在出生撞顶时下压到 ceiling-height，即使陷入地板。高度查询不等于出生合法性检查；重生候选点检查是另一条路径。两者 BSP 查询均不表达本项目的真实覆盖无地面，不能把该情况自动解释为高度 0 或原版悬空状态。UZDoom 玩家 Spawn 的 SpawningMapThing 默认为 false，不要误套普通地图物件分支。仅源码核对，异常夹具未运行；SUPERSEDED: 2026-11-12，研究当时未决，用户随后按契约 §3.15 确认出生初始化方案，0mu 回退为本项目规则，原版源码事实不变。
- Source / 来源: code
- Date / 日期: 2026-11-12

### [Stage1/Spawn] 出生允许 UZDoom 高度调整，真实无地面仅回退玩家高度
- Evidence / 证据: 用户 2026-11-12 本轮决策；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3.15；`docs/DOOM_MOVEMENT_REFERENCE.md` §16.4。
- Notes / 说明: 有地面时按占地双面开口收紧 F/C，先脚底=F，撞顶再脚底=C−56mu，允许陷入地板及卡住，不以 24mu 跨步或净空合法性拒绝出生。中心无真实覆盖则告警后仅玩家 foot_h=0mu；不伪造 sample_floor_h/support_h 或接地，不取任意 BSP 叶子的高度冒充真实地面。SUPERSEDED: D09 原不自动抬升限制及 D10 出生相关待决状态取代；不横向挪位、不替换起点、不保证脱困，结构校验仍有效。查询统一表达与完整示例另行整理，未实现。
- Source / 来源: user
- Date / 日期: 2026-11-12

### [Stage1/Hitscan] 经典水平射程与实体对角线截距不等于完整三维最近命中
- Evidence / 证据: 外部只读 `E:/DOOMSourceCode/linuxdoom-1.10/p_map.c:899,1063`、`p_maputl.c:616,683`、`p_pspr.c:601,626`；阶段 1 契约 D06-03–06、D06-14。
- Notes / 说明: 经典 P_LineAttack 的 distance 用来构造 XY 终点，命中高度按 shootz+slope×水平距离求得；不直接求交水平 floor/ceiling。实体先以 radius 方框中按射线方向选取的一条对角线取得平面截距，再在该距离检查 z..z+height，不是精确三维盒体入点。同距交点按收集顺序处理，没有 D06-14 的显式类别/稳定 ID 排序。P_BulletSlope 正前方无目标时会试左右各约 5.625°，但 P_GunShot 仍使用原朝向加武器散布；侧向探测只提供坡度，不等于子弹水平转向目标。D06-06 已选真实三维总射程及地形/受击体最早求交，不能仅替换距离单位就宣称等价移植。以上仅源码核对，未运行游戏复现，不改变已定契约。
- Source / 来源: code
- Date / 日期: 2026-11-12

### [Stage1/Contract] 决策完成与示例交付、运行验收分别跟踪
- Evidence / 证据: 用户 2026-11-12 明确“待确认决策已经决策完毕”；`ETNDOOM/ModdingDocs/Stage1/STAGE_1_MAP_CONTRACT.md` §3、§4.2、§5.1。
- Notes / 说明: SUPERSEDED: 此前 D10 部分已决策/仍待裁定的状态已取代，D01–D10 在阶段 1 范围内均已决策。统一查询输入输出从既定规则汇总，不重新开启选型；完整字段实例、示例数据和交付审查仍单列跟踪，运行功能尚未实现。旧候选、源码研究和历次修正完整保存在 `STAGE_1_DECISION_HISTORY.md`，其中状态仅为历史；主契约保留主要编号，旧 §3.1.1–3.1.9 在历史文件中查阅。不要把出生高度回退解释为地面存在，也不要用旧开放轮廓豁免或已移出的 D06-12 规则覆盖现行契约。
- Source / 来源: user
- Date / 日期: 2026-11-12

### [Docs/Storage] ETNDOOM 新增文档与知识增量统一保存到 ETNDOOM
- Evidence / 证据: 用户 2026-11-13 明确要求迁出 `docs/` 的新增文档和已有文档改动部分；`AGENTS.md`「知识库维护」。
- Notes / 说明: SUPERSEDED: 此前将阶段 1 研究与知识增量写入 `docs/` 的维护方式再次纠正。`docs/` 仅保留本体上游参考；新文档直接置于 `ETNDOOM/`，已有文档的补充/修正保存到该目录同名文件，不存在则创建。开工读取两处对应资料，更新只写本项目补充。迁移不得复制整份本体历史代替增量，也不能删除尚未在目标验证完整的内容。
- Source / 来源: user
- Date / 日期: 2026-11-13

### [Goal/Migration] 从旧方案阶段 1 准备转向移植 DOOM，方向确认与实施完成分开
- Evidence / 证据: 用户 2026-11-14 明确项目目标、兼容顺序，并要求以“准备从旧方案阶段1开始迁移主要实现方案为移植DOOM”更新文档和提交；`ETNDOOM/ModdingDocs/DOOM_CORE_ROUTE_EVALUATION.md` §1–2。
- Notes / 说明: 先兼容原版 Doom/Doom II 与 limit-removing，再考虑 Boom/MBF21。SUPERSEDED: 原“准备继续实现旧方案阶段 1”及上一轮“是否转向移植尚未决定”的状态已取代；内核、桥接方式和旧规则差异仍待裁定。当前 `57f4cdf` 基线与干净工作区不包含上一轮临时阶段 1 运行时模块，不能把那次实现/回归描述记为当前能力；现有运行功能仍为阶段 0，旧契约保留作迁移对照。
- Source / 来源: user
- Date / 日期: 2026-11-14

### [Doom/Core] 移植时需保留玩法与查询、素材元数据的耦合
- Evidence / 证据: `E:/DOOMSourceCode/linuxdoom-1.10/p_map.c:399,451,511`、`p_setup.c:249,456`、`p_floor.c:386`；`ETNDOOM/ModdingDocs/DOOM_CORE_ROUTE_EVALUATION.md` §5。
- Notes / 说明: 移动提交与特殊线触发耦合，玩法依赖部分 R_* 查询与素材查找，某类升地板使用下墙贴图高度。不可按渲染文件前缀删除全部依赖，也不能让 ETN 与内核各自裁决同一实体位置。显示换皮须区分逻辑尺寸；以上为源码核对，不代表已完成移植验证。
- Source / 来源: code
- Date / 日期: 2026-11-14
