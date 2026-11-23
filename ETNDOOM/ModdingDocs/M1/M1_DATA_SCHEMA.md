# M1 Data Schema / M1 实际观察与资源格式

> Date / 日期：2026-11-19。
> Status / 状态：ABI 2 实现格式；运行验证以 M1 验收记录为准，本文不替代测试结果。
> Source / 来源：code（`etndoom_mod/native/m0_observer.c`、`m1_observer.h`、`m1_observer_patches.py`）。

## Identity / 身份

- `m0_snapshot()`、`m0_map()` 与 `m1_resources()` 返回 `schema=2` 的 JSON，缓冲在下次同类调用时覆盖，桥接必须复制。
- `world_epoch`、实体 `id`、事件 `sequence` 与 `voice_generation` 使用十进制字符串，避免 JSON 浮点精度损失。world epoch 来自实际 `P_SetupLevel` 完成钩子；读档外层 begin/commit 抑制中间初始地图的发布。
- 实体ID在`P_SpawnMobjSafe`和`P_UnArchiveThinkers`明确创建/恢复mobj的路径中、加入thinker链后分配；不是通用`P_AddThinker`钩子，避免special thinker误认。`P_RemoveThinker`标记删除前撤销；地址复用会取得新 ID。世界重建清空 ID 表并开始新代次，因此身份必须以 `(session_epoch, world_epoch, id)` 组合消费。`0` 表示无有效引用。
- ID 表容量 131072；事件队列 8192。达到容量会产生显式观察失败，核心停止推进，不发布截断后的成功数组。快照、地图、资源 JSON 缓冲分别为 16、32、16 MiB；超限返回 `*_CAPACITY` 错误。

上文原生 API 的 `world_epoch` 是核心装图代次。Godot `session.snapshot()` 与 `session.map_data()` 统一返回宿主的 `session_epoch/world_epoch`，另以 `core_world_epoch` 保留原生代次；同进程关闭再建会话时核心代次可从1开始，宿主代次继续递增，不能混用两个编号域。`map_data()` 只给复制结果附当前身份，不执行世界检查、不推进 tic、快照序号或事件；非关卡的 `world_valid=false` 地图结果同样携带当前身份。

## Snapshot / 动态快照

流程头包含 tic、leveltime、gamestate/gameaction、游戏/关卡身份、上游暂停、RNG 三索引及 `world_valid`。非 LEVEL 状态保留玩家 HUD 与流程数据，但不访问旧实体和地图数组。`flow` 返回真实 `wminfo`、结算阶段和 Finale 阶段/计时；前后地图索引沿用上游从零开始的语义。

玩家包含原始健康/护甲、武器拥有和 ready/pending、弹药上限/现值、钥匙、powerup 计时、伤害/拾取闪烁、统计、按键锁存、refire、跳跃冷却、psprites 与视点动态量。实体包含原始定点位置/动量/尺寸/上下界、角度、type/state/tics/sprite/frame/flags、真实 thinker 次序、AI 计数和 target/tracer 引用。`interpolate=false` 用于中断显示插值，传送另有事件。

动态数组字段按以下固定顺序读取：

| 字段 | 每项顺序 |
|---|---|
| `sectors` | floorheight, ceilingheight, lightlevel, floorpic, ceilingpic, special, tag, sky, oldspecial |
| `sides` | textureoffset, rowoffset, toptexture, bottomtexture, midtexture |
| `lines` | flags, special, tag |
| `buttons` | line index, where, restored texture, remaining tics |
| `psprites` | state index（-1 无）, tics, sx, sy |

`sector_sound_targets` 与 sectors 同序。`specials` 保留非 mobj thinker 的原始顺序和类型；door/floor/ceiling/plat、各类灯光计数、暂停中的 plat/ceiling 单独输出。`texture_translation`、`flat_translation` 是内核当下动画映射，不能从初始目录推定运行时材质不变。

## Map / 静态拓扑

顶点和所有位置/高度使用 16.16 定点整数。二维内核 `(x,y)` 不预先翻转；转换为 Godot 时使用 `(x,z,-y)`。

| 字段 | 每项顺序 |
|---|---|
| `vertices` | x, y |
| `lines` | vertex1, vertex2, flags, special, tag, front side, back side（65535 无） |
| `sides` | sector, textureoffset, rowoffset, toptexture, bottomtexture, midtexture |
| `sectors` | floorheight, ceilingheight, floorpic, ceilingpic, lightlevel, special, tag, sky |
| `segs` | vertex1, vertex2, linedef, sidedef, front sector, back sector, offset, angle |
| `subsectors` | sector, first seg, seg count |
| `nodes` | x, y, dx, dy, child0, child1, 两个孩子各四项 bbox |

BSP child 的 `0x80000000` 表示 subsector，其余位为索引；seg 是原生 BSP 切分后的实际墙片段，关联 linedef 保留真实墙边身份。不得把 BSP 分区线自动当实体墙。天空由 `sky_flat`、`sky_texture` 与 sector sky 标记说明。

## Resources / 完整可解码资源

`m1_resources()` 导出当前资源会话最终解析的视图：

- `lumps`：原生索引、8 字节名称、精确长度、IWAD 来源标记；`palette_lump` 和 `colormap_lump` 指向最终 PLAYPAL/COLORMAP。
- `textures`：内核已解析的名称、逻辑宽高、当前动画映射与按覆盖顺序排列的 patch `[origin_x, origin_y, lump_index]`，格式 `doom-patch-composition`。该组合和所有 patch 原始字节足够解码透明纹理，不要求消费者重做 WAD 优先级搜索。
- `flats`：保留原生索引、最终 lump、length、decodable 与当前映射。至少4096字节的真实 flat 为64×64 `palette-index8-row-major`；namespace marker 为0×0、decodable=false、`namespace-marker`，不会把零字节标记伪装成贴图。实际sector及动画映射使用的flat需由消费者核验decodable。
- `sprites`：原生 sprite/frame/rotation 对应实际 lump、flip、宽高与 left/top offset；格式 `doom-patch-columns`，包含 Crispy 的 16 朝向映射。
- `states`：sprite, frame, tics, nextstate, misc1, misc2，直接来自应用内嵌 DEHACKED 后的状态表。

`m1_resource_read(kind,index,offset,out,capacity)` 当前只接受 `kind=0` 的原生 lump。index 必须来自本会话目录；offset 不能超过目录 length；单次 capacity 为 0..1048576。成功返回实际复制字节数；-1 表示参数/会话拒绝，-2 表示实际文件范围或读取失败。读取不加载任意路径，也不生成新资源身份。资源索引在整个会话内稳定，关闭会话后全部失效。

## Events / 事件

`m1_events()` 重复读取返回同一未确认批次；`m1_ack_events(sequence)` 仅允许 `[acknowledged,last_sequence]`，确认后释放队列前缀。事件包括 world_rebuilt、entity_spawn/remove/teleport 和实际音频 start/stop/music/pause/resume；每项保留生成顺序、world epoch、tic。

世界重建先撤销旧队列，再发布新 `world_rebuilt`；建立世界时的批量 spawn/音频由完整快照与音频状态恢复，不逐个堆入队列。运行期间即使实体在一 tic 内创建后删除，两条事件仍会保留。音频事件的 `voice_generation` 区分通道复用；`resource` 与 `parameters` 由音频后端说明。观察不调用 RNG、不重排 thinker、不替内核模拟。

事件使用同一存储结构，消费者必须先按 `type` 解释字段：

| type | 字段含义 |
|---|---|
| `entity_spawn/entity_remove/entity_teleport` | `entity_type` 是 mobj 类型，`position` 是事件发生时的原生16.16坐标；`resource/parameters` 是共用存储的别名，不作为资源/音频参数消费 |
| `sound_start` | `channel/voice_generation` 标识声音实例；`resource` 是声音 lump，`parameters=[volume,separation,pitch]`；`entity_type/position` 是这两项的别名，不是实体类型或空间位置 |
| `sound_stop` | 保留被停止实例的 channel、generation、resource及来源ID；parameters为0 |
| `music` | resource为音乐lump，`parameters[0]` 为looping，channel为-1 |
| `audio_pause/audio_resume` | channel和resource为-1，不对应实体或空间位置 |
| `world_rebuilt` | 只用sequence、world_epoch、tic及事件类型，其他共用字段不表示新实体 |

音频 `entity_id` 是触发/更新时能识别的 mobj 来源，非mobj来源为0。历史生成/删除事件和声音停止事件可能引用当前快照中已经不存在的实体ID；应按同世界的生命周期历史消费，不能要求所有事件ID均出现在最新 `entities`。原生 `tic` 记录事件生成时的 `gametic`：`RunTic` 内的实体/声音事件通常比本次step完成后的快照tic小1，`gametic++` 后的音频更新事件则使用更新后的值。批次先后顺序以 `sequence` 为准，不用这些观察记录驱动模拟时钟。

## Special Field Validity / 机关条件字段有效性

`specials[].valid_mask` 的 bit i 对应 `values[i]`。未置位的值统一输出0，表示当前类型/状态不使用该槽位；实现不读取相应未初始化C字段。规则状态不能仅凭数组中的0推断，须同时检查mask。

| kind | values顺序 | 条件有效字段 |
|---|---|---|
| door | sector, type, topheight, speed, direction, topwait, topcountdown | topheight/topwait仅direction=1或2；topcountdown仅direction=0或2 |
| floor | sector, type, crush, direction, newspecial, texture, destination, speed | newspecial/texture仅lowerAndChange或donutRaise |
| ceiling / ceiling_stasis | sector, type, bottomheight, topheight, speed, crush, direction, tag, olddirection | raiseToHighest无bottomheight；lowerToFloor/lowerAndCrush无topheight；olddirection仅direction=0 |
| plat / plat_stasis | sector, speed, low, high, wait, count, status, oldstatus, crush, tag, type | raiseAndChange/raiseToNearestAndChange不初始化low；count仅waiting或暂停前为waiting；oldstatus仅in_stasis |

来源：code（固定Crispy `p_plats.c:EV_DoPlat/T_PlatRaise`、`p_doors.c:T_VerticalDoor`、`p_floor.c:T_MoveFloor`、`p_ceilng.c:EV_DoCeiling`）及test（运动机关跨会话续跑暴露plat非waiting时的未初始化count）。此规范仅修观察器，不初始化或改写原生机关字段。
