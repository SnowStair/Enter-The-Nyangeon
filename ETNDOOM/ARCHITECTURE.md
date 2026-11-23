# Architecture / ETNDOOM 架构增量

> Scope / 范围：只记录 ETNDOOM 新增结构。本体单例、加载器和场景流程继续查阅 [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)。
> Entry format / 条目格式：日期、Source / 来源、职责与所有权、代码证据、验证边界。

## M1 Runtime / M1 运行时（2026-11-19）

Source / 来源：code；自动结果和人工状态分别见 [M1 验收](ModdingDocs/M1/M1_VALIDATION.md)。SUPERSEDED: 下方 M0 的“音频关闭、按地图名推测世界变化、无存档”描述仅适用于历史 M0。

独立 ID `etndoom_m1` 由 `entry/m1_entry.gd` 安装清单驱动，`gdextension/bridge_m1.c` 注册 `CrispyDoomBridgeM1`，建会话前要求全部 ABI 2 导出。原生 DLL 每会话加载/卸载的所有权不变；SDL2_mixer 2.8.1 加入锁定依赖，注册桥接库仍驻留。`m1/session.gd` 管身份、命令/流程、暂停原因和事件分发；`m1/screen.gd` 提供原版软件画面与实际流程控件。返回 ETN 后保留 F9/按钮再次进入入口，不重建本体角色/回合。

入口在复制或加载任何原生 DLL 前，逐项比较 PCK 内嵌 `build_identity.json` 与物理 `native/manifest.json` 的 schema、桥接/核心 ABI、build_id 和全部文件哈希。两者缺失或不一致以 `build_identity` 阶段拒绝，防止合法的旧 PCK 与另一合法构建的原生目录混用；随后继续验证物理文件、缓存哈希与已驻留桥接的构建身份。

流程控制在主线程安全边界同步执行，不依赖额外 gameplay tic；结算确认排入下一原生 tic 并从 `snapshot.control` 回报完成。世界代次来自实际装图/读档完成钩子；变更时清旧命令、撤回旧事件，通知消费者全量重建。宿主身份和原生 world epoch 分别保留，不把存档恢复的原生时钟当宿主输出序号。

`native/m1_save.c` 封套包含原生存档与补充状态，使用资源内容/有序角色、内核 DLL 内容、规则和 schema 校验。预检拒绝保留当前世界；原生恢复失败进入 FAILED。槽位位于 `user://etndoom_m1/saves/<profile>_<rules>/`，与 ETN 本体存档隔离。

声音由原生 SDL_mixer/OPL 输出；Godot 消费播放诊断而不重复播放声音事件。音频回调只访问自有 PCM 观察缓冲；退出先暂停设备并撤回回调，再释放内核并卸载。绘图固定到 35 Hz 内核边界，宿主 `framebuffer` 仅读缓存，避免探索标志和结束音效随读取频率漂移。

## M0 Crispy Host / M0 Crispy 宿主接入（2026-11-17）

Source / 来源：code；运行证据集中在 [M0 探针记录](ModdingDocs/M0/M0_PROBES_AND_ACCEPTANCE.md)，不能由本节结构说明推定全部 Gate 通过。

`ModManager` 按已有 ZIP/PCK 机制载入新 ID `etndoom_m0`。纯 GDScript entry 从 `list_mods()` 取得实际物理安装根，验证 `native/manifest.json` 中每个 DLL 的 SHA-256，复制到本模组的内容哈希缓存，再调用 `GDExtensionManager.load_extension`。只有扩展类注册成功后才加载 `session.gd`，避免脚本解析依赖尚未注册的原生类。证据：`etndoom_mod/entry/m0_entry.gd:_bootstrap`、`etndoom_mod/build_m0.py:build`。

| 层 | 文件 | 所有权 |
|---|---|---|
| 安装/引导 | `etndoom_mod/entry/m0_entry.gd` | 参数、宿主身份、安装根、DLL 清单与缓存、扩展注册时序、进入/返回 ETN |
| 会话/输入 | `etndoom_mod/m0/session.gd` | 会话/世界代次、命令序列与 1024 条队列、256 条生命周期事件、暂停与错误状态；不自行模拟移动 |
| 画面/时钟 | `etndoom_mod/m0/screen.gd` | monotonic wall time→35 tic/s、每显示帧最多 8 tic、输入采样、320×200 framebuffer 上传、人工暂停/重开/返回 |
| Godot 原生边界 | `etndoom_mod/gdextension/bridge.c` | Godot C GDExtension ABI、主线程检查、DLL 符号/ABI 校验、参数与返回复制；不使用 `godot-cpp` |
| Crispy 内核 | `etndoom_mod/native/m0_core.c`、`m0_observer.c`、锁定源码 | 完整 `RunTic→G_Ticker`、定点/RNG/地图/玩家/thinker/流程真值；read-only 状态输出与软件 framebuffer |
| 生命周期内存 | `etndoom_mod/native/m0_memory.c` | 内核 C 堆和 FILE 登记，关闭/释放；宿主随后 `FreeLibrary`，下一会话重新加载获得全新静态状态 |

扩展注册库驻留，内核 DLL 每会话加载/销毁；两者不能混称“热卸载 GDExtension”。销毁执行内核允许的退出 handler、SDL 清理和登记分配释放，再卸载内核 DLL。外部 C 字符串/缓冲只在下一次相应调用前有效，桥接在返回 Godot 前复制；不把内核指针暴露为可保存身份。模拟、观察、framebuffer 与销毁均在宿主主线程串行调用。

进入 M0 时将当前 ETN 场景实例从树中暂时摘下保存，不发原玩法玩家生成/回合信号；创建自己的 Control 显示 DOOM。只保存并修改鼠标模式、现有 SoundManager 音频播放器的 `stream_paused`，返回时按记录归还，再把原场景实例挂回。不会创建 ETN 战斗玩家/敌人、使用其伤害系统作为 DOOM 镜像。证据：entry `start_session/return_to_etn`。`SceneTree.paused`、`Engine.time_scale` 不参与 DOOM 时钟，M0 screen 的处理模式为 ALWAYS。

原生缓存为 `user://etndoom_m0/native/<manifest_sha256>/`，使已加载 DLL 不占用安装器准备交换的 Mod 安装目录。缓存每次使用先验证哈希；缺失/损坏拒绝进入 DOOM，保留菜单及可定位诊断。当前构建成功加载后尝试清理同根下非当前的 64 位十六进制构建目录；链接或其它目录不处理，占用失败保留并报告，下次启动重试。卸载后 entry 不再运行，残留缓存须在宿主完全退出后按显式清理入口处理；不能声称本体安装器会自动删此目录。P5 验证更新、禁用、卸载和失败事务，完整多版本矩阵仍属 M4。

M0 音频输出关闭，原生跳跃是 Crispy 命令/配置；完整音频、存读档、战斗/机关/跨图继承验证归 M1。最终俯视为 M2，既有 Stage0 独立保留，不能把 framebuffer 临时显示记作最终俯视。
