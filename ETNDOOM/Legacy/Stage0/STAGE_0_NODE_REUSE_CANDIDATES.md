# Stage 0 Node Reuse Decisions / 阶段 0 节点复用确认清单

> Status / 状态：D05、D07 已实现；按确认清单重建独立场景并持有测试相机，glow 与场外滚动背景启用。0.1/0.2 自动、像素和人工验收均已通过（用户于 2026-10-26 确认）；阶段 0.3 已于 2026-10-30 完成实现、回归、人工验收与交接，Gate D 已关闭。证据见[实施记录](STAGE_0_IMPLEMENTATION.md)。
> Scope / 范围：`main.tscn` 的场景结构与表现节点，以及已有全局节点的影响。用户已明确 Momoi 有关节点不在阶段 0 节点复用讨论范围；旧角色盘点仅保留在历史附录。
> Source / 来源：用户对场景需大幅重做的补充、2026-10-23 的七项反馈及后续整体确认、2026-10-24 对 D06 与 D07 的单独确认；本地场景、资源与 shader 核对。
> Date / 日期：2026-10-24

## 1. Decision Boundary / 决策边界

- D04 已确认使用独立测试 Mod entry；D05 已确认为重建独立测试场景，按本文清单复用部分节点与资源。Momoi 的裁剪方式按 D06 执行；D07 已确认由测试场景独立持有相机，均不由本次场景节点确认代替。
- 用户 2026-10-23 明确：Momoi 有关节点不纳入本文的阶段 0 节点复用讨论。既有 C02 角色资源约束和当时 D06、D07 尚未确认的状态不在该次反馈中另行改写；两项随后分别由 2026-10-24 的用户决策覆盖。附录 A 的旧盘点不作为当前候选清单。
- 用户于 2026-10-24 另行确认 D06：实例化原 Momoi 场景，入树前隔离旧玩法，由模组自有最小根逻辑接管物理体；当前角色处理以 [Momoi 分析 §8.3](STAGE_0_MOMOI_ANALYSIS.md#83-momoi-adaptation--沿用原场景的接管方案) 为准。D07 同日确认测试场景自有 `Camera2D`，不复用 Momoi 子树中的原版相机；其契约见开发细化文档 §3.3.2。
- D01、D02 已确定地图来自 WAD、素材来自 IWAD、使用正交俯视坐标；D03 已确定由地图数据生成四边静态碰撞。原版地图图片、等距 TileMap 布局和墙体几何没有直接沿用价值。
- “复用空容器”主要是沿用节点职责和分层约定，新建同类节点通常同样简单；“复用子场景/资源”才可能省下实际资产、动画或配置工作。
- 复用一个节点不等于保留它的全部子节点、组、脚本与信号。原版回合回调或全局组成员资格不能顺带视为已批准。
- 用户已确认全局泛光与场外滚动背景都复用，接受其余带入/不带入建议；只有明确需要用户裁决的节点才保留待确认。当前清单没有此类遗留节点，原有尺寸适配、绘制层级、容器挂载和组名隔离属于后续实现工作。
- 本文的“不带入”是阶段 0 场景的已确认设计；本次只更新文档，没有删除、禁用或改动原版场景和功能。

## 2. Included Nodes / 确认带入节点

下表共 10 个节点，均已确认带入。路径相对于原版 `main.tscn` 根节点；容器只复用类型、命名和职责，不实例化完整原版主场景。

| 节点 | 已确认带入内容 | 实现约束 |
|---|---|---|
| 根 `Node2D` | 独立测试场景的 2D 根容器 | 不带入 `main.gd` 及其 BGM 导出配置。 |
| `YSort` | 启用 Y 排序的容器 | 只带入空容器，不带入原版整棵子树。 |
| `YSort/PlayerRoot` | 测试角色挂载容器 | D04 不走原版生成链；组名只按实际消费者需要保留，不主动恢复原版玩法查找链。 |
| `BackLayer` | 地图表现后方的容器 | 不带入其原有静态渐变和 `MapTest2`；地图表现按 D02 重建。 |
| `FloorLayer` | 地面表现容器 | 与 `BackLayer` 分层组织地面表现，不重复生成同一份 WAD 地面；具体绘制挂载属于实现细节。 |
| `BattleRoom` | `Marker2D` 地图定位锚点 | 不沿用原坐标 `(704, 448)`；定位按 WAD 数据设置，地图中心与出生点分别表达，不默认保留 `"CenterPosition"` 组。 |
| `Control`、`Control/ColorRect` | 滚动背景父节点与最底层纯色铺底 | 与 `Control/TextureRect` 共 3 个节点；尺寸按测试视野适配，不负责场内 WAD 纹理。 |
| `Control/TextureRect` | 场外滚动背景及配套材质、shader、贴图 | 确认复用；调整覆盖范围并由场内地面遮盖，见 §3.2。 |
| `WorldEnvironment` | `Environment` 的全局 glow 配置 | 确认复用并启用；不因此引入灯光节点，也不代替实体描边材质，见 §3.1。 |

证据：`scenes/main/main.tscn:37-66,171-245,295-340`；`scenes/main/main.gd:26-94`。`main.tscn` 没有直接声明 `Camera2D`。

## 3. Rendering Reuse Cost / 表现节点复用成本

### 3.1 Glow / 全局泛光

原版 `WorldEnvironment` 只引用 1 份内嵌 `Environment`，其中仅显式设置：

```ini
background_mode = 3
glow_enabled = true
glow_strength = 0.3
```

按用户提出的节点数量与节点规模标准，复用成本低：**1 个节点 + 1 份小资源，0 个脚本、0 个子节点、0 条信号连接**。项目已有 `viewport/hdr_2d=true`，不需要为这份配置新增灯光节点。

需要纠正旧说明：glow 是按画面亮度产生泛光的后处理，不能据此认为它会给所有实体统一生成描边。实体边缘轮廓由各自的描边 shader/material 生成；例如 `sprite_outline.gdshader` 明确采样四邻域并合成边缘。高亮描边可再受到 glow 影响，例如敌人受击时会将 `outline_color` 写为 `Color(2,2,2)`。复制 `WorldEnvironment` 不等于复制了全部实体的描边材质。

证据：`scenes/main/main.tscn:37-40,176-177`；`project.godot:247-252`；`shaders/sprite_outline.gdshader:12-31`；`script/entity_ENEMY.gd:525-528`。glow 的引擎行为另核对 Godot 官方《Environment and post-processing》的 Glow / Using glow in 2D 章节。

已确认：阶段 0 复用并启用上述 glow 配置。按已确认的 D09，自动回归须保存完整视口截图并执行像素级机器校验；截图需记录含 glow 的观察条件，为自动校验固定采样时机或明确容差/掩码。为检查原始资源而采用的隔离采样不改变正常人工运行启用 glow 的决策。阶段 0 仍不引入光照系统。

### 3.2 Background / 场外滚动背景

用户确认原版会在场地以外渲染滚动背景。代码将各层分得很清楚：

| 节点 | 实际作用 | 是否属于滚动核心 |
|---|---|---|
| `Control` | 普通 `Control` 父节点，组织两个背景子节点；不是专门的自动布局 `Container` | 确认带入父节点，无脚本 |
| `Control/ColorRect` | `z_index=-10` 的深色纯色铺底，范围大于原场地 | 确认配套带入，本身不滚动、不铺纹理 |
| `Control/TextureRect` | `z_index=-9`，使用 `test_BG.png` 与 `scrolling_bkgd.gdshader`，通过 `TIME` 改变 UV，再重复采样贴图 | **是，滚动核心** |
| `BackLayer/TextureRect` | `z_index=-2`，一份静态 `GradientTexture2D` | 否，原场地的渐变衬底 |
| `BackLayer/ColorRect` | 名字叫 `ColorRect`，实际类型是 `TextureRect`；使用另一份静态渐变 | 否，不能按名字误判类型 |
| `BackLayer/MapTest2` | `z_index=-2` 的静态场地图像，引用 `map_test_2.png`，带原版旋转、缩放和倾斜 | 否，不符合 D02 的正交地图表现 |

`Control/TextureRect` 的最小复用规模为 **1 个节点 + 1 份 `ShaderMaterial` + 1 个 24 行 shader（748 字节）+ 1 张贴图（`test_BG.png`，591 字节）**；本次确认连 `Control` 与纯色铺底一起沿用，合计 **3 个节点**。以上是源码/源文件规模，不包含 Godot 导入产物，也不是运行时性能测量。没有 GDScript、回合信号或管理器依赖；材质中的速度、方向、重复次数与染色沿用原配置，覆盖尺寸按测试视野适配。

原版使用低层背景加上上层静态场地图像形成场内外区分；滚动 shader 本身不接收 WAD 边界，也没有“只在矩形外绘制”的裁剪逻辑。阶段 0 沿用低层背景，由上层不透明 WAD 地面覆盖场内，不额外引入裁剪节点；这张背景贴图不作为 D02 的场内素材。还需按地图范围和相机可达视野调整背景覆盖尺寸，尤其不能直接沿用原版有限矩形而假设 0.1 越界后背景始终铺满屏幕。这些适配属于实现工作，不再作为节点取舍待确认项。

证据：`scenes/main/main.tscn:3-4,42-66,181-239`；`shaders/scrolling_bkgd.gdshader:1-24`；源文件字节数为 2026-10-23 本地静态核对。

已确认：复用 `Control`、`Control/ColorRect`、`Control/TextureRect` 及滚动所需资源；两个原版静态渐变与 `MapTest2` 不带入。

## 4. Excluded Nodes / 确认不带入节点

以下节点均已确认不带入阶段 0。这里只确定测试场景的组成，不删除原版资源或功能；后续重新引入的安排按表中说明执行。

| 原节点                                                                                                                                                                                                   | 确认不带入的原因与后续安排                                                                           |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `YSort/Wall`、`YSort/FloorWall`                                                                                                                                                                        | 原版等距 TileSet 与手填墙体几何不适用；D03 要求从 WAD 范围生成矩形四边碰撞。可沿用 `wall` 层语义，不能照搬几何。              |
| `YSort/SpawnMap`、`YSort/SpawnNorth`、`YSort/SpawnEast`、`YSort/SpawnSouth`、`YSort/SpawnWest`                                                                                                            | 原版出生区域与等距地图布局；阶段 0 不刷怪，也不使用它们反推地图范围。                                               |
| `BackLayer/TextureRect`、`BackLayer/ColorRect`、`BackLayer/MapTest2` | 两份原场地静态渐变与场地图像，不是滚动背景核心。其原版场地外观和几何不适用；`Control/TextureRect` 已确认为带入。 |
| `SELayer`、`ForegroundLayer`、`Light` | 用户明确阶段 0 不需要特效、伤害跳字和光照，暂不引入；后续需求另议。 |
| `CanvasLayer`、`CanvasLayer2` | 阶段 0 无 HUD 需求，不带入空容器，也不为状态显示新增调试 HUD；已有全局叠层按 §5 处理。 |
| `CanvasLayer/ColorRect`                                                                                                                                                                               | 屏幕暗角渐变，不是必要地图表现；会改变画面观察条件。                                                         |
| `BuffBox`、`YSort/EnemiesRoot`、`YSort/CoinRoot`、`YSort/PropRoot`、`YSort/BulletRoot`、`YSort/FieldModRoot`、`EquipLayer`                                                                                  | 均为原版内容容器；阶段 0 无对应实体。空容器本身不会生成实体，但没有必要为这些未使用系统先补齐整套容器/组。                            |
| `RoundTimer`（含 `GlobalTimer`）、`RoundManager`、`EnemyManager`、`UpgradeManager`、`PickItemManager`、`SummonedManager`、`InteractionManager`、`game_mode_manager`、`ChipManager`、`FieldModManager`             | 原版回合、刷怪、升级、拾取、支援/召唤、交互与词条系统；不符合 C03 和阶段范围。若测试需要计时，使用测试自身计时，不复用会广播原版全局 tick 的时钟。    |
| `ChipHud` | 用户所称 `ChipH` 对应原节点 `ChipHud`；阶段 0 不引入，后续会加入并修改。修改内容留待后续阶段，不再并列保留“弃用”方向。 |
| `PlayerUpScreenDate`、`GameOverPage`、`cheat_menu` | 都是玩法 HUD/菜单；隐藏不等于不连接信号。作弊菜单还能改状态或生成实体，不作为阶段 0 调试入口。 |
| `CanvasLayer2/ArrowN`、`CanvasLayer2/ArrowE`、`CanvasLayer2/ArrowS`、`CanvasLayer2/ArrowW`、`WarringAnim`、`WarringAnim/RaidWarringAnimNorth`、`WarringAnim/RaidWarringAnimEast`、`WarringAnim/RaidWarringAnimSouth`、`WarringAnim/RaidWarringAnimWest` | 突袭预警/方向提示，依赖原版目标和玩法信号；阶段 0 无突袭。 |
| `CanvasLayer2/Crosshair`                                                                                                                                                                              | 阶段 0 无瞄准/攻击；原脚本还控制鼠标模式、监听回合并逐帧发准星位置信号，不能仅为显示指针整套沿用。                                |
| `BGMTimer`                                                                                                                                                                                            | 回调接入 `main.gd` 的 BGM 轮换；只复用 Timer 类型没有实际节省，阶段 0 也不需要原版音乐流程。                        |

证据：`scenes/main/main.tscn:36-170,216-239,247-293,315-338,336-422`；`scenes/crosshair/crosshair.gd:14-30,78-87`；`ui/arrow.gd:12-27`；`ui/round_timer.gd:75-86,508-509`。

## 5. Global Nodes / 已存在的全局节点

`ModManager`、`GameEvents`、`Game`、`PlayerData`、`SoundManager`、`MapBounds`、`PoolManager`、`Transition`、`DebugPerformanceMonitor`、`CRTOverlay` 等是本体 autoload，不是 `main.tscn` 的子节点（`project.godot:25-42`）。

- D04 的测试 Mod 直接切换当前场景后，它们仍然存在；无需为了复用而在测试场景里再实例化一份。
- `MapBounds` 必须按开发细化文档 §3.2 隔离，不能借它实现边界阻挡。
- `GameEvents` 的存在不要求测试主动广播原版首回合、属性刷新或全局 tick。
- F3 性能叠层可作为已有观察工具；CRT 与 glow 会影响人工看到的最终画面，渲染验收要说明观察条件。

## 6. Decision Closure / 决策收束

用户 2026-10-23 已确认：**全局泛光与场外滚动背景都复用**；`ChipHud` **阶段 0 不引入，后续会加入并修改**。其余带入/不带入建议接受为确认项，不再笼统标为候选。

D05 据此收束为：重建独立测试场景，按 §2 的 10 个节点及其必要资源复用；不继承整张 `main.tscn`，不带入 `main.gd` 或 §4 的原版子树/玩法系统。容器可新建同类型节点来承接既有职责，不能把“确认带入”理解为保留其原有全部配置、全局组或后代。

当前场景清单没有需要用户额外裁决的节点。D01–D10 均已决策，Gate A–C 均已完成：0.1/0.2 自动与像素回归通过，人工验收由用户于 2026-10-26 确认符合预期。阶段 0.3 已完成，Gate D 已关闭；具体视角/投影规则与证据见[开发细化文档](STAGE_0_DEVELOPMENT_DETAIL.md)和[0.3 契约](STAGE_0_3_VIEW_CONTRACT.md)。角色接管、相机归属、越界判定及开发源目录分别按 §3.3.1、§3.3.2、§3.3.3、§6.2 执行。（来源：user、test）

SUPERSEDED: 2026-10-23 本文前一版的“glow 与滚动背景仅保留候选”“D05 整体场景方案仍待确认”“HUD 后续可复用也可弃用重做”均被本次用户决策替代。当前带入/不带入清单以 §2、§4 为准，`ChipHud` 后续明确会加入并修改。（来源：user）

SUPERSEDED: 2026-10-23 旧版将 Momoi 子树列为优先讨论对象，并把 `Control/TextureRect` 与原场地渐变/图像一起排除。按用户反馈，Momoi 退出本文当前讨论；滚动背景须与原场地图像分开判断，glow 与滚动背景恢复为低成本候选，特效/跳字/光照/HUD 明确阶段 0 不引入。原角色盘点保留在附录 A，不作为当前候选。（来源：user、code）

## Appendix A. Historical Momoi Inventory / 历史角色盘点

<details>
<summary>2026-10-23 旧盘点，仅保留历史，不属于当前阶段 0 节点复用讨论</summary>

SUPERSEDED: 2026-10-23 用户明确 Momoi 有关节点不在阶段 0 节点复用讨论范围。以下保留旧盘点原有事实与建议，不作为当前推荐，也不表示 D06、D07 已裁决。

SUPERSEDED: 2026-10-24 用户随后分别确认 D06 与 D07；本附录相机行仅保留原候选分析，不代表当前方案。D07 现确认为测试场景独立持有相机；Momoi 整体实例化带出的原版相机在入树前移除，详见开发细化文档 §3.3.2。（来源：user）

### A.1 Original Candidates / 原候选

本节原为 D06、D07 的补充输入，不替代它们的技术方案决策。C02 的固定加载 Momoi 场景约束不由本次讨论改写。

| 节点 / 子树 | 可复用内容 / 价值 | 原阶段 0 建议与条件（已退出当前讨论） |
|---|---|---|
| 根 `momoi`（`CharacterBody2D`） | 角色物理体及 `collision_mask=256`、浮动移动模式配置 | 高价值候选，但不直接运行完整 `script/player.gd`。移动只保留平面输入、速度与 `move_and_slide()`；`"Player"` 组必须按隔离方案另行处理。 |
| 根下 `CollisionShape2D` | 半径为 `7.0` 的圆形本体碰撞，局部位置 `(0, -6)` | 高价值候选。0.1 不参与碰撞查询，0.2 配合墙层启用；停止位置要包含形状偏移，不能把根位置、形状中心和脚底当成同一点。 |
| `Graphics` | 角色外观的变换容器 | 可沿用；不整体激活其下的 `Gun`。用其翻转/位置组织外观，不保留跳跃或踢击引起的偏移。 |
| `Graphics/AnimatedSprite2D` | Momoi 贴图、`SpriteFrames`、`idle`/`run` 动画和精灵偏移 | 最高价值候选。局部位置为 `(0, -17)`；阶段 0 自行驱动待机/移动切换，不播放 `jump`，不依赖完整原版状态逻辑。 |
| `Graphics/Halo` | 光环贴图、缩放、描边材质 | 外观候选；原版跟随更新在 `player.gd` 中，保留节点后要明确采用固定位置还是保留简化跟随。不能假设它独立具有跟随逻辑。 |
| `Graphics/AnimatedSprite2D/HaloRoot` | 光环定位锚点 | 与 `Halo` 配套候选；其本身是普通 `Node2D`，只提供定位，不负责驱动光环。 |
| `Shadow` | 无脚本的阴影 Sprite2D 子场景与角色缩放 | 可直接复用外观，依赖少，有助于观察脚底位置。阴影图案本身不是碰撞判定点。 |
| `Camera2D` | `gamecamera.tscn` 中的平滑配置、角色内相对位置 | 条件候选，归 D07。Momoi 配置 `offset=(0,-15)`；初始视图按 D02 需以 WAD 出生点为中心，不能未经核对照搬偏移。原脚本还连接震屏、准星和运镜信号。 |
| `RunSounds`、`RunSoundsTimer` | 脚步音资源与 0.2 秒间隔配置 | 可选的移动反馈。需由测试移动逻辑控制，不能为了脚步声保留完整 `player.gd`；不影响加载/碰撞断言。 |
| `GPUParticles2D` | 无脚本的跑步烟尘子场景 | 可选外观，原场景 `emitting=false`；原版由移动状态切换启停。基础地图验收可以保持不发射，避免遮挡脚底和边界。 |
| `StateMachine` | 小型通用状态驱动脚本 | 条件候选，其驱动器通过 `owner` 调 `transition_state/get_next_state/tick_physics`。只有测试控制器满足接口、且仅实现待机/移动时才值得复用；不保留原版跳跃状态。 |
| `Follow`、`Graphics/AnimatedSprite2D/Hat` | 跟随物/帽子挂点及简单占用标记 | 低价值候选，阶段 0 没有对应挂载对象时无实际用途；`"Follow"`、`"Hat"` 组也不必为了外观保留。 |

证据：`scenes/player/momoi/momoi.tscn:33-46,84-126,260-310,349-394,420`；`scenes/player/StateMachine.gd:1-23`；`scenes/game_camera/gamecamera.gd:24-66`；`script/player.gd:263-320,389-423`；`scenes/shadow/shadow.tscn:1-6`；`script/follow.gd:1-3`、`script/hat.gd:1-3`。

原注意事项：Momoi 的 `AnimationPlayer` 是受击无敌帧/复位动画，`AnimationPlayer2` 是踢击/复位动画；待机和跑步帧动画属于 `AnimatedSprite2D.sprite_frames`。不能以“保留移动动画”为由把两个 `AnimationPlayer` 都带入阶段 0（`momoi.tscn:136-258,393,427`）。

### A.2 Original Omissions / 原排除项

| 原节点 | 原不建议带入的原因（已退出当前讨论） |
|---|---|
| Momoi 的 `Gun`、`Kick`、`MomoiPS`、`PlayerBuffManager` | 原版武器、攻击、技能和 Buff，按 C03 隔离。 |
| Momoi 的 `HurtBox`、`PickBox` 及其碰撞形状，`HealthComponent`、`Stats`、`T_HP_Count` | 受击、拾取、血量和完整玩法属性。仅需移动参数时可参考 `MAX_SPEED=155`，无须为一个速度值启动整个属性系统。不能把 Area2D 形状当成根碰撞体复用。 |
| Momoi 的 `FlyTimer/JumpTimer/JumpCDTimer/InvincibleFrame`、`JumpSounds/OnHitSounds/CoinSounds`、`AnimationPlayer/AnimationPlayer2`、`JumpCDBar`、`GameUI`、`CanvasLayer/PauseScreen` | 跳跃、受击、拾取、战斗 UI 和暂停路径均不属于本阶段；其中 `CanvasLayer` 本身只有普通容器价值。 |
| 角色相机内部的 `CanvasLayer/ColorRect/AnimationPlayer` | 原版运镜黑框演出；若最终采用简化相机，不需要同时引入这套演出。 |

证据：`scenes/player/momoi/momoi.tscn:310-448`。

</details>
