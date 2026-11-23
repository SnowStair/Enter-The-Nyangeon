# M1 Platform and Audio / M1 平台服务与音频接入

> Date / 日期：2026-11-19（补实现与自动证据）。
> Status / 状态：音频与平台实现已落地，原生专项自动通过；真实宿主与人工结论见验收文档。SUPERSEDED: 2026-11-18 的“音频后端尚未选定或实现”；下方设计对照表保留为实施依据，实际冻结项见 §7。
> Source / 来源：code（M0 构建/平台包装与固定 Crispy `s_sound/i_sound/d_main`）；实现路线须由窄探针收敛。
> Navigation / 导航：[M1 总览](README.md)、[桥接契约](M1_BRIDGE_CONTRACT.md)、[验收](M1_VALIDATION.md)。

## 1. Baseline / 当前平台事实

| 位置 | 已有行为 | M1 影响 |
|---|---|---|
| `native/m0_core.c:30,55` | 声明 audio=false，启动加 `-nosound` | 移除禁声不是音频接入完成；初始化、更新和关闭必须同时接通 |
| `native/CMakeLists.txt:6,12` | SDL_mixer 禁用，仍链接 SDL/textscreen/pcsound/opl | 音乐/SFX 可用性取决于实际后端与依赖，不能从链接名推断可播放 |
| `build_native.py:31,34` | 禁音乐包搜索与用户默认配置加载 | 接声音后仍禁额外资源自动发现，不引入未经许可音乐包/SoundFont |
| `native/m0_core.c:62` | 只按命令执行 `M_Ticker → RunTic` | 上游独占主循环中的媒体服务需逐项补回 |
| 固定源码 `src/doom/d_main.c:558` | `D_RunFrame` 在 tic 推进后调用 `S_UpdateSounds` | M0 绕开 D_RunFrame，M1 不能遗漏声音位置/通道更新 |
| `build_native.py:73`、`native/m0_memory.c` | 自定义退出 handler、SDL 清理、登记分配释放 | 新设备线程/回调须在 DLL 卸载前彻底停止 |

前五个本仓路径相对于 `etndoom_mod/`；`src/` 来自 vendor 固定源码包，生成目录行号可能因补丁变化。

## 2. Platform Services / 必需服务与边界

| 服务 | M1 工作与通过条件 |
|---|---|
| 资源路径 | 对获准 profile 显式绑定路径与内容身份；路径不写死在新接口内部。中文/空格路径、缺文件、不可读错误可定位；禁止默认搜索其它 IWAD |
| 数据源 | 保留上游 WAD、节点、BLOCKMAP/REJECT、渲染逻辑元数据链；地图和资源读取来自同一内核解析结果 |
| 写目录 | 存档/诊断/缓存分目录且属于模组；隔离测试使用独立 user://，不影响本体主存档 |
| 配置 | 规则配置显式且进锁；不读取用户独立 Crispy 的残留设置。音量等宿主设置与会影响模拟的规则配置分别处理 |
| 时钟 | 模拟仍由宿主固定步进；新增菜单/媒体服务不再调用 TryRunTics 或借 SDL 时钟额外推进 gameplay |
| 内存 | 原生分配/释放在同一侧；观察缓冲有容量，缓存注明归属/失效；音频库私有分配用其关闭 API 释放 |
| 退出/错误 | 普通退出请求转宿主动作，受控错误返回；C 保护栈不跨未审计的外部回调/析构。未知访问违规仍算崩溃 |
| 构建/部署 | 依赖固定版本/来源/哈希/许可证，ZIP manifest 与更新路径同步；不依赖 `E:/crispy-doom` 等外部目录 |

M1 可以先用开发参数/受限 profile 接路径，不以选文件 UI 为门槛；最终发布包不依赖开发机路径仍是产品交付要求。WAD 路径复制、异常派生样本和用途扩大按 [验收样本边界](M1_VALIDATION.md#2-samples--样本许可与覆盖缺口) 处理。

**用户补充（2026-11-19）**：纯 `doom.wad` 与 `doom.wad + dss/DSS.wad` 已获准并要求正常运行回归。DSS 内嵌 DEHACKED 属该获准 PWAD 的必要内容，M1 必须保留 Crispy 的自动读取语义；不能把 M0 的 `-nodeh` 当所有 profile 的永久默认。继续禁用未获准目录自动发现，正常入口不传外部 `DSS.deh`，也不因它与 PWAD 同目录而自动加载。保存身份记录实际 WAD 和内嵌补丁策略，参考文件不加入活动资源清单。文件哈希及静态核对见 [验收 §2.1](M1_VALIDATION.md#21-approved-additions--m1-新增获准资源2026-11-19)。

## 3. Audio Route / 音频接入方案与冻结方式

**建议先验证保留 Crispy 声音/音乐逻辑与成熟后端的最短路径**，之后根据设备所有权、宿主音量、暂停与卸载结果选择输出方式。M1 需要可听见、可暂停、可退出的完整音频，不要求立即做俯视空间音效或 ETN 风格重新混音。

| 方案 | 复用点 | 必须解决的成本/风险 |
|---|---|---|
| A：原生后端直接输出 | `S_* → I_*` 与已有解码/合成/通道逻辑 | SDL_mixer/其它依赖、与 Godot 音频共存、音量/暂停控制、设备线程及 DLL 卸载 |
| B：保留原生混音/合成，PCM 输出到 Godot | 上游选声/通道及合成，宿主统一设备 | 有界 PCM 队列、采样率/格式、欠载/积压、线程隔离；音频拉取不推进模拟 |
| C：导出声音事件与数据，由 Godot 播放 | 上游触发/选声，Godot 负责实例 | 须保留原生优先级、通道抢占、pitch、位置衰减/停止和音乐解码；不能只逐事件 play 替代全部语义 |

优先探针 A；若设备与会话卸载边界代价过高，再比较 B。C 只有在原生声音语义可以完整、低成本保留时选用，避免重新实现上游混音规则。探针只用获准内容，不为听到音乐临时下载额外素材。

若选择基于上游 OPL 的音乐路径，核验实际构建和 `GENMIDI` 使用；若选择其它合成器，额外数据和依赖须先落实来源与许可。不能假定 Godot 可直接播放 MUS，或认为启用 SDL_mixer 就自动解决所有音乐格式。

冻结记录至少包含：后端/编译开关、SFX 与音乐数据路径、采样率/声道/格式、缓冲容量/上限、设备创建/销毁点、音量映射、暂停策略、设备不可用时行为、依赖锁与真实宿主证据。参数未测前标待测，不填“默认足够”。

## 4. Logical Timing / 声音逻辑与模拟时序

保留 `S_StartSound/S_StopSound/S_UnlinkSound/S_UpdateSounds/S_ChangeMusic` 的选择与对象解绑语义。补接被独占循环绕过的 `S_UpdateSounds`；具体在每 tic 还是每显示帧更新，须与选定参考配置对齐并明确其对通道/RNG 的影响，不从函数名推测无副作用。

M0 对照专门禁用了擦屏动画，保留正常绘制和声音 pitch RNG 路径，详见 [M0 源码审计 §1.1](../M0/M0_SOURCE_AUDIT.md#11-reference-configuration--对照配置与观察钩子)。M1 引入音频后要重新冻结两端配置；不得通过 `nodrawers`、移除 RNG 字段或把已出现的差异归咎于“音效而已”掩盖变化。

同配置下改变 framebuffer/快照读取次数或只静音设备输出，不应改变 gameplay 轨迹。若 `-nosound` 改变上游逻辑分支，应把它作为独立配置记录，不把 `-nosound` 与“选声照常、输出音量为零”混称同一种模式。

音频设备的播放时钟不等于 35 Hz 模拟时钟；不得在设备回调中调 step，不得以“声音队列缺数据”为由补跑 AI。实际音频输出可以有缓冲延迟，逻辑声音记录按触发 tic 标记。测量从输入/触发到声音输出的延迟与长帧欠载，性能预算在目标机器上冻结。

## 5. Lifecycle / 声音与宿主生命周期

| 场景 | 必须行为 |
|---|---|
| 进入 DOOM | 沿用 entry 对现有 SoundManager 播放器状态的保存/暂停，初始化自己的后端；不改本体持久音量配置 |
| 玩家/怪物移动 | 声音来源跟随内核位置；对象删除后执行解绑/停止语义，不访问已释放 mobj |
| 用户暂停/失焦 | 冻结游戏声音/音乐的既定策略，恢复不重放历史开始事件；输入和媒体处理可继续响应退出 |
| 换图/死亡重建 | 停止旧地图声音；音乐按内核流程切换；同通道复用带新实例身份 |
| 读档 | 旧声音/事件失效，按恢复后音乐/持续状态重建；不重播存档前的一次性枪声 |
| 声音设备失败 | 给具体诊断与返回通路；可提供显式无声降级，但降级运行不能记为有声验收通过 |
| 关闭/失败返回 | 停生产者→撤回/停止设备回调→释放队列/资源→关闭后端→销毁内核→卸载 DLL；最后归还 ETN 场景/音频/鼠标 |

不能仅依靠 M0 的 `m0_release_memory()` 释放库私有资源，也不能释放缓冲后再等待仍可能访问它的回调。销毁期间不得通过等待游戏主线程处理音频回调形成死锁。所有原生线程应在 FreeLibrary 前可证明终止。

## 6. Acceptance / 平台与音频验收出口

至少观察获准内容中的枪声、受击/拾取、门/机关、环境或持续声（样本存在时）及关卡音乐；覆盖连发、同时发声、对象消失、移动/远近、暂停、失焦、换图、读档、反复建销。无对应样本时写缺口，不能因扬声器有任意声音就视为全类覆盖。

自动检查事件/通道/缓冲/句柄/错误与确定性；人工检查实际可听、无重复/残声、合理同步、ETN 音频恢复。M1 可以保留原生输出供 M2 继续使用；M2 的空间/视觉音效打磨不接走 M1 未完成的基础播放与清理。

## 7. Implemented Backend / 实际后端与服务边界（2026-11-19）

Source / 来源：code（`etndoom_mod/native/m1_audio.c`、`m1_audio_patches.py`、`m0_core.c`、`m0_reference.c`、`etndoom_mod/build_native.py`）；test（下列本地专项）。本节取代上方尚未选定方案的状态，不据自动生成 PCM 代签人工收听。

| 项目 | 实际冻结值与职责 |
|---|---|
| 音频后端 | 方案 A：Crispy `S_* → I_*`、SDL_mixer 2.8.1 SFX、Crispy 软件 OPL2 合成；GENMIDI 来自当前有序 WAD 视图，无外部 SoundFont/音乐包 |
| 配置 | `snd_sfxdevice=3`、`snd_musicdevice=3`、请求采样率 44100、双声道 S16LE；`snd_pitchshift=0`（沿用 Doom 的上游默认），但选声的原生 pitch RNG 调用保留；OPL_DRIVER 固定 SDL，DMXOPTION 固定空串，禁用未编译的 libsamplerate |
| 依赖 | `vendor/SDL2_mixer-devel-2.8.1-mingw.tar.gz`，SHA-256 `b6c98eecd308aa9922ede0aac466bb5dea6c3e9b9b59dd496009f778c90d83d7`；来源/许可证/运行 DLL 哈希在 `vendor/dependencies.json`。新增运行库为 `SDL2_mixer.dll`，其直接依赖只有 SDL2 与 Windows 系统库 |
| 输出设备 | SDL_mixer 直接创建/播放，实测驱动 `wasapi`、44100 Hz、2 声道；Godot 不再次播放声音事件，不创建重复音源 |
| 观测 PCM | postmix 回调把最终混音复制到 262144 字节固定环形缓冲；`m1_audio_read` 只读并消费观测副本，不推进 tic。溢出保留最新数据并累计 `capture_dropped_bytes`，不影响实际播放，也不把观测副本溢出称为播放欠载 |
| 音频状态 | `m1_audio_status` / `m1_audio_info` 返回设备、初始化/暂停、采样格式、非零样本数、回调数、峰值、音乐资源及 32 个声音槽位；槽位带递增 instance、资源 lump ID、可识别的实体 ID、音量/声像/pitch |
| 音频事件 | start/stop/music/pause/resume 接入 `m1_events` 的同一有界队列；声音槽位复用产生新 instance。世界重建后的消费者用全量音频状态重新同步；直接输出不依赖消费者 ack 才播放 |
| 音量 | `m1_audio_set_volume(sfx,music)` 接受 0..127 输出增益；不通过 `S_SetSfxVolume(0)` 静音，避免其跳过原生选声/pitch RNG。音乐修改在 OPL 锁内执行 |
| 暂停 | 先 `Mix_PauseAudio(1)` 停设备回调，再冻结上游音乐；恢复上游音乐后恢复设备。SFX 与音乐均不在暂停时继续消耗播放时钟 |
| 临时文件 | OPL 的 MUS→MIDI 临时文件改到当前会话 `savedir/.m1-music.mid`，使用 UTF-8 文件包装并在注册后删除，不再写公共 TEMP 的 `doom.mid` |
| 失败 | 初始化核验声音/音乐模块、实际活动音乐、设备格式；不能创建时返回错误，不把无声运行记录为有声通过 |
| 销毁 | 停设备→同步撤 postmix→释放观测锁→先销毁音乐/OPL、再关闭 SFX 设备→内核退出 handler/分配释放→宿主卸载 DLL。上游 OPL 的 effect 在释放队列/锁前注销；共享设备场景也释放 OPL 缓冲，退出函数可重复调用 |

### 7.1 Fixed Render Boundary / 固定绘图边界

读取帧缓冲原本并非无副作用：`R_StoreWallRange` 会给原生 linedef 设置 `ML_MAPPED`；E3 结局的 `F_BunnyScroll` 原本在 Drawer 中触发 pistol 音效并消耗 `M_Random`。专项首先在 fixture 第 2 tic 发现 `lines.flags` 差异，没有通过屏蔽发现位或忽略 RNG 使测试通过。

实际实现将软件绘图固定在每个模拟 tic 后，顺序为 `M_Ticker → RunTic → gametic++ → S_UpdateSounds → D_Display → RGBA 缓存`。初始化及成功重建世界的流程命令也刷新缓存，但不增加 tic；`m0_frame` 仅读缓存，额外截图/显示刷新不再改变原始发现位。独立参考仍保留 `TryRunTics/RunTic`，在对应每 tic 观察边界绘图，原 `D_RunFrame` 的重复绘图/声音更新被替换为展示已生成结果；两端均禁擦屏动画。M1 的这一 35 Hz 内部软件绘图仍是诊断表现，不是 M2 最终俯视。

E3 ARTSCREEN 的六次 pistol 提示迁到 `F_Ticker` 的 `finalecount=1185,1190,1195,1200,1205,1210`，保持规范逐 tic 播放时序；Drawer 只绘图，无新增需存档的静态计数器。上述改动均通过有锚点计数检查的补丁应用到锁定源码，不手工修改生成目录。

### 7.2 Button Sound Determinism / 按钮声音的确定性修正

Source / 来源：code（`native/m1_audio_patches.py` 的 `p_spec.c` 补丁、上游 `s_sound.c:S_StartSoundOnce`）；test（`tests/m1_button_audio_checks.py`）。

锁定配置的 `soundfull=0` 使敌人声音的 `S_StartSoundOnce` 分支不启用，berserk 武器分支本身处于 `#if 0`；实际仍会调用该函数的是 `P_UpdateSpecials` 的按钮恢复。它原先检查真实设备声道是否仍在播放，决定是否调用 `S_StartSound`，因而也决定是否消耗 pitch 的 `M_Random`。这不是纯输出差异。

真实 E1M1 的 line 136（SR 门按钮）已用正常 ticcmd 复现：第 136 tic 按下，第 170 tic 恢复；快速执行只有 1 次 `sound_start`，在按下后等待设备 1.3 秒则有 2 次，并从第 170 tic 开始出现 RNG 索引差异。修正前证据保存在 `tests/m1_results/button_audio_before_20261119/summary.json`，未改世界位置、按钮或随机数。

M1 明确改变此处的声音去重语义：按钮恢复使用 `S_StartSound`，仅在**同一次 `P_UpdateSpecials` 中、同一 soundorg** 的多个贴图恢复之间去重；不再以设备播放完成情况决定。到期按钮槽位延迟到本次扫描结束后统一清零，供扫描读取先前来源，不增加跨 tic 状态或存档字段。核心和独立参考均应用相同补丁。一般声音通道仍由原生后端播放，不能将本修正描述成“完全未改变音频逻辑”。

### 7.3 Automated Evidence / 自动证据与边界

```powershell
py -3 etndoom_mod/build_native.py --all
py -3 tests/m1_audio_checks.py --out tests/m1_results/audio_20261119
py -3 tests/m1_reference_checks.py --out tests/m1_results/reference_extra_20261119
py -3 tests/m1_button_audio_checks.py --output tests/m1_results/button_audio_final_20261119
py -3 tests/m1_render_resources.py --output tests/m1_results/render_resources_final_20261119
```

- `tests/m1_results/audio_20261119/summary.json`：实际 WASAPI 音乐与射击混音具有非零 PCM；5 次枪声事件；暂停期间回调计数保持不变，恢复后递增；100 tic 静音加重复读取与正常输出轨迹一致；3 次会话创建/销毁后跟踪分配均归零；不存在的 SDL 音频驱动返回失败并完成释放。`captured_mix.wav` 是本地混音证据，人工听感仍待验证。
- `tests/m1_results/reference_extra_20261119/summary.json`：fixture jump=0/1/2 各 70 tic、纯 Doom E2M1 移动/攻击 350 tic；每组都执行 0/1/3 次帧/快照读取。0 次模式比较最终状态，1/3 次模式逐 tic 与独立参考比较；除单独的宿主控制面字段外，保留原始整数、RNG、实体、sector/side、linedef 发现位等字段。
- 上述证据不证明地图中每一种声音/机关均实际触发，也不把 E3 结局提示的源码审计当成完整结局路线已跑通。真实宿主、更多玩法路线、存档最终版本复跑与人工收听继续在 [验收文档](M1_VALIDATION.md) 统一汇总；最终构建身份以交付索引和对应 `build-lock.json` 为准。

2026-11-19 最终冻结内核 `0d0db6de55a422186ff28457269eb8d365842de614e29ad20453dc13e0988f26` 已复跑以下专项，路径均为本地测试证据，不纳入发布包：

- `tests/m1_results/audio_final_20261119/summary.json`：实际 WASAPI、音乐与射击非零 PCM、暂停回调冻结/恢复、100 tic 静音与重复读取确定性、三次会话卸载及错误驱动清理全部通过；人工收听仍待执行。
- `tests/m1_results/button_audio_final_20261119/summary.json`：同一真实按钮路径 176 tic，快速执行与按下后停顿 1.3 秒的全部权威快照相等，两端均发生两次声音开始。设备完成导致的 stop 观测仍属于实际播放状态，不能用它调度模拟。
- `tests/m1_results/button_reference_final_20261119/summary.json`、`tests/m1_results/reference_extra_final_20261119/summary.json`：上述按钮 176 tic、fixture jump=0/1/2 各 70 tic、Doom E2M1 移动攻击 350 tic 均通过最终独立参考与 0/1/3 次读取对照。独立参考 SHA-256 为 `5fbc12d451e2610ffb8074f8d2894056d0cc7a5ccd66d6b971df3166b7e8f0c3`；0 次模式比较终态，1/3 次模式逐 tic 比较，不屏蔽 RNG 或 linedef flags。
- `tests/m1_results/api_boundary_final_20261119/summary.json`：12 类资源读取参数边界、重复读取/确认、事件容量与失败清理通过；第 8193 次不确认的暂停切换明确返回 `CORE_FAILURE` / `active=false`，保留 8192 项及失败标记，旧会话停止后可新建会话。
- `tests/m1_results/render_resources_final_20261119/summary.json`：Doom E1M1 解码 1115 个不同 patch、合成 287 个 texture、解码 107 个 flat、核验 3328 个 sprite rotation；DSS E2M1/E4M1 各为 1461 / 575 / 108 / 4288，分别确认内嵌 DEHACKED 修改 326 项 states。全部拓扑索引、BSP、实体关系及只读不改变权威快照通过；每组提供 `m2_sample.png`、`m2_sample.json` 与单项 PNG。原生 flat 索引保留命名空间 marker，必须依据 `decodable` 消费，真实地图引用均可解码。
