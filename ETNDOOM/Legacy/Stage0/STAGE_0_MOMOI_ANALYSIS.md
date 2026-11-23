# Stage 0 Momoi Analysis / 阶段 0 Momoi 原版处理分析

> Status / 状态：D06、D07 已实现；0.1/0.2 自动、像素和人工验收均已通过（用户于 2026-10-26 确认）。阶段 0.3 已于 2026-10-30 完成实现、回归、人工验收与交接，Gate D 已关闭。证据见[实施记录](STAGE_0_IMPLEMENTATION.md)。
> Scope / 范围：原版 Momoi 的角色数据、实体生成、移动驱动、外观与玩法依赖，以及对阶段 0 的影响；相机归属按 D07 执行。
> Source / 来源：用户 2026-10-23 明确 Momoi 是可用玩家角色中的一个实体，阶段 0 需要复用她验证移动；2026-10-24 补充敌怪重做前提并确认 D06、D07 决策；原版机制来自本地源码、场景和资源核对。
> Date / 日期：2026-10-24

## 1. Identity / 角色身份与实体

原版把 Momoi 组织为“角色数据 + 玩家实体场景 + 通用玩家逻辑 + 专属组件”，没有一个负责全部行为的 `momoi.gd`。

| 对象 | 原版职责 | 证据 |
|---|---|---|
| `resources/player/momoi.tres` | `PlayerCard` 数据：`id="momoi"`、名称、立绘、武器介绍、语音名及实体 `scene_path`；本身不移动、不接受物理碰撞。 | `resources/player/momoi.tres:8-17` |
| `scenes/player/momoi/momoi_card.tscn` | 主菜单选角 UI，`player` 字段指向实体场景；不是战斗中的 Momoi。 | `scenes/player/momoi/momoi_card.tscn:60-68` |
| `scenes/player/momoi/momoi.tscn` | 可实例化的玩家实体，根是 `CharacterBody2D`，加入 `"Player"` 组，绑定角色数据、属性节点及完整子树。 | `scenes/player/momoi/momoi.tscn:260-268` |
| `script/player.gd` | 根脚本，`class_name Player`；负责通用输入、移动、跳跃、朝向、受击表现等。 | `script/player.gd:1-20,204-423` |
| `MomoiPS` / `MomoiPS.gd` | Momoi 的专属被动组件：燃烧施加、燃烧目标额外承伤和升级后的扩散；不负责平面移动。 | `scenes/player/momoi/momoi.tscn:432-435`；`scenes/player/momoi/MomoiPS.gd:16-52,58-79` |

阶段 0 的验证对象是一个具有实际位置、速度和物理移动能力的 Momoi 玩家实体。实体场景内部哪些逻辑继续执行、哪些组件隔离，已由 D06 确定，见 §8.3。此前 D05 将 Momoi 节点排除于场景容器清单之外，不表示阶段 0 排除 Momoi；D06 于 2026-10-24 另行确认。

## 2. Spawn Flow / 选角、生成与初始化

正常单机流程如下：

1. 选角卡确认时调用 `GameEvents.emit_player_card_id(player)`；这里的 `player` 是 `res://scenes/player/momoi/momoi.tscn` 这样的场景路径，信号名里的 `id` 不表示一定传入 `"momoi"`（`ui/player_card.gd:275-299`）。
2. 难度页通过 `get_player_id()` 保存路径，确认难度并完成转场后调用 `GameEvents.change_scene(path, level_select.player)`（`ui/level_select.gd:24-25,287-288`；`ui/level_button.gd:132-139`）。
3. `GameEvents.change_scene()` 切换主场景，`load(player).instantiate()` 创建实体，再延迟挂入组 `"PlayerRoot"` 对应的容器，随后延迟发出 `first_round_add`（`script/GameEvents.gd:194-215`）。
4. Momoi 入树后，根和子节点分别初始化。`StateMachine` 等待根的 `ready`，将初始状态设为 `0`，即 `IDLE`（`scenes/player/StateMachine.gd:4-12`）。
5. `main.gd.first_round()` 清池、重置运行期属性修正、设置游戏模式并启动音乐；随后查找 `"Player"`，读取实体 `Stats` 的基础属性、发出 `set_player` 并重算属性，最后启动首回合和支援（`scenes/main/main.gd:58-94`）。

角色实例化与整局玩法初始化是两件事。仅从移动函数看，它读取实体自己的 `Stats` 和输入动作，没有调用首回合初始化；但原场景中的其它组件仍各有依赖，不能据此宣称完整 Momoi 子树已经能脱离原版流程独立运行。

阶段 0 的 D04 已选择自己创建测试场景和角色，不经过上述 `GameEvents.change_scene()` 生成链。因此既要显式完成移动所需初始化，也不能为获取移动参数而顺带启动 `main.gd.first_round()`。

## 3. Movement / 移动如何执行

### 3.1 Driver / 驱动关系

玩家根脚本没有用自身的 `_physics_process()` 执行移动。实际调用链是：

```text
StateMachine._physics_process(delta)
  owner.get_next_state(current_state)     判断状态，循环到稳定
  owner.transition_state(from, to)        状态变化时切换动画及相关表现
  owner.tick_physics(current_state, delta)
    Player.move(...)
      Player.get_movement_vector()
      更新 CharacterBody2D.velocity
      CharacterBody2D.move_and_slide()
```

`owner` 是 Momoi 场景根节点。只关闭或替换根节点自己的 `_physics_process()`，不会自动停止该子状态机调用根的方法；反过来，只关闭状态机也不会自动关闭枪的独立物理回调或撤销全局信号（`scenes/player/StateMachine.gd:4-22`；`script/player_gun.gd:33-52`）。

### 3.2 Planar Motion / 平面移动

| 环节 | 原版处理 | 证据 |
|---|---|---|
| 输入 | `Input.get_axis("move_left", "move_right")` 与 `Input.get_axis("move_up", "move_down")` 组成二维向量；由 `can_control` 控制是否读取。 | `script/player.gd:341-348` |
| 方向 | `Game.control_mode == 0` 时归一化输入，避免键盘斜向目标速度更快；其它控制模式直接使用原输入向量，保留模拟量幅度。 | `script/player.gd:301-305` |
| 基础参数 | Momoi 场景设 `MAX_SPEED=155`；`SPEED_TIME` 沿用 `Stats` 默认值 `0.2`。无属性修正时，每轴加速度为 `155 / 0.2 = 775`。 | `scenes/player/momoi/momoi.tscn:360-368`；`script/Stats.gd:31-32`；`script/player.gd:225-226` |
| 速度更新 | x、y 分别用 `move_toward()` 接近目标速度；松键后以同样方式减速，不是立刻归零。 | `script/player.gd:307-310` |
| 实际位移 | 更新根实体的 `velocity`，再调用 `move_and_slide()`，由物理引擎处理墙体阻挡和沿边滑动。 | `script/player.gd:299-325` |
| 运行期修正 | 正常游戏由 `PlayerData` 快照并合成属性，修改实体实际使用的 `stats.MAX_SPEED` / `stats.SPEED_TIME`。 | `script/PlayerData.gd:276-287,347-360` |

注意：`move()` 虽然有名为 `MAX_SPEED` 的形参，速度目标实际写的是 `stats.MAX_SPEED`。不能仅根据调用时传入的值判断实际速度；例如跳跃分支传入 `stats.MAX_SPEED * 2`，不等于速度目标真的翻倍。本次只记录现状，不修复或重定义原版移动（`script/player.gd:243-244,299-310`）。

三个控制开关的作用不同：

- `can_control=false`：输入向量为零；若仍执行移动，已有速度会逐渐减小。
- `player_stop=true`：强制目标方向为零，同时阻止根脚本处理跳跃、射击、踢击、换弹和暂停输入；不能据此保证子组件完全停止。
- `can_move=false`：`tick_physics()` 跳过移动分支，但后面的弹药、枪口、朝向、光环和脚步逻辑仍执行。

证据：`script/player.gd:204-297,301-310,341-348`。

### 3.3 State and Jump / 状态与跳跃

原版状态为 `IDLE / RUNNING / JUMP / FLY / FALL`。`IDLE` 和 `RUNNING` 都执行同一个平面移动函数；状态切换主要决定动画、烟尘与脚步开关（`script/player.gd:4-10,233-250,389-423`）。

待机/跑步判断依赖当前实际 `velocity` 和落地条件，因此按键后的动画不是单纯按“是否按着移动键”决定。原版落地条件为精灵局部 `position.y == -17`，没有调用 Godot 的 `is_on_floor()`（`script/player.gd:350-370`）。

跳跃仍使用同一个二维根物理体；升空和下落主要通过修改 `AnimatedSprite2D.position.y` 表现，并切换 `z_index`、计时器、闪避状态和相关信号。当前玩家逻辑没有独立的世界高度字段（`script/player.gd:299-320,350-423`）。

`can_jump=false` 只在输入入口拦截新请求；`get_next_state()` 内另有同名局部变量，判断的是落地与冷却状态。`round_start` 还会通过 `reset_control_flags()` 重新开启成员 `can_jump`。阶段 0 禁跳不能只依靠一次赋值而保留其它跳跃路径不检查（`script/player.gd:102-108,204-208,350-359`）。

## 4. Geometry and Appearance / 物理形状与外观

| 部分 | 原版配置 / 行为 | 阶段 0 的分析意义 |
|---|---|---|
| 根 `CharacterBody2D` | `motion_mode=1`，`collision_mask=256`，查询墙体层。 | 这是承载实际位移与地图碰撞的实体。 |
| 根 `CollisionShape2D` | 半径 `7` 的圆，局部偏移 `(0,-6)`。 | 墙体停止位置应按这个圆计算；圆心、根原点与精灵中心不是同一点。 |
| `HurtBox` | 独立 `Area2D`，包含受击胶囊形状，`is_player=true`。 | 参与伤害/接触查询，不承担根物理体的墙体滑动。 |
| `PickBox` | 另一独立 `Area2D`，初始圆半径 `35`。 | 用于发现拾取物，与根碰撞圆不同。 |
| `Graphics/AnimatedSprite2D` | 局部位置 `(0,-17)`；`SpriteFrames` 中包含 `idle`、`run`、`jump`。 | 待机/跑步资产已在实体场景中，不需要重新制作。 |
| `Graphics` / `Halo` | 朝向由准星位置决定，翻转 `Graphics.scale.x` 和 `halo.flip_h`，不是根据移动方向决定。 | 若移除原版准星系统，朝向规则需要单独处理。 |
| `AnimationPlayer` / `AnimationPlayer2` | 分别负责受击闪烁和踢击/复位轨道。 | 不应把它们误认为待机/跑步动画播放器。 |
| `Camera2D` | 原版场景实例化 `gamecamera.tscn`，Momoi 另设 `offset=(0,-15)`。 | D07 已确认在 Momoi 入树前移除此相机，改由测试场景持有独立 `Camera2D`；原版信号行为不纳入阶段 0。 |

证据：`scenes/player/momoi/momoi.tscn:33-34,84-127,129-258,260-335,393-428`；`script/player.gd:255-287,327-336`；`scenes/game_camera/gamecamera.gd:26-66`。

2026-10-24 修正：D08 已确认。0.1 以玩家根 `CharacterBody2D.global_position` 严格越过逻辑边界为准；0.2 以实际根碰撞形状（含半径、偏移与世界变换）对四边内侧的接触为准。脚底或阴影只作视觉辅助，边界线本身不算越界；详见开发细化文档 §3.3.3。此前“D08 尚未裁决”已失效。（来源：user）

## 5. Coupling / 为什么不能直接删除玩法节点

| 依赖位置 | 原版耦合 | 对隔离方式的约束 |
|---|---|---|
| 根脚本 `@onready` | 直接取得 `Gun`、跳跃计时器、`HurtBox`、`PickBox`、UI、相机和各类表现节点。 | 保留根脚本却删除这些节点，会产生失效引用；根逻辑也要同步适配。 |
| 根 `_ready()` | 初始化枪弹药，订阅射击、金币、结束、准星和回合信号。 | 入树后再隐藏/禁用节点，不能撤销已经发生的初始化或信号订阅。 |
| `tick_physics()` | 即使只处于 `IDLE/RUNNING`，仍读枪弹药、跳跃冷却，操作枪口、受击状态、光环、脚步和烟尘。 | 仅将状态限制为待机/跑步，仍不等于只运行移动。 |
| `Gun` | 自己有 `_physics_process()`，可生成子弹、枪口特效并给玩家施加后坐速度。 | 只隐藏武器或关闭玩家状态机，不足以隔离武器。 |
| `MomoiPS` | `_ready()` 连接敌人伤害事件，基类还连接被动升级事件。 | 禁用逐帧处理不等于禁用被动回调，须防止注册或处理连接。 |
| `GameUI` / `PlayerBuffManager` / `T_HP_Count` | 分别连接属性/全局 UI 信号、Buff 事件和回合事件。 | 隐藏界面不等于停止玩法状态变更。 |
| `"Player"` 组 | `PlayerData`、武器和其它系统通过组查找玩家；`MapBounds` 也通过该组查找并处理越界。 | 保留组需验证全局介入；移除组也需处理原组件的查找依赖。 |

证据：`script/player.gd:56-108,225-297`；`script/player_gun.gd:33-52,119-186`；`script/PlayerPS.gd:10-14`；`scenes/player/momoi/MomoiPS.gd:16-35`；`ui/game_ui.gd:27-41`；`scenes/manager/player_buff_manager.gd:6-12`；`scenes/player/t_hp_count.gd:7-20`；`script/PlayerData.gd:182-183`；`script/map_bounds.gd:24-62`。

`MapBounds` 使用全局 tick，取得边界后可以直接改写根实体位置并清空速度。阶段 0.1 要验证越界，阶段 0.2 要验证真实物理阻挡，两者都必须排除这条介入路径；不能将它造成的停止或回位算作 `move_and_slide()` 的结果。

## 6. D06 Decision / D06 已确认决策

当前已确认的是：使用一个 Momoi 玩家实体来验证移动，固定加载原角色场景，阶段 0 只允许外观和平面移动。原版现成提供实体物理体、碰撞圆、移动参数、输入/加减速规则和动画资源；它们可以作为复用与对照的依据。

技术方式对比如下；用户于 2026-10-24 确认采用第二项，由模组自有根逻辑接管。其余方式保留为方案比较，不是并列实施路径：

| 候选方式 | 能复用什么 | 必须解决的问题 |
|---|---|---|
| 实例化原场景，保留 `Player` 根逻辑并显式增加阶段 0 隔离 | 原玩家类型及原移动调用路径。 | 必须覆盖根初始化、状态机、输入、子组件初始化/信号和全局组依赖；现有控制开关不够。 |
| 实例化原场景，在入树前适配根逻辑和子树（已确认） | 原场景实例的物理体、形状、外观及所需基础参数。 | 新根直接继承 `CharacterBody2D`，不依赖原 `Player`；入树前处理子树、信号与组。验收验证 ETNDOOM 接管后的移动路径，具体见 §8.3。 |
| 复制并裁剪出独立角色场景 | 复制时保留的实体配置和资源。 | 增加场景同步成本；若改为只加载复制品，就与 C02 当前固定加载原场景的约束不一致，不能未经确认直接采用。 |

若目标是验证“原版 Momoi 的移动能否在新地图上工作”，应尽量保持输入、加减速、物理形状与 `move_and_slide()` 的语义一致，并明确任何适配差异；仅让一张 Momoi 动画贴图改变位置，不能覆盖这项验证。

选择理由：原版待机/跑步也会访问枪、跳跃计时器和受击等组件，保留旧根逻辑会持续承担隔离成本。用户又已明确阶段 5/7 的敌怪将大幅重做或新设计，整体接管旧敌怪行为不再是成本基准；阶段 0 从一个由模组控制的玩家实体开始，后续按实际交互需要建设生命周期与调度职责。

D06 已移入开发细化文档的已确认决策；§8.3 的适配顺序、保留范围、移动基线和朝向规则均按本次确认执行。用户随后确认 D07 使用测试场景独立相机，Momoi 子树内的原相机在入树前移除；契约见开发细化文档 §3.3.2。D08 坐标判据和 D10 开发源目录现均已确认；其它阶段决策按开发细化文档 §1 执行。没有运行阶段 0 或声明移动、相机/碰撞验收通过。（来源：user）

## 7. Call Ownership / 根逻辑由谁运行

用户于 2026-10-23 进一步询问根逻辑的调用者，以及是否可由 ETNDOOM 重写玩家乃至所有实体的逻辑。以下说明调用事实与候选方向，不将提问视为方案确认。

Momoi 根节点挂载的 `script/player.gd` 是脚本实例，由 Godot 执行；其方法通过不同入口被调用，并非由一个原版实体管理器统一轮询。

| 入口 | 谁触发 | 运行什么 |
|---|---|---|
| `@onready` 与 `_ready()` | Godot 节点就绪流程。 | 取得枪、计时器、受击区域、UI 等引用，初始化弹药并建立全局信号连接。 |
| `_unhandled_input(event)` | Godot 的未处理输入分发。 | 跳跃请求、暂停、射击开关、踢击和换弹；移动方向另在物理更新中读取。 |
| `get_next_state()` / `transition_state()` / `tick_physics()` | 子 `StateMachine` 的物理回调及 `current_state` setter。 | 判断状态、切换表现，执行移动及枪口、受击、光环、脚步等耦合逻辑。 |
| `get_crosshair_pos()` / `reset_control_flags()` / `bullet_hit_damage()` 等 | 已连接的信号发出时，Godot 调用对应的 `Callable`。 | 按事件更新准星、控制开关或子弹伤害；这些不是逐帧状态机的下级调用。 |
| `Gun._physics_process()` 等子节点回调 | Godot 对各个子节点分别调度。 | 子组件独立运行；根脚本没有调用它们的全部更新。 |

本地证据：`script/player.gd:56-108,204-297`；`scenes/player/StateMachine.gd:4-22`；`script/player_gun.gd:33-52`。引擎机制参照 Godot 官方文档 `Node` 的生命周期、输入与物理处理说明，以及 `GDScript reference` 的 `Initialization order`。

因此，替换 `tick_physics()` 只替换其中一条调用路径；新增一个实体管理器，也不会自动停止原有生命周期、输入、状态机与信号回调。

## 8. Mod-Owned Entities / 模组自有实体逻辑与 D06 决策

### 8.1 Feasibility / 可行性

可以在 ETNDOOM 模组中实现新的实体逻辑。`ModManager` 会加载已挂载模组的 entry，创建其 `Node` 并加入树中；entry 可加载模组自己的场景和脚本（`script/mod_manager.gd:1059-1079`）。Godot 也支持通过 `Object.set_script()` 更换对象脚本，同时保留对象内建属性。

Momoi 仍可作为有实际物理体、位置、速度和外观的玩家实体存在，由新脚本控制；保留原 `Player` 脚本类型不是实体能够运行的必要条件。但若新逻辑不再执行 `Player.move()`，验收对象应明确为 ETNDOOM 的实体移动，而不是原版控制器原样兼容。前文 §6 的原移动规则可作为对照，不是必须保留旧根逻辑的要求。

技术上还可让 ETNDOOM 管理本模式生成的玩家、敌人、子弹和拾取物；“所有实体”应先限定为本模式拥有的实体。本体 autoload、其它模组和正常模式实体的全局接管是更大的兼容范围，不由此方案自动包含。

### 8.2 Suggested Responsibilities / 建议职责

以下为建议名称与职责，尚未创建这些类或冻结接口：

| 部分 | 建议职责 |
|---|---|
| `EntityWorld` | 本模式实体的登记、ID、创建与销毁入口，以及需要时的统一更新顺序；跟随本次模式场景存活。 |
| 移动实体 / `ActorBody` | 保存该实体的移动状态与碰撞配置，执行物理移动；阶段 0 使用 `CharacterBody2D.move_and_slide()`。 |
| `PlayerController` / `EnemyController` | 分别将玩家输入或 AI 决策转换为移动/动作意图，共用需要一致的空间规则。 |
| `ActorView` | 根据实体状态显示 Momoi 等角色的动画、朝向、光环与阴影，不承担移动判定。 |
| 子弹、拾取物等专用行为 | 共用必要的登记与生命周期约定，各自选择合适的节点类型与更新方式；不强制全部继承移动角色基类。 |

阶段 0 只需实现一个玩家的创建、移动和表现，不提前建设完整 `EntityWorld`、AI、武器、伤害或完整 `ModeSession`。可先让新玩家根脚本获得自己的物理回调，未来有确定的跨实体更新顺序需求时，再将该更新入口交给调度器；同一实体每个物理 tick 只执行一次移动。

后续独立高度与通行服务的职责已有草案（`ETNDOOM/ModdingDocs/NEW_MODE_MAP_PLAN.md` §2–§3），但阶段 0 只做平面验证，不提前冻结世界高度、WAD 通行或正式实体接口。

### 8.3 Momoi Adaptation / 沿用原场景的接管方案

以下为用户于 2026-10-24 确认的 D06 实施约束，保留 C02 的原场景加载要求，并取得该实例的行为所有权。D01–D10 与 Gate A 均已完成；本节已实现为 `etndoom_mod/stage0/stage0.gd:73` 的入树前适配，两模式运行验证通过：

1. 加载并实例化原场景，暂不加入活动场景树。
2. 从原 `Stats` 读取并校验 `MAX_SPEED`、`SPEED_TIME` 等所需数值，记录固定角色来源，保存待保留的碰撞和外观引用。参数不合法或预期节点缺失时报告适配失败，不继续挂载半成品。
3. 在更换根脚本前，清除根的 `is_hurt` 自连接及 `PickBox`、`JumpCDTimer`、`Stats` 指向旧根方法的序列化连接；再将不带入的玩法子树从该实例移除并释放。不能只对仍挂在待入树实例中的节点调用 `queue_free()` 后立即将根入树，以免其在延迟释放前进入原就绪流程。
4. 为同一个 `CharacterBody2D` 实例设置模组自有根脚本，直接继承 `CharacterBody2D`，显式赋予保存的移动参数、物理形状和表现引用。原版 `Stats` 读出所需数值后移除，不将旧运行期属性合成搬入新根。
5. 入树前移除根的 `"Player"` 组及保留子树上的其它原版玩法组，测试场景直接持有角色引用。由此避开 `MapBounds` 按 `"Player"` 查询的路径；保留节点如有脚本仍需检查是否会重新入组或订阅原版事件。
6. 按 0.1/0.2 设定根形状和墙体 mask 后加入测试场景，由新根的单个物理回调独占移动。相机由测试场景独立持有并显式跟随该玩家，不加入 Momoi 子树；详细契约按开发细化文档 §3.3.2 执行。

已确认的保留范围：

| 部分 | 阶段 0 确认处理 |
|---|---|
| 原根 `CharacterBody2D`、根 `CollisionShape2D` | 保留实例及形状配置；0.1 禁用形状和碰撞查询，0.2 恢复形状、使用 mask `256`。 |
| `Graphics/AnimatedSprite2D`、`Halo`、阴影等必要外观 | 复用资源与局部锚点，必要时去掉旧脚本；只保留经核对不运行玩法逻辑的部分。 |
| `Stats` | 提取基础移动参数后移除，由新逻辑保存所需数值。 |
| `StateMachine`、`Gun`、`Kick`、跳跃与受击 Timer | 移除；待机/跑步表现由新根依据移动结果切换。 |
| `MomoiPS`、`PlayerBuffManager`、`HealthComponent`、`HurtBox`、`PickBox`、`T_HP_Count` | 移除，不注册原版战斗、被动、拾取和回合回调。 |
| `GameUI`、暂停 UI、原受击/踢击 `AnimationPlayer`、脚步/跳跃等玩法音效与烟尘 | 不带入活动子树；阶段 0 无对应玩法或特效需求。 |
| 原 `Camera2D` | 整体实例化 Momoi 时可能暂时生成；入树前连同附属黑幕/动画子树移除并释放，不激活原相机。阶段 0 相机由测试场景独立持有，按开发细化文档 §3.3.2 跟随玩家且不连接原版镜头信号。 |

移动基线沿用原输入动作与 `Game.control_mode` 对归一化的选择，每轴 `move_toward()` 加减速，基础速度 `155`、`SPEED_TIME=0.2`，根圆半径 `7`、偏移 `(0,-6)`，最终调用 `move_and_slide()`。这些是阶段 0 的对照配置，后续体型、控制手感和 DOOM 通行规则仍可重新设计。人物朝向按水平移动意图更新，停止或纯竖向移动时保持朝向；这是替代原准星驱动朝向的明确差异，不为阶段 0 接入准星系统。

每次物理更新的职责为“读取输入意图 → 更新速度 → 执行一次物理移动 → 更新必要表现”。阶段 0 可集中在一个小根脚本中，不要求将示意的 `PlayerController`、`ActorBody`、`ActorView` 都拆成独立类。后续若引入统一调度，须把这条更新入口交给调度器并停用原回调，保持一个移动执行者。

必须注意：入树前处理能避免原树的 `_ready()` 链先运行，但 `instantiate()` 已可能执行脚本 `_init()` 和导出属性赋值，不能等同于原场景完全没有初始化。`Object.set_script()` 会丢弃旧脚本实例的属性值和状态，而保留内建属性；不能假设旧 `stats`、`player_card` 等脚本字段自动迁移。仅换根脚本也不会替代对子节点、组和场景信号连接的检查。

本地证据：`scenes/player/momoi/momoi.tscn:260-268,357-368,432-448`；`script/player.gd:12-15,56-108`；`script/map_bounds.gd:24-62`。引擎机制参照 Godot 官方文档 `Object.set_script()`、`Node` 的入树/就绪顺序及 `GDScript reference` 的初始化顺序。运行证据为 `tests/stage0_results/20261024_final/stage01/result.json` 与 `stage02/result.json`；旧根连接清理必须只针对旧脚本回调，不能无差别撤销引擎 Container 的内部连接，详见 `ETNDOOM/LEARNINGS.md`。（来源：test，2026-10-24）

截至 2026-10-24 的自动回归验证：原根及被移除组件入树前均未 ready；保留子树没有原玩法全局信号订阅，旧根序列化连接已清理；攻击/跳跃输入不启动玩法，全局时间事件不改变位置；0.1/0.2 每物理 tick 只有一次移动，分别满足越界和真实阻挡/滑动要求。用户于 2026-10-26 确认 0.1/0.2 人工验收均符合预期；阶段 0.3 后续已于 2026-10-30 完成并关闭 Gate D，证据见实施记录 §6。测试对象是复用 Momoi 实体配置的 ETNDOOM 控制路径。（来源：test、user）

## 9. Decision History / 决策历史

以下保留讨论当时的状态，不作为当前开工条件。现行结论为 D01–D10 已决策、Gate A 已完成，可开始 0.1；具体约束见开发细化文档 §1、§7–§8。

SUPERSEDED: 2026-10-24 原“优先评估模组自有控制逻辑”的候选现收束为上述 D06 明确推荐，依据原版管理调查与用户已确认的敌怪重做前提；方案采用仍待用户确认，没有批准实施或扩展阶段 0 的实体范围。

历史讨论（2026-10-23，以下状态均以开发细化文档 §1、§8 的现行结论为准）：用户要求结合 DOOM 的实体管理评估兼容收益、局限与重做成本。建议将“接管一个玩家的最小控制逻辑”与“重做全部实体管理”分开决策，保留 DOOM 的关键交互语义，按实际需求逐步建立本模式的生命周期和调度职责；不据此承诺完整 WAD 或原版行为精确兼容。体型差异、更新顺序及 Godot 物理边界见 [Entity Management Recommendation / 实体管理与 DOOM 兼容建议](ENTITY_MANAGEMENT_RECOMMENDATION.md)。本轮仍为建议，不裁定 D06。

SUPERSEDED: 2026-10-24 用户随后确认上述建议为 D06 实际决策，原“采用仍待用户确认”“不裁定 D06”仅保留为讨论历史。单玩家最小接管方案已确认；完整实体管理架构和 D07–D10 未因此裁定，功能尚未实现。D10 的开发源目录随后另行确认，现行路径以开发细化文档 §7–§8 为准。（来源：user）
