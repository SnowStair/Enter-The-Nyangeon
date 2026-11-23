# ETN Entity Management / 原版全体实体管理

> Status / 状态：当前本体源码的静态分析，未修改功能代码、未做运行验收。
> Scope / 范围：当前仓库单机路径的玩家、敌人、弹丸、召唤物、拾取物和场景道具；不把联机 Mod 的镜像管理计入原版管理职责。
> Source / 来源：用户 2026-10-24 询问原版对于全体实体的管理，并补充阶段 5/7 敌怪重做前提；原版机制来自本地源码，后续设计前提在 §7 标注来源。
> Date / 日期：2026-10-24

## 1. Overall Model / 整体模型

ETN 使用 Godot 节点与场景承载对象，在其上组合分类生成器、对象池、分组查询、组件和全局信号。引擎调度节点回调；ETN 没有另建一个覆盖所有玩法实体的统一注册表和统一游戏更新循环。

管理职责应分别理解：

| 职责 | 实际承担者 |
|---|---|
| 实体的场景挂载与父子关系 | `SceneTree`、各类 Root 容器及生成调用方 |
| 移动、AI、武器等行为 | 实体根脚本、子状态机、武器与其它子组件 |
| 生成与初始配置 | 玩家切场景流程、敌人波次/出生脚本、弹丸辅助器、召唤来源、拾取物生成器 |
| 复用与部分计数 | `PoolManager`、`CoinManager`，由实体上报状态 |
| 查找对象与广播事件 | 节点组、分类活跃表、`Targeting`、`PlayerRef`、`GameEvents` |
| 回合清场与最终释放 | `RoundManager` 发信号，`main.gd` 分类处理；其它场景有自己的清理代码 |

`Player`、`Enemy`、`Summoned` 分别直接继承 `CharacterBody2D`；弹丸通过 `HitBox` 继承 `Area2D`，`SceneProp` 继承 `Node2D`。这些类型不共享一个 ETN 自定义 `Entity` 基类。

证据：[Player](E:/ETN_DOOM/script/player.gd:1)、[Enemy](E:/ETN_DOOM/script/entity_ENEMY.gd:1)、[Summoned](E:/ETN_DOOM/script/summoned.gd:1)、[PlayerBullet](E:/ETN_DOOM/script/player_bullet.gd:1)、[HitBox](E:/ETN_DOOM/script/hit_box.gd:1)、[SceneProp](E:/ETN_DOOM/script/props/scene_prop.gd:1)。

## 2. Scene Ownership / 场景归属

主场景在 `YSort` 下设置 `PlayerRoot`、`EnemiesRoot`、`CoinRoot`、`PropRoot`、`BulletRoot` 和 `FieldModRoot`；另有 `EquipLayer`、`SELayer`、`ForegroundLayer`。

这些 Root 是挂载容器，不是自行遍历并更新全部子实体的管理器。组名又被生成器用于定位容器，因此同时构成隐式接口。

容器名称不等于严格类型边界：Utaha 炮台作为召唤物直接加入 `PlayerRoot`，医疗箱加入 `CoinRoot`。不能通过“`PlayerRoot` 的全部子节点”推导“全是玩家”，也不能通过“`CoinRoot` 的全部子节点”推导“全是金币”。

证据：[主场景容器](E:/ETN_DOOM/scenes/main/main.tscn:295)、[炮台挂载](E:/ETN_DOOM/scenes/player/utaha/UtahaPS.gd:59)、[医疗箱挂载](E:/ETN_DOOM/scenes/manager/pick_item_manager.gd:51)。

## 3. Creation / 分类生成

| 对象 | 主要创建路径 | 行为与生命周期归属 |
|---|---|---|
| 玩家，包括 Momoi | `GameEvents.change_scene()` 加载选定角色场景，延迟加入 `PlayerRoot` | `Player`、状态机、角色被动、武器和受击等组件 |
| 普通敌人 | `EnemyManager` 选择波次生成场景，出生脚本取池或实例化敌人 | 具体 `Enemy` 子类、`EnemyStateMachine`、各子组件；Boss 另有编排 |
| 弹丸 | `ProjectileSpawner` 收敛取池/新建、配置、挂载、激活、拓展通知 | 玩家弹、敌弹和召唤弹各自运行；辅助器不逐帧管理它们 |
| 召唤物 | 角色被动或装备脚本等直接实例化 | `Summoned` 及其子类；`SummonedManager` 跟踪区域中的召唤物并刷新属性 |
| 金币 | `CoinManager.drop_coin()` 优先复用，必要时新建或合并价值 | `coin.gd` 自行移动、拾取、回池，并上报活跃状态 |
| 医疗等拾取物 | `PickItemManager` 等按回合、Timer 或定点需求生成 | 对应拾取脚本；并非所有拾取物都使用对象池 |
| 场景道具 | 场景预置或具体生成代码 | `SceneProp` 与碰撞、受击、交互等组件；具体对象决定销毁行为 |

证据：[玩家创建](E:/ETN_DOOM/script/GameEvents.gd:194)、[波次选择](E:/ETN_DOOM/scenes/manager/enemy_manager.gd:173)、[敌人出生](E:/ETN_DOOM/script/spawn_anim.gd:85)、[弹丸辅助器](E:/ETN_DOOM/script/projectile_spawner.gd:17)、[装备创建炮台](E:/ETN_DOOM/scenes/update_item/utaha_turret.gd:15)、[召唤物跟踪](E:/ETN_DOOM/scenes/manager/summoned_manager.gd:7)、[金币掉落](E:/ETN_DOOM/scenes/manager/coin_manager.gd:63)、[医疗生成](E:/ETN_DOOM/scenes/manager/pick_item_manager.gd:72)、[油桶销毁](E:/ETN_DOOM/script/props/oil_barrel.gd:21)。

`ProjectileSpawner` 统一的是生成步骤，不是所有实体的工厂；它还保留 `notify_local()` 供 `duplicate()` 等特例手动通知。不同站点可选择先入树再激活、先激活再入树或延迟入树，不存在所有对象完全相同的初始化时序。

## 4. Updates / 谁运行实体逻辑

玩家的典型调用链：

```text
Godot 物理回调
  -> StateMachine._physics_process(delta)
     -> owner.get_next_state()
     -> owner.transition_state()
     -> owner.tick_physics()
        -> 根脚本的状态行为与移动
```

因此，Momoi 根脚本中的普通移动方法由她自己的状态机调用。就绪、输入、全局信号、Timer 和动画方法轨道又是其它调用入口，不能认为某个管理器统一调用了根脚本的所有逻辑。

证据：[玩家状态机](E:/ETN_DOOM/scenes/player/StateMachine.gd:4)、[Momoi 详细分析](E:/ETN_DOOM/ETNDOOM/ModdingDocs/Stage0/STAGE_0_MOMOI_ANALYSIS.md:1)。

敌人的 `EnemyStateMachine` 每个物理帧调用 `owner.tick_physics()`；状态重评受 `cd_time` 控制，每 3 个 `global_time_count` 重新开放一次，正常约 0.3 秒。不是每 3 个物理帧才移动一次，也不是全体实体都使用 0.3 秒更新周期。

弹丸和金币等直接在各自 `_physics_process()` 中运动。实体还通过全局 tick 处理寿命、Buff 或冷却；这是多种更新入口并存的结构。

证据：[敌人状态机](E:/ETN_DOOM/script/EnemyStateMachine.gd:12)、[玩家弹运动](E:/ETN_DOOM/script/player_bullet.gd:166)、[金币运动](E:/ETN_DOOM/scenes/item/coin.gd:96)。

### Global Tick / 全局 tick 的实际来源

普通战斗中，`ui/round_timer.tscn` 的 `GlobalTimer` 以 `wait_time=0.1` 计时；超时进入 `round_timer.gd`，再调用 `GameEvents.emit_global_time_count()` 广播。计时器在回合启动流程中开启。测试房则用自己的 0.1 秒 Timer 发同一信号。

这不是 `GameEvents` autoload 自行产生的永久模拟时钟，也不等于 Godot 物理帧。若独立模式去掉 `RoundTimer` 场景但仍保留依赖这条信号的原版行为，必须另行解决计时来源。仅把 HUD 隐藏与删除承载 Timer 的场景也应区分。

证据：[Timer 配置](E:/ETN_DOOM/ui/round_timer.tscn:465)、[回合启动计时](E:/ETN_DOOM/ui/round_timer.gd:132)、[超时广播](E:/ETN_DOOM/ui/round_timer.gd:508)、[信号包装](E:/ETN_DOOM/script/GameEvents.gd:575)、[测试房时钟](E:/ETN_DOOM/scenes/main/test_room.gd:130)。

## 5. Pools and Lifetime / 对象池与生命周期

`PoolManager` 按 `pool_id` 保存节点数组、集合、空闲缓存与轮转位置。实体在自身 `_ready()` 等位置注册；取不到空闲对象时通常由调用方实例化。部分池达到配置数量后允许强制回收，未配置限制的池不设限。

回池的实际工作由实体 `idle_state()` 或 `deactivate_silent()` 完成，例如隐藏、停物理回调、关闭碰撞、断开自身计时回调和清理状态。池并不统一替全部类型执行这些步骤。

`tree_exiting` 用于移除池记录。`detach()`、`erase_pool()`、`clear_pool()` 操作管理记录；其中 `clear_pool()` 还清空活跃敌人登记，但它们不因此释放对应场景节点。

证据：[注册池](E:/ETN_DOOM/scenes/manager/PoolManager.gd:427)、[退出注销与 detach](E:/ETN_DOOM/scenes/manager/PoolManager.gd:485)、[强收调用](E:/ETN_DOOM/scenes/manager/PoolManager.gd:522)、[取池策略](E:/ETN_DOOM/scenes/manager/PoolManager.gd:556)、[清表语义](E:/ETN_DOOM/scenes/manager/PoolManager.gd:125)、[玩家弹回池](E:/ETN_DOOM/script/player_bullet.gd:103)。

普通敌人的典型生命期：

```text
波次选择 -> 出生动画 -> 取池或新建 -> 配置属性与位置 -> active_state()
  -> 自身状态机运行、接受伤害
  -> Stats 发死亡信号 -> 掉币与 on_dead() -> 延迟 idle_state()
  -> 节点留在场景中，等待复用
```

敌人回池时注销活跃登记、隐藏、禁用自身及状态机物理回调、禁用碰撞并清 Buff；激活时恢复相关状态并重新登记。这里只说明基类普通路径，Boss 或具体子类可覆写死亡行为。

回合清场是另一条路径：`RoundManager` 发分类信号，`main.gd` 遍历容器，敌人清表后 `queue_free()`；敌弹释放，其他活跃弹丸调用 `idle_state()`；医疗物释放，金币另走 `coin_clear()`。没有全体实体一律执行的通用 `destroy()`。

证据：[敌人激活与失活](E:/ETN_DOOM/script/entity_ENEMY.gd:113)、[死亡与掉币](E:/ETN_DOOM/script/entity_ENEMY.gd:538)、[死亡信号处理](E:/ETN_DOOM/script/entity_ENEMY.gd:576)、[清场接线](E:/ETN_DOOM/scenes/main/main.gd:26)、[分类清理](E:/ETN_DOOM/scenes/main/main.gd:99)。

`SceneProp.on_round_end()` 是可调用的生命周期方法；基类没有自行订阅 `GameEvents.round_end`，不能因方法存在就推导所有场景道具会自动随回合清理。测试房重置显式遍历 `"SceneProp"` 组释放。

证据：[SceneProp 方法](E:/ETN_DOOM/script/props/scene_prop.gd:13)、[测试房清道具](E:/ETN_DOOM/scenes/main/test_room.gd:89)。

## 6. Queries and Interaction / 查询与交互

原版有多套用途不同的集合：

| 集合 | 表达的含义 |
|---|---|
| Root 容器子节点 | 场景归属，可能混合类型及活跃/待机状态 |
| `"Player"`、`"Enemy"`、`"Summoned"` 等组 | 分类与约定接口，使用时仍须判断状态和有效性 |
| `PoolManager.pool` | 已注册、可复用的对象集合，不等于活跃对象 |
| `PoolManager._active_enemies` | 按节点 `instance_id` 登记的活跃敌人，维护时排除部件 |
| `CoinManager._active` | 活跃金币，独立于活跃敌人表 |
| `SummonedManager.summoned_group` | 被其 Area2D 跟踪到的召唤物，不是独立于空间范围的通用实体表 |

活跃敌人表由敌人的激活、失活和退出上报维护，并约每秒用 `"Enemy"` 组纠偏。数量超过 80 发停止刷怪信号，回落再恢复；这是生成节流，不能当作全体实体上限或严格的 80 个敌人硬上限。

`Targeting` 优先读取活跃敌人表，过滤无效、待机及玩家方对象，结果为空时回退 `"Enemy"` 组，并按物理帧缓存候选。`PlayerRef` 从 `"Player"` 组解析玩家，允许调用方在旧引用失效后重取。`InteractionManager` 按组 `"Interactable"`、范围状态和优先级选交互对象。

证据：[活跃敌人登记](E:/ETN_DOOM/scenes/manager/PoolManager.gd:140)、[生成节流与纠偏](E:/ETN_DOOM/scenes/manager/PoolManager.gd:241)、[选敌](E:/ETN_DOOM/script/targeting.gd:13)、[玩家引用](E:/ETN_DOOM/script/player_ref.gd:12)、[交互选择](E:/ETN_DOOM/scenes/manager/interaction_manager.gd:52)、[召唤物探测范围](E:/ETN_DOOM/scenes/manager/summoned_manager.tscn:8)。

碰撞、伤害和位置纠正也不是池的职责：角色通过自身移动函数调用 `move_and_slide()`；弹丸有自己的射线与位移；`HurtBox` / `HitBox`、血量组件和属性节点传递命中与死亡；`MapBounds` 又按约 1 秒周期检查玩家、活跃敌人和召唤物，必要时直接纠正位置与速度。

证据：[玩家移动](E:/ETN_DOOM/script/player.gd:320)、[命中入口](E:/ETN_DOOM/script/hurt_box.gd:39)、[血量组件](E:/ETN_DOOM/script/health_component.gd:28)、[扣血](E:/ETN_DOOM/script/health_component.gd:160)、[出界回位](E:/ETN_DOOM/script/map_bounds.gd:24)。

## 7. ETNDOOM Implications / 对模组接管的含义

根据以上源码可以作出以下工程判断：

- 新增实体管理器不会自动取得原实体的行为所有权；旧状态机、子组件、信号、Timer 和全局扫描仍可能运行。
- 复用实体资产、复用生成/回池协议、继续使用原版行为，是不同程度的复用，需分别选择。
- 节点在树中、属于某组、被池记录、处于活跃状态和仍可接受交互，是不同条件；模组不宜用其中一个条件代替全部条件。
- 若独立模式保留原版组名，应检查 `Targeting`、`MapBounds` 等跨场景消费者，而不只检查角色根脚本。

用户补充（2026-10-24，来源：user）：为适配 DOOM 地图与 DOOM 的逻辑，阶段 5 与阶段 7 的敌怪必然大幅重做，或者直接设计新的敌怪。因此，无需以接管原版敌怪既有运行行为为新实体管理器的目标；新系统应服务于重做或新设计的敌怪。

上述“不会自动取得行为所有权”的结论用于识别实际复用部分的依赖与隔离边界，不能将其扩大成新系统必须迁移原版全体敌怪的要求。复用素材或独立配置仍可按需求评估；敌怪必需的重做成本与实体管理器的增量建设成本应分别评估。

SUPERSEDED: 2026-10-24 本节原先仅从旧实体接管成本说明架构边界，现补充用户确认的敌怪重做前提。原版机制分析保留，后续默认评估对象为 ETNDOOM 重做或新设计的敌怪，而非原版敌怪行为的整体接管。（来源：user）

以上前提不裁定全面实体管理架构。阶段 0 复用 Momoi 玩家实体验证移动的范围与既有阶段闸门保持原状态；架构建议见 [实体管理与 DOOM 兼容建议](E:/ETN_DOOM/ETNDOOM/ModdingDocs/ENTITY_MANAGEMENT_RECOMMENDATION.md:1)。

2026-10-24 D06 已决策：用户确认继续实例化原 Momoi 场景，在入树前处理旧信号、玩法子树和组，再由模组自有最小根逻辑驱动物理体；阶段 0 先落实单玩家控制入口，后续围绕重做或新设计的实体逐步建设管理职责。具体约束见上述建议文档 §6.1 与 [Momoi 分析 §8.3](STAGE_0_MOMOI_ANALYSIS.md#83-momoi-adaptation--沿用原场景的接管方案)。此次确认不改变原版源码结论，全面实体管理架构仍待裁定，功能尚未实现。（来源：user）

SUPERSEDED: 2026-10-24 本节原“D06 为工程推荐，采用待用户确认”已由用户确认替代；原版机制分析与未决架构边界保留。（来源：user）
