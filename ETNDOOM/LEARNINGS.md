# Learnings / 经验库

> Scope / 范围：归档后的新增移植认知；旧条目保留在 [Legacy/LEARNINGS.md](Legacy/LEARNINGS.md)，本文件不恢复或复制其全文。本体参考仍见 `docs/LEARNINGS.md`。
> Entry format / 条目格式：标题、Evidence / 证据、Notes / 说明、Source / 来源、Date / 日期。用户假设与已确认事实分别标注；未确定的高影响结论放入「待确认 / To Confirm」。

### [Port/Scope] 关卡步进不等于完整游戏运行时，PWAD 装载也不是额外玩法
- Evidence / 证据：`E:/DOOMSourceCode/linuxdoom-1.10/p_tick.c:130`；`g_game.c:605,1020,1172,1201,1270`；`d_main.c:938`；`w_wad.c:292,351`（后四项同属该只读研究目录）；`E:/isodoom/src/Game/GameFlow.cs:24`。
- Notes / 说明：经典 `P_Ticker()` 推进关卡中的玩家、thinkers 和 specials；`G_Ticker()` 另调度装图、重生、存读档、结算和结束状态。移植仅保留 `p_*` 会留下完整游戏流程缺口，因此“内核移植完成”须明确包含哪些流程模块及宿主替换点。经典 `-file` 和多文件资源查找已支持外部 PWAD；ETN 仍需接文件路径、装载配置、UI 及俯视显示，且不能由 PWAD 支持推出所有第三方内容兼容。上述为源码结构事实；具体候选和 ETN 运行结果仍待验证。路线调整见 [DOOM 移植开发路线](ModdingDocs/DOOM_PORT_DEVELOPMENT_ROADMAP.md) §4–5。
- Source / 来源：code。
- Date / 日期：2026-11-16。

### [Port/M0] 继承能力不等于 M0 开放范围或 WAD 加载许可
- Evidence / 证据：用户 2026-11-16 对 M0 迁移矩阵、四组决策与测试预期的裁定及 2026-11-17 WAD 加载许可；[M0_LEGACY_MIGRATION.md](ModdingDocs/M0/M0_LEGACY_MIGRATION.md) §2.1、§3–4。
- Notes / 说明：M0 基本需求为“ETN 中能运行一个移植 DOOM”，俯视功能不属于 M0。Source Port 自带玩法按选定版本继承；旧命中决策不带入 B0，旧天空与自研导航/刷怪/突袭决策丢弃。原生跳跃支持则原样移植验证，不支持则跳跃保持 B2，不移植 ETN 跳跃；ETN 跳跃表现始终 B2。D08 全部 B2/M3，不能因上游支持 PWAD 就将通用资源装载恢复成 M0 门槛。M0 只加载用户明确给定并允许的 WAD。SUPERSEDED: 2026-11-17 用户给定清单，替代“清单未给定”状态：2026-11-17 已获准 `DOOM2.WAD + MAP01.wad` 用于自制图自动回归及人工验证；单独 `DOOM2.WAD` 主要用于人工验证，自动回归仅验证正确加载。完整路径见[探针 §4.1](ModdingDocs/M0/M0_PROBES_AND_ACCEPTANCE.md#41-approved-wads--当前获准加载清单2026-11-17)。其它文件不能因本地存在、被文档引用或作为依赖而视为获准。Stage0 表现基线归 B1/M2；复杂地图更多依靠人工验收，MAP02/NoBorder 保留基本自动回归；地图特例永远是优先级最低的方案。策略确认与具体版本行为验证必须分开记录。
- Source / 来源：user。
- Date / 日期：2026-11-17（更新许可状态，保留原策略）。

### [Port/Packaging] ZIP 附加文件、PCK 挂载与原生库可加载是三个不同边界
- Evidence / 证据：`script/mod_installer.gd:4,48,51,85`；`script/mod_manager.gd:18,19,582,1059`；`etndoom_mod/build_stage0.py:23,28,50`。
- Notes / 说明：当前安装器校验布局后提取 ZIP 条目，未限制为仅 PCK，并以目录重命名交换安装；Stage0 构建却只收集既定白名单并把 manifest/PCK 放进 ZIP。新增原生库因此需要单独的构建/布局与真实宿主加载验证，不能以现有安装器可提取附加文件推断 DLL 已可运行。运行中 DLL 对目录交换及卸载的影响也未实测，列为 M0 P2/P5 门槛，见 [M0 构建边界](ModdingDocs/M0/M0_SELECTION_AND_BUILD.md) §5。此条只确认源码结构，不声明原生部署已成功或必然失败。
- Source / 来源：code。
- Date / 日期：2026-11-16。

### [Port/Backends] 最终目标为 GZDoom/UZDoom，首版后端须可保留切换
- Evidence / 证据：用户 2026-11-16 的首版 Source Port 选型要求；[路线 §1](ModdingDocs/DOOM_PORT_DEVELOPMENT_ROADMAP.md#1-objective--开发目标与完成口径)、[选型 §8](ModdingDocs/M0/M0_SELECTION_AND_BUILD.md#8-first-port-recommendation--首版四候选评估2026-11-16)。
- Notes / 说明：最终使用 GZDoom/UZDoom，并支持在此前已经移植的 Source Port 中切换；第一版满足 M0–M1。不能将旧“首版只做一套”扩大为永久单内核，也不能把 GZDoom/UZDoom 仍记作未定长期方向。SUPERSEDED: 2026-11-16，原“首版候选尚未确认”由用户确认 Crispy Doom 为首个内核取代，源码位于 `E:/crispy-doom`。用户同时明确目标端口有限、现代端口存在相互模仿与兼容；首版不强求完全公共桥接接口或通用适配器，先完成 Crispy 的实际接入，第二个内核接入时再按需要复用或调整。必要的宿主生命周期与状态边界保留；退出会话后切换与存档互通范围仍属待裁定技术细节。
- Source / 来源：user。
- Date / 日期：2026-11-16。

### [Port/M0] 试验内核版本与源码身份分别记录
- Evidence / 证据：用户 2026-11-17 重申试验内核为 Crispy Doom 7.2；[选型 §8.1](ModdingDocs/M0/M0_SELECTION_AND_BUILD.md#81-conclusion--结论与状态)。
- Notes / 说明：内核版本已确认，不再列为开工前待用户选择；历史记录的 7.2 tag 与本地 `7.2-1` HEAD 分开保留，实施时锁定实际 commit/补丁并核验。选型确认不等于参考构建、宿主加载或运行验收通过。
- Source / 来源：user。
- Date / 日期：2026-11-17。

### [Port/Crispy] 文件职责不能按网络或渲染前缀裁剪，跳跃须保留生效配置链
- Evidence / 证据：`E:/crispy-doom/src/doom/d_net.c:71,93,96,257`、`src/crispy.c:44`、`src/doom/g_game.c:730`、`src/doom/p_user.c:388`（后者路径相对于同一源码根，commit `35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2`）；完整模块定位见[运行时边界 §3–4](ModdingDocs/M0/M0_RUNTIME_BOUNDARY.md#4-hidden-dependencies--必须验证的隐式依赖)。
- Notes / 说明：`d_net.c` 中的 `RunTic` 先设置 `netcmds` 再执行 `G_Ticker`，单人也依赖此职责，不能因不做联机就整文件删去。Crispy 跳跃经 `critical->jump` 与 `AFLAG_JUMP` 生效；`CheckCrispySingleplayer` 决定 `critical` 指向实际配置还是零配置，因此只写跳跃选项不等于玩法已启用。这些是静态源码事实，宿主接入与运行仍待验证。
- Source / 来源：code。
- Date / 日期：2026-11-17。

### [Port/License] 免费且不附带 IWAD 不免除 GPL 分发义务
- Evidence / 证据：`E:/crispy-doom/README.md:127`、`src/doom/p_tick.c:5`（同一只读研究目录，commit `35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2`）；[Crispy COPYING](https://github.com/fabiangreffrath/crispy-doom/blob/35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2/COPYING.md) §2–3；[UZDoom LICENSE](https://github.com/UZDoom/UZDoom/blob/trunk/LICENSE) 前言、§1、§5–6、§10；[GZDoom LICENSE](https://github.com/ZDoom/gzdoom/blob/master/LICENSE)。在线分支于 2026-11-17 核对，后两者尚非本项目冻结版本。
- Notes / 说明：Crispy 主体声明 GPL-2.0-or-later，当前 GZDoom/UZDoom 主体为 GPLv3；在纳入文件及依赖均兼容的前提下，可选择 GPLv3 满足组合发布要求，不能把 GPLv2-only 与 GPLv3 混为兼容。免费不免除版权/许可保留、修改标识、对应源码与构建脚本交付以及下游修改和再分发权利；仅附上游仓库地址不能替代交付本项目实际版本的修改与桥接源码。不附带商业 IWAD 只处理相应资源的分发边界，不能替代代码许可合规。UZDoom 根 LICENSE 还明确指出品牌及部分内置素材另有许可，须按实际打包内容审计；本地副本的 `wadsrc_extra` 许可实际位于 `wadsrc_extra/nonfree/license.md`，不能只依赖根文件列出的旧 `static` 路径。本条为许可证文本核对，不是最终发布法律结论。
- Source / 来源：code（源码仓库随附许可及官方许可证文本）。
- Date / 日期：2026-11-17。

### [Port/License] 完全开源假设下可采用 GPLv3 合规发布，仍须覆盖实际组合范围
- Evidence / 证据：用户 2026-11-17 追加“如果 ETNDOOM 是完全开源项目”的条件性提问；上条所列 Crispy、GZDoom、UZDoom 许可证；`README.md:136`。
- Notes / 说明：该输入是评估假设，不是用户已选定许可证或已完成开源的裁定。在使用文件及依赖兼容的前提下，ETNDOOM 的组合代码按 GPLv3 发布、提供与二进制匹配的完整对应源码及必要构建/安装脚本、保留版权/许可/修改声明并保障下游 GPL 权利，可以满足三个端口主体代码的许可要求。“完全开源”不能只指公开源码，也不能任意选择与 GPLv3 不兼容的开源许可。各组件可保留兼容的原许可，组合整体遵守 GPLv3，不意味着擅自改写上游版权声明。若仅 ETNDOOM 模组开源，ETN 本体授权及实际组合范围仍须核实；若应纳入组合范围的宿主代码也获得兼容授权并履行相应源码义务，该边界障碍可解决。独立资源许可仍另行处理。本轮不更改项目许可证，不把假设写成发布合规已验收。
- Source / 来源：user（新增假设） | code（前轮核对的许可证文本）。
- Date / 日期：2026-11-17。

### [Port/Save] Crispy 上游存档未完整记录确定性续跑所需 RNG 状态
- Evidence / 证据：固定 commit `35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2` 的 `src/doom/g_game.c:2536,2848`、`src/doom/p_extsaveg.c:469`、`src/doom/m_random.c:46,70`；只读核对源为 `E:/crispy-doom`，不是正式构建依赖。完整审计见 [M0_SOURCE_AUDIT.md](ModdingDocs/M0/M0_SOURCE_AUDIT.md) §3。
- Notes / 说明：`G_DoLoadGame` 先调 `G_InitNew`，后者 `M_ClearRandom` 清零 `rndindex/prndindex/crndindex`；已核对基础/扩展存档未归档这些索引。因此保留上游存档不能直接承诺“保存→读取”后的逐 tic 轨迹等同不中断运行。M1 的存档封套需补足经审计的 RNG/调度状态，并对比后续输入的完整轨迹；不能仅测试第一帧位置或存档文件存在。这是明确代码事实。SUPERSEDED: 2026-11-19已由M1封套补足三组RNG及其它状态，并通过每支路350tic续跑；完整审计上提到 [M1流程/存档§8](ModdingDocs/M1/M1_FLOW_AND_SAVE.md)。
- Source / 来源：code。
- Date / 日期：2026-11-17。

### [Port/Native] Windows DLL 首次加载须规范化分隔符，已加载模块会掩盖路径错误
- Evidence / 证据：`etndoom_mod/gdextension/bridge.c` 的 `LoadLibraryExW` 调用与 UTF-8→UTF-16 路径转换；2026-11-17 原生桥接中文空格缓存目录探针。
- Notes / 说明：使用 `LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_DEFAULT_DIRS` 时，本轮正斜杠绝对路径首次加载返回 Win32 126；转换为反斜杠后成功。同进程先用反斜杠加载，再用正斜杠访问已加载模块可能成功，不能据此证明首次装载路径正确。桥接现先转换路径分隔符，再检查 `MultiByteToWideChar` 结果并调用宽字符加载 API；回归必须在新进程中验证中文/空格路径与依赖搜索。
- Source / 来源：code | test。
- Date / 日期：2026-11-17。

### [Port/Milestone] M0 阶段完成与组合发布授权分别记录
- Evidence / 证据：用户 2026-11-18 明确“预期内的M0行为全部完成，我标记人工验证为通过”；[M0 人工验收](ModdingDocs/M0/M0_MANUAL_VALIDATION.md) §5；本地 `tests/m0_results/final_delivery_20261117/manual_acceptance.json`。
- Notes / 说明：M0 技术实现、自动回归与人工验收已完成。SUPERSEDED: 2026-11-17 的人工待确认状态及将阶段完成与全部发布 Gate 绑定的旧口径。G1 组合发布授权继续按用户既有答复保留待裁定，不能因阶段结案推定授权通过；完整玩法/流程/存档/音频及最终俯视分别仍归 M1/M2。原自动日志中的 `manual_acceptance=false` 是生成当时快照，当前人工结论另记，不回写自动证据。
- Source / 来源：user。
- Date / 日期：2026-11-18。

### [Port/Control] 绕过上游主循环后，保存请求消费与声音更新必须单独接回
- Evidence / 证据：本仓 `etndoom_mod/vendor/crispy-doom-35b49519.tar.gz`（固定 commit `35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2`）内 `src/doom/g_game.c:944,2579,2585`、`src/doom/d_main.c:558`；`etndoom_mod/native/m0_core.c:62`；`etndoom_mod/build_native.py:49`。
- Notes / 说明：`G_SaveGame()` 仅设置 `sendsave`，由 `G_BuildTiccmd` 转成特殊按钮后进入保存调度。M0 直接构造 ticcmd 并调用 RunTic，普通 buttons 又只接受 0..127，因此不能仅导出 `G_SaveGame()` 就认为存档可执行。`S_UpdateSounds()` 的常规更新位于被宿主替代的 `D_RunFrame`，也不因 `S_*` 编译进 DLL 自动得到调用。M1 必须显式接回这些服务，并让暂停中的保存/读取/退出不依赖额外 gameplay tic。SUPERSEDED: 2026-11-19已接通独立控制泵与每tic声音更新，暂停存读及真实WASAPI专项通过；实际出口见 [流程/存档](ModdingDocs/M1/M1_FLOW_AND_SAVE.md) §2 和 [平台/音频](ModdingDocs/M1/M1_PLATFORM_AND_AUDIO.md) §1、§4。
- Source / 来源：code。
- Date / 日期：2026-11-18。

### [Port/M1] Doom/DSS 已获准回归，DSS 只使用内嵌补丁
- Evidence / 证据：用户 2026-11-19 指定 `doom.wad`、`dss/DSS.wad` 与参考 `dss/DSS.deh`；[M1 验收 §2.1](ModdingDocs/M1/M1_VALIDATION.md#21-approved-additions--m1-新增获准资源2026-11-19) 记录路径、哈希、目录及加载策略；固定 Crispy `src/doom/d_main.c:2070,2084`；`etndoom_mod/native/m0_core.c:53`。
- Notes / 说明：SUPERSEDED: 2026-11-18 M1 细化稿中“Doom/第三方回归文件尚未落实”的状态。用户确认 `doom.wad` 为 The Ultimate Doom，须单独加载正常运行；DSS 为基于 Doom 1.9、可在 Crispy Doom 运行的第三方 WAD，回归使用该 Doom IWAD 加载并正常运行。外部 `DSS.deh` 用于 Dos Doom、仅供参考；Crispy 正常使用 DSS 的内嵌 DEHACKED，不额外加载外部文件。静态核对发现 M0 的 `-nodeh` 会禁用内嵌补丁，M1 需调整该获准 profile 的策略；DSS 替换 E2/E4 地图，不能仅测 E1M1。内嵌/外部补丁字节不同，分别记身份，不据此推翻用户指定的加载方式。许可与用户提供的兼容信息不等于已完成 ETN 移植实测；通用资源功能仍归 M3。
- Source / 来源：user（许可、用途与兼容说明） | code（静态文件/源码核对）。
- Date / 日期：2026-11-19。

### [Port/Observation] 读取 framebuffer 必须与原生绘图副作用解耦
- Evidence / 证据：`etndoom_mod/native/core_source/src/doom/r_segs.c:R_StoreWallRange`、`f_finale.c:F_BunnyScroll`（生成自固定源码包）；正式补丁 `etndoom_mod/native/m1_audio_patches.py`，缓存边界 `m0_core.c:refresh_frame/m0_frame`；本地 `tests/m1_results/audio_20261119/`、`reference_extra_20261119/`。
- Notes / 说明：原生绘图会设置 `ML_MAPPED`，兔子结局 Drawer 原本还触发声音、消耗 `M_Random`；仅说明“读取不推进 tic”不足以保证观察无副作用。本轮多读取对照在第 2 tic 定位到真实 line flags 差异。M1 将绘图固定到内核初始化/每 tic/世界替换边界，framebuffer 仅读缓存；结局音效迁入 ticker，两端同补丁。差分保留全部原始 flags，不屏蔽探索位掩盖问题。
- Source / 来源：code | test。
- Date / 日期：2026-11-19。

### [Port/Audio] 卸载内核前必须撤回共享 SDL_mixer 上的 OPL 回调
- Evidence / 证据：`etndoom_mod/native/m1_audio_patches.py` 对 `opl/opl_sdl.c:OPL_SDL_Shutdown` 的修改；`native/m1_audio.c:m1_audio_shutdown`；本地音频专项的设备、PCM、暂停和反复销毁记录。
- Notes / 说明：上游 OPL 可与 SFX 共用 mixer 设备，不能只在 OPL 自己拥有设备时释放 callback_queue/mix_buffer。DLL 销毁前还须注销 `MIX_CHANNEL_POST` effect 与 PCM 观察回调，等待设备边界后再释放缓冲/锁；内核追踪分配计数清零不能替代撤回外部库仍持有的函数指针。
- Source / 来源：code | test。
- Date / 日期：2026-11-19。

### [Port/Save] 原生存档补足范围包含精度、遍历顺序与未归档相位
- Evidence / 证据：`etndoom_mod/native/m1_save.c`、构建器中的保存辅助补丁；[M1 保存审计](ModdingDocs/M1/M1_FLOW_AND_SAVE.md) §8.2。
- Notes / 说明：除三组 RNG 外，原生 `P_ArchiveWorld` 将部分地板/天花板高度与 side offset 压为整数 16 位，恢复会把 mobj/specials 分组，按钮恢复会压紧槽位，Brain 产怪的 easy 相位不在原存档内。M1 封套补足定点值、thinker/碰撞链顺序、按钮空槽及相位；还须恢复G_InitNew切换Nightmare时原地改写的状态tics与弹射物速度，DEH奇数值不能假定移位可逆；需用不中断分支对照实际运动/战斗续跑，不能只凭原版存档存在推断确定性。
- Source / 来源：code。
- Date / 日期：2026-11-19。

### [Port/Audio] 按钮声音的设备去重会改变随机数消耗
- Evidence / 证据：`etndoom_mod/native/m1_audio_patches.py` 的 `p_spec.c` 补丁；本地 `tests/m1_results/button_audio_before_20261119/summary.json`、`button_audio_final_20261119/summary.json`。
- Notes / 说明：E1M1真实SR按钮第136tic按下、170tic恢复，快跑与设备等待1.3秒在修正前出现不同M_Random索引。`S_StartSoundOnce`依设备是否还播放旧声决定调用，不能作为确定性模拟条件。M1仅在同一次P_UpdateSpecials、同一soundorg的多个恢复之间去重，核心/参考同补丁；修正后快慢完整轨迹及350tic存读续跑通过。详细原因上提到平台/音频§7.2。
- Source / 来源：code | test。
- Date / 日期：2026-11-19。

### [Port/Observation] 原生结构体的全部字段不都在当前状态有效
- Evidence / 证据：`etndoom_mod/native/m0_observer.c:specials`；`tests/m1_results/save_routes_final2_20261119/summary.json`；[M1数据格式](ModdingDocs/M1/M1_DATA_SCHEMA.md)。
- Notes / 说明：plat运动期间count、非stasis时oldstatus、单向机关不存在的目标高度等可能尚未初始化。直接序列化会读到堆垃圾并制造假差异，不能通过改上游玩法初始化或屏蔽活动计时修复。观察接口按原生类型/状态输出valid_mask，无效槽位填0且不读取；flat目录中的零长度命名空间marker同样须明确不可解码，索引不能重排。
- Source / 来源：code | test。
- Date / 日期：2026-11-19。

### [Port/Resources] 纹理索引0不能一概当作无逻辑尺寸
- Evidence / 证据：固定Crispy `src/doom/p_floor.c:EV_DoFloor` 的`raiseToTexture`分支；本地`tests/m1_results/gameplay_final3/textureheight/summary.json`。
- Notes / 说明：该动作检查bottomtexture>=0，索引0同样参与最短纹理高度计算。E4M7第2016tic的sector242相邻底纹理有SUPPORT3(index260,128mu)与AASTINKY(index0,72mu)，目标为触发前0+72mu；过滤index0会错误得到128mu。2366tic正常输入及触发后350tic独立参考完全一致；M2显示层的空贴图处理不能反过来改原生机关逻辑尺寸。
- Source / 来源：code | test。
- Date / 日期：2026-11-19。

## 待确认 / To Confirm

### [Port/License] ETN 宿主与 GPL 内核的组合范围及授权尚待确认
- Confirmation / 用户确认：2026-11-17 实施 M0 期间，用户明确答复 G1 授权“尚未确定”，按**待裁定**记录。本地实现和自动回归继续；不能将技术验证通过写成 G1 已通过，也不替用户选择项目许可证或宣布组合可发布。
- Evidence / 证据：`README.md:136`；[M0 选型与构建](ModdingDocs/M0/M0_SELECTION_AND_BUILD.md) §2、§4；[GNU FAQ：插件边界](https://www.gnu.org/licenses/gpl-faq.en.html#GPLPlugins)、[独立聚合与组合程序](https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation)。
- Notes / 说明：当前 README 明确写有“仓库目前未附带项目级 LICENSE”，不能由源码可见推出 ETN 代码已有 GPL 兼容授权。按 GNU/FSF 的解释，同进程动态链接、相互函数调用及共享内部数据可能构成单一组合程序；DLL/PCK/ZIP 分开、单独下载或称为模组不自动豁免，独立进程也须看通信语义。TODO: 核实实际 ETN 代码权利人及授权、最终桥接实现和发布内容，判断对应源码及 GPL 许可须覆盖哪些宿主代码；不预先认定只开放内核足够，也不认定整个仓库及独立美术资源自动变为 GPL。此处为风险识别，GNU FAQ 是许可制定方解释，具体法律边界仍须结合事实评估；本轮未替用户选择或更改项目许可证。移植工期、继承覆盖和俯视适配成本仍见路线文档的未验证事项。
- Source / 来源：user（2026-11-17 明确尚未确定） | code（仓库声明及官方许可解释）。
- Date / 日期：2026-11-17。

### [Migration/Host] fork 兼容测试必须使用新版源码宿主与新资源路径
- Evidence / 证据：`etndoom_mod/m1/session.gd:4`；本地 `.migration/compat_20261123/host_export.json`；`tests/m1_results/20261123_180649/summary.json`；`tests/m1_results/fork_compat_20261123/summary.json`。
- Notes / 说明：复制 Git 内容后，PCK 中的旧绝对 WAD 路径仍能读旧目录，旧发布 EXE 也不能证明对新版本体兼容。迁移须调整源码常量、重建原生/PCK，并从 fork 当前本体导出隔离宿主。实际仓库的 godot_ai 状态不改；缺失插件只在临时测试副本中剔除，原目录直接导出的宿主启动验证曾因此失败。新目录测试通过不代表完整 M1 人工验收，也不改变 M0 ABI 1 与当前 M1 ABI 2 的边界。
- Source / 来源：code | test。
- Date / 日期：2026-11-23。
