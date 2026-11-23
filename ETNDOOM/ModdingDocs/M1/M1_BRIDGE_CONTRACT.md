# M1 Bridge Contract / M1 桥接接口细化

> Date / 日期：2026-11-19。
> Status / 状态：M1 ABI 2 已实现；实际入口与容量见 §8，数据字段见 [M1_DATA_SCHEMA.md](M1_DATA_SCHEMA.md)。下方 §1–7 保留设计语义，具体符号以 §8 和源码为准。SUPERSEDED: 2026-11-18“尚无 M1 ABI”的实施前状态。
> Source / 来源：code（`m0_core.h`、`m0_core.c`、`m0_observer.c`、`session.gd`、`screen.gd`）；下方保留设计语义，实际ABI及测试边界见§8。
> Navigation / 导航：[M1 总览](README.md)、[流程/存档](M1_FLOW_AND_SAVE.md)、[平台/音频](M1_PLATFORM_AND_AUDIO.md)。

## 1. Principles / 延续的边界

单活动会话、主线程串行模拟、35 tic/s、16.16 定点与 uint32 角度、内核唯一玩法真值保持。GDExtension 注册库驻留，Crispy 内核继续每会话加载/卸载；M1 不为复用全局变量而承诺同一 DLL 内多次完整初始化。

现有输入队列 1024、生命周期事件容量 256、每帧最多 8 tic、70 tic 欠账警告、350 tic 超限停止为起始参数。音频/实体事件加入后应测量事件字节数和峰值，再冻结新容量；原有 256 条容量不是自动适用于完整声音系统的结论。

ABI 增量必须同时落实到 C 头、桥接符号装载、Godot 调用与构建锁。若字段/符号不兼容，提升 ABI 并在创建前拒绝旧 DLL；不直接复用 `abi=1` 而改变旧语义。无需为未来所有端口建立公共能力系统。

## 2. Operations / 操作面与执行边界

下表表达语义操作；已实现 C/Godot 符号对照见 §8。

| 操作 | 接受条件 | 执行与结果 |
|---|---|---|
| `build_info` | 库已载入 | ABI、内核/补丁/依赖身份、实际音频模式、数据 schema |
| `create_session(config)` | 无活动会话 | 明确资源 profile、难度、起始地图与规则配置；第一份合法流程/世界状态或创建错误 |
| `submit_commands` / `step` | 活动、可步进、未因宿主暂停停止 | 沿用逐 tic 输入；返回实际执行数、最后消费命令和流程/世界变化 |
| `request_flow_action(action, request_id)` | 当前状态允许该操作 | 明确 accepted 与 completed；同一请求不能重复执行；恢复/返回等控制不等待 gameplay tic |
| `set_paused(reason, active)` | 活动会话 | 更新暂停原因；清实时按键与一次性请求；重置 wall-time 采样 |
| `read_snapshot` / `read_map` | 快照按实际状态；地图必须有效 | 返回复制数据；无世界时明确 `world_valid=false`，不假造空玩家 |
| `read_resource(handle, offset, limit)` | 资源身份和类型合法 | 有界数据与总长度、格式、逻辑元数据；不接受任意文件路径 |
| `read_events` / `acknowledge_events` | 序号合法 | 重读稳定、按实际消费确认；容量不足明确暂停/失败，禁止覆盖 |
| `save_game(slot)` / `load_game(slot)` | 见流程/存档合法性表 | 事务结果包含请求 ID、完成边界与诊断；不能在 accepted 时显示成功 |
| `close` | 任意会话状态，包括 FAILED | 幂等；停止生产输入/媒体，撤回回调，释放后卸载内核 |

正式入口仅接受声明的动作与字段；不以通用控制台/任意 argv 暴露网络、补丁、跨图作弊或未许可资源。普通出口必须由上游触发，调试跳图不能替代出口验收。

2026-11-19 用户已明确增加纯 Doom 与 Doom+DSS 两个回归组合，见 [获准清单](M1_VALIDATION.md#21-approved-additions--m1-新增获准资源2026-11-19)。受限 profile 应表达 Doom episode/map 和 DSS 的内嵌 DEHACKED 策略；上文“不暴露任意补丁”不禁止该已获准 PWAD 的默认内嵌补丁。外部 `DSS.deh` 仅参考，不作为正常接口输入。

## 3. Identity and Time / 身份与时序

| 字段 | M1 语义 |
|---|---|
| `session_epoch` | 每次成功建会话递增，进程内不复用；不是永久存档 ID |
| `world_epoch` | 实际装图、同图重开、死亡导致地图重建、读档成功时建立新代次；从内核钩子上报 |
| `target_tic` / `command_seq` | 桥接调度/接收序号；沿用 M0 的 `sequence` 字段时明确映射。成功读档后不把旧待执行输入带入新世界 |
| `core_gametic` / `leveltime` | 内核原始时钟；读档可回退/恢复，不承担宿主唯一序号职责 |
| `snapshot_seq` / `event_seq` | 会话内单调输出序号；读取快照不推进 core tic |
| `entity_id` | mobj 生存期稳定、世界内不复用；建议正 int64 创建序号，0 表示无引用 |
| `sector_id/line_id/side_id` | 绑定当前 world_epoch 的装图索引 |
| `resource_handle` | 会话资源集绑定；资源集销毁时失效。地图衍生资源另带 world_epoch |
| `channel_id` / `voice_generation` | 声音实例身份；复用同一通道不能把旧停止事件应用到新声音 |

`world_epoch` 只在真实重建提交后发布；地图进入结算不必立即销毁资源，但须以 `world_valid` 和合法操作声明哪些数据可读。传送只改变对应实体的连续性标记，不给整个地图重建代次。

一批命令发生 world change 时立即停止当批，返回实际执行数量和原因，丢弃旧世界未执行输入并要求消费者提交新代次命令。不能拿旧输入继续新地图，也不能隐式把最后命令复制进去。

持续身份不经过 Godot JSON 的浮点数路径。C→Godot 可用真实 int64 Variant/整数数组；保留 JSON 通道时将 64 位身份编码为十进制字符串并严格解析。结构大小、字节序、长度上限及溢出行为随 ABI 一起冻结；禁止把地址、字典遍历位置当稳定 ID。

## 4. Snapshot / 完整快照与字段来源

快照分三部分：始终存在的会话/流程头；仅在有效世界中存在的地图/实体；可选诊断。M0历史实现在玩家为空时直接报`NO_WORLD`；M1现按gamestate返回流程头/HUD，非LEVEL的实体与地图数组为空、引用为0，地图读取明确world_valid=false，结算与Finale已实际验证。

| 数据块 | 必需字段/含义 | 真实来源与约束 |
|---|---|---|
| 头/流程 | 身份、tic、gamestate/gameaction、模式、episode/map/skill、暂停原因、world_valid、合法动作、待完成请求 | `doomstat` / `g_game` / 桥接控制状态；宿主暂停和上游 paused 分别记录 |
| 玩家/HUD | playerstate、实体 ID、health/armor、武器拥有/ready/pending、弹药及上限、钥匙、powerup/计时、伤害/拾取反馈、击杀/物品/秘密统计 | `player_t`；不能从武器动画或画面反推 |
| 实体 | ID、type、state、tics、位置/动量/angle、radius/height、sprite/frame、显示 flags、health、sector、target/tracer 等诊断关系 | mobj 与状态表；原始数值用于比较，脚底 z 明确 |
| sector | floor/ceiling 高度、材质、light、special/tag、有效的动画/天空解释 | 内核数据；不自行求解机关 |
| side/line | 动态 texture offset、上下/中纹理与开关变化；运行期会变的 line 标志/动作状态 | `sides/lines`；初态拓扑不代表以后纹理永远不变 |
| 结算/结束 | 前/后地图、秘密出口、统计、阶段、允许确认/返回 | `wminfo`、WI/Finale 实际状态；必要时增只读 getter |
| 诊断 | 三组 RNG、thinker/specials 序列、消费序号、请求结果、容量/内存计数 | 观察不调用 RNG、不改变 thinker 链；非 mobj thinkers 不能漏出验证范围 |

实体表首先采用每 tic 全量快照，生命周期事件用于补足一 tic 内生成又删除的短命对象和一次性效果；不要先做复杂增量同步。批量序列化可另排观察顺序，但不可重排内核链表。完整快照容量不足返回错误或显式分页，不返回截断后看似合法的数组。

坐标继续为内核 `(x,y,z)` → 逻辑 `(x,-y,z)` → Godot `(x,z,-y)`；角度 0 为 +X，`0x40000000` 为 +Y。负坐标、脚底高度、方向跨零的真实样例在实现后填写，不能把预测样例写成实测输出。

## 5. Map and Resources / M2 消费准备

| 接口内容 | M1 交付要求 |
|---|---|
| 地图拓扑 | 保留 vertices/lines/sides/sectors；补可供绘制/查询的 seg/subsector/BSP 关联或经验证等价的输出，注明真实墙边与 BSP 切分边 |
| 纹理/flat | 从内核最终资源视图取得解码数据或完整可解码数据；尺寸、格式、透明/调色板、动画映射与当前索引明确 |
| sprite | 状态→sprite/frame/rotation/flip→实际 lump 的映射、偏移和尺寸；不由 Godot重新搜索 WAD 并猜覆盖关系 |
| 天空/特殊表现 | 导出内核真实标记和必要映射；具体俯视可读性处理留 M2 |
| 声音/音乐 | 若宿主消费事件，提供类型、资源/实例身份与数据；若原生后端播放，提供播放控制/状态和可验证诊断 |

材质索引本身不足以交接 M2，必须能解析为实际资源。按贴图高度升地板等依赖使用原生逻辑尺寸；角色美术尺寸在表现层独立处理。读取接口只服务已创建的获准资源集，不对外开放 D08 的通用装载能力。

## 6. Events / 事件与容量

事件头建议固定为 `session_epoch/world_epoch/tic/event_seq/type/payload`，至少覆盖：会话开始/结束、世界重建、流程切换、请求完成/失败、暂停原因变化，以及选用方案所需的声音开始/停止/更新/音乐切换。实体短命效果、传送等无法可靠由两份快照重建的变化需要事件或等效记录。

采用单一分发器将事件交给各消费者；所有必需消费者实际处理后才 ack。当前 `screen.gd:138` 的整批无条件确认不能直接沿用到新增声音消费。重复读不重复播；同一 tic 的多个事件保持生成顺序，ack 不代表“用户听完了声音”。

容量在推进前检查，但一 tic 产生的事件数量也可能超过剩余空间：实现须有有界单 tic 暂存并在完整批次可交付时发布；若连单 tic 暂存也溢出，标记会话 FAILED、保留诊断并停止，不返回成功或丢事件继续。临时耗尽可先阻止下一 tic，允许消费现有事件后恢复。退出/清理通路不能依赖已满的事件队列。

读档/重建时关闭旧声音、撤回旧事件与资源引用；新的重建边界应带最后旧序号或清晰的切换标记，消费者据此全量重建。显示插值不能跨 world_epoch，传送不能做穿墙补间。

## 7. Ownership and Errors / 所有权与错误

跨 ABI 的字符串/缓冲均在返回 Godot 前复制；持续读取使用具备身份与长度的句柄，不保留内核裸指针。所有修改游戏状态的调用主线程串行，音频设备回调只能消费自有缓冲，禁止重入 step/存读档/销毁或直接访问 Godot 对象。

错误至少包含 `code / stage / operation / request_id / session_epoch / world_epoch / recoverability / message`；文件/lump/偏移仅在确实可定位时附加。参数/身份拒绝不改当前世界；读档预检拒绝保留旧世界；进入原生装图后失败且不能回滚则进入 FAILED，只可诊断/关闭/返回。

快照读取失败与正常“无活动关卡”分开。任意访问违规、设备回调执行到已卸载 DLL、宿主进程退出都算失败，不能包装成普通可恢复错误。实际错误码清单、ABI 结构与真实样例随 M1.5 实现补齐。

## 8. Implemented ABI / 实际接口冻结（2026-11-19）

Source / 来源：code | test。M1 使用独立 Mod ID `etndoom_m1`、驻留类 `CrispyDoomBridgeM1` 和 ABI **2**；data schema **2**、save schema **1**。M0 历史宿主仍为 ABI 1，当前默认原生 DLL 不能混用。依据 `native/m0_core.h`、`native/m1_observer.h`、`native/m1_audio.h`、`gdextension/bridge_m1.c`、`m1/session.gd`（均相对 `etndoom_mod/`）。

| 语义 | 原生 / GDExtension / 宿主入口 |
|---|---|
| 建立 | `m1_create(iwad,pwad,savedir,skill,episode,map,jump)` / `open_core` / `create_session(profile,jump,skill,episode,map)`；C层episode=0表示Doom II，1–4表示Doom |
| 输入 | `m0_step` / `step_core` / `submit_commands`、`step`、`command`；单人slot0，显式连续target_tic与递增sequence |
| 流程 | `m1_control(action,a,b,c,request_id)` / `control_json` / `request_flow_action`；action为`new_game/restart_level/reborn/pause/save/load/confirm` |
| 状态 | `m0_snapshot/m0_map/m0_build_info` / 对应`*_json` / `snapshot/map_data/build_info` |
| 原版画面 | `m0_frame/m0_width/m0_height` / `framebuffer/dimensions_json` / `framebuffer/dimensions`；RGBA8，读取只复制缓存 |
| 资源 | `m1_resources/m1_resource_read` / `resources_json/resource_read` / `resources/resource_handle/read_resource`；kind0读取最终lump，不重新解析外部WAD |
| 事件 | `m1_events/m1_ack_events` / `events_json/ack_events_json` / `read_events/acknowledge_events`；原生成功后才提交宿主ack |
| 音频 | `m1_audio_status/m1_audio_set_volume` / `audio_status_json/audio_volume_json` / `audio_status/set_audio_volume`；原生SDL_mixer/OPL播放，0–127输出音量 |
| 清理 | `m0_destroy` / `close_core` / `close`；先撤回音频回调再卸载，报告分配数及DLL卸载结果 |

流程控制不等待游戏tic；保存/读取/暂停不推进`gametic`。`confirm`返回`completed=false`后，下一真实tic消费，宿主由快照的`control`生成完成事件。暂停/读取/重建可显式取消待确认请求，不把accepted当成完成。保存槽位C层0–7，UI显示1–8。难度1–5；原规则与原生jump分开配置。

| 容量 | 冻结值与失败行为 |
|---|---|
| 宿主命令 / 事件 | 1024 / 256；命令整批验证，事件接近满时停止接收推进操作，ack后可继续 |
| 原生事件 / 实体身份表 | 8192 / 131072；溢出进入明确失败，不覆盖旧事件；control和step都检查observer失败 |
| JSON缓冲 | snapshot16MiB、map32MiB、resources16MiB、events4MiB；不足返回明确容量错误 |
| 单次资源读取 | 最多1MiB，索引/偏移/长度验证；资源句柄绑定session_epoch |
| 存档容器 | 最多64MiB；严格结构/哈希/核心DLL与有序资源身份预检，原子替换 |
| 显示调度 | 35Hz，每帧最多8tic；70tic警告，超过350tic保留欠账并暂停，需重开/读取/返回 |

64位原生身份经JSON十进制字符串传输；宿主命令参数为Godot真实int64。实体ID只来自mobj创建/撤回钩子，不能把非实体thinker地址当实体。`specials.valid_mask`明确哪些槽位有效，无效值规范为0，不能读取未初始化内存。资源目录中的flat marker明确`decodable=false`；完整patch/texture/flat/sprite解码由独立Python消费者验证。

宿主错误包含`ok/stage/error`；流程响应还附`operation/request_id/session_epoch/recoverability`及原生`code/active/completed/world_epoch`等字段。普通参数拒绝保留世界；核心失效收口并撤回DLL。不是所有错误都有文件/偏移，消费者须按实际存在字段显示，不把诊断缺项理解成成功。

事件分为宿主会话/流程事件与原生实体/传送/音频事件。原生后端直接播放，UI不会重复播放收到的音频事件。声音通道的自然结束由设备墙钟决定，**设备通道状态/PCM波形不作为游戏确定性状态比较**；按钮恢复和结局声音的逻辑触发已移到固定tic路径，避免设备或绘图读取频率消耗不同RNG。补丁原因与实证见 [平台/音频 §7](M1_PLATFORM_AND_AUDIO.md#7-implemented-backend--实际后端与服务边界2026-11-19)。
