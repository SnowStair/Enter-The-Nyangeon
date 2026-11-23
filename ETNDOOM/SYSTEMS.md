# Systems / ETNDOOM 系统增量

> Scope / 范围：只记录 ETNDOOM 新增系统；本体系统继续查阅 [`docs/SYSTEMS.md`](../docs/SYSTEMS.md)。
> Entry format / 条目格式：日期、Source / 来源、职责/参数、代码证据、验证边界。

## M1 Runtime / M1 完整单人服务（2026-11-19）

Source / 来源：code。实际数值/数组和生命周期见 [M1_DATA_SCHEMA.md](ModdingDocs/M1/M1_DATA_SCHEMA.md)，保存审计见 [M1_FLOW_AND_SAVE.md §8](ModdingDocs/M1/M1_FLOW_AND_SAVE.md)。验证状态以 [M1_VALIDATION.md](ModdingDocs/M1/M1_VALIDATION.md) 为准。

- `m1_create` 显式区分 Doom episode/map 与 Doom II MAP；受限 profile 为 fixture/doom2/doom/dss，禁止 autoload/sideload/外部补丁。DSS 的内嵌 DEHACKED 由 Crispy 默认链应用，销毁 DLL 后重入纯 Doom 重建原始状态表。
- 玩法继续唯一由 `RunTic/G_Ticker` 执行；Godot 不求解移动、命中或机关。完整快照包含实体/引用、HUD、动态 sector/side、非 mobj thinkers、按钮计时、材质动画及结算/结束状态。世界无效时保留合法流程头，拒绝旧地图访问。
- 宿主暂停原因独立叠加 manual/focus/dialog/overload。聚焦仅撤回 focus；暂停中允许保存/读取/返回。积压超限保留欠账，只由世界重建解决；普通保存不会顺便清掉欠账。
- 原生事件容量 8192，宿主分发队列容量 256；原生短命实体/传送/声音事件稳定重读，消费后 ack，满容量停止推进或报告失败。世界重建明确撤回旧批次与引用。
- `m1_resources/m1_resource_read` 输出最终解析的纹理 patch 组合、flat、sprite 朝向/flip/偏移、状态表与有界 lump 字节，供 M2 解码；不开放任意路径资源浏览。
- UI 提供新游戏参数、F5 当前图重开、Enter 原生重生/流程确认、F6/F7 存读槽位、F10/F9 返回/重入。最终俯视表现仍归 M2。

## M0 Runtime / M0 固定步进与运行状态（2026-11-17）

Source / 来源：code。实际验证结果见 [M0 探针记录](ModdingDocs/M0/M0_PROBES_AND_ACCEPTANCE.md)；完整模块和 M1 出口见 [固定源码审计](ModdingDocs/M0/M0_SOURCE_AUDIT.md)。

- 唯一玩法真值是 Crispy `RunTic→G_Ticker`，保留其新游戏、关卡、结算/结束调度。`m0_step` 每次只消费一个明确的 `ticcmd_t` 并推进一个 tic，Godot 不直接修改位置、动量、血量或随机索引。16.16 定点与 32 位角度原始值用于差分，显示换算单向进行。
- 实时取 `Time.get_ticks_usec()`，35 tic/s、每帧最多补 8 tic；70 tic 欠账显示警告；超过 350 tic 停止推进并保留欠账，必须重开或返回，不通过清空欠账继续伪装正常。暂停和失焦停止产生新欠账、清理按键/一次性武器请求，恢复不追赶暂停 wall time。`screen.gd:advance_seconds` 供确定的帧序列回归。
- 会话只允许一个活动内核；重复建会话被拒绝。每次新会话 `session_epoch/world_epoch` 递增；地图标识改变或 `leveltime` 回落使世界代次递增，清除旧世界待执行命令并停止当前批次。M1 增加正式重开/读档入口时仍须由真实世界重建事件明确更新代次，不能依赖地图名相同与否。
- 命令含 `session_epoch/world_epoch/target_tic/sequence` 和 forward/side/turn/buttons/arti；严格递增且 tic 连续，超界、重复、迟到、跨代次和容量不足整批拒绝。容量 1024；没有明确命令就拒绝 step。暂停不消费命令；切换暂停清空待处理命令，恢复不重放。
- 生命周期事件容量 256，包括会话开始、世界变化、暂停/恢复；读取返回复制数据，确认后回收。消费者按 `event_seq` 去重，队列满则拒绝继续推进/状态变更，不能覆盖未确认事件。完整音效/粒子等事件属于 M1/M2，不由这几个生命周期事件代表完成。
- M0 输出玩家原始坐标/动量/角度、血量/护甲/武器/状态、实际 gamestate/gameaction、三组 RNG、实体数量、sector 动态值；静态图输出 vertices/lines/sides/sectors。完整实体数组/稳定实体 ID、资源读取、存档和完整流程 API 仍归 M1，当前不返回伪造占位值。

代码证据：`etndoom_mod/native/m0_core.c:m0_step`、`m0_observer.c:m0_snapshot/m0_map`；`etndoom_mod/m0/session.gd:submit_commands/step/set_paused/read_events`；`etndoom_mod/m0/screen.gd:advance_seconds`。对照程序的显示 RNG 处理与存档 RNG 缺口见源码审计 §1.1、§3，不能把两者混成玩法 RNG 可以随意重置。
