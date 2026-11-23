# M0 Source Audit / 固定源码能力与完整运行时审计

> Date / 日期：2026-11-17。
> Source / 来源：code（Crispy 固定源码、本体加载器与随附许可）。
> Scope / 范围：本文件记录源码能证明的行为及其 M1 验证归属；构建和宿主实测另见 [探针与验收](M0_PROBES_AND_ACCEPTANCE.md)，不能由此推定测试通过。
> Identity / 身份：`https://github.com/fabiangreffrath/crispy-doom.git`，commit `35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2`，7.2 tag `fdeabe4c23a833534b70aa84a22f1685aae7125d` 后一个提交；差异仅 Hexen `poly` 指针初始化修正。下方 `src/` 锚点均属于此 commit 的 Crispy 源码，最初通过只读研究副本 `E:/crispy-doom` 核对；该绝对路径不是正式构建依赖。

## 1. Compatibility / 能力、开放范围与证据等级

以下全部为“固定版本源码核对”，不是“ETN 实测”。M0 只开放获准的 `DOOM2.WAD + MAP01.wad` 与单独 `DOOM2.WAD`；其它文件、扩展格式和补丁均未获得本次加载许可。

| 项目 | 固定源码事实 | 本项目范围、失败呈现与后续验证 |
|---|---|---|
| 游戏识别 | `src/d_iwad.c`、`src/doom/d_main.c` 按 IWAD 内容及命令行选择 Doom/Doom II 等模式；`README.md:14,20,32` 声明 limit-removing 与部分商业扩展 | M0 只验证本地获准 Doom II 资源。Doom、任务包和不同 IWAD 版本列 M1/M4 待获准样本，不由一次 Doom II 通过推及全部 |
| 经典地图与索引 | `src/doom/p_setup.c:229,234,355,384,546` 对部分无效 seg/side、空 subsector/sector、缺玩家起点调用 `I_Error` | 继承上游解析器；不恢复旧自研“全部开放轮廓拒绝”规则。任意坏地图并非都可靠预检，未知内存破坏不承诺可恢复；M0 反例先用缺文件，损坏文件专项等待单独许可 |
| 节点 | `src/doom/p_setup.c:1338,1343,1349` 分支加载 ZDBSP、DeePBSP v4、经典节点；`src/doom/p_extnodes.c:390,413,444` 有 XNOD/XGL3 等路径；`:515` 明确在无解压支持时拒绝压缩节点 | 上游有对应读取代码不等于正式构建启用了全部依赖。M0 仅核实获准图实际走的路径；压缩/GL/扩展节点实测归 M1/M4，并记录实际 zlib 配置 |
| BLOCKMAP / REJECT | `src/doom/p_setup.c:883,1124,1316,1354` 载入 BLOCKMAP/REJECT，BLOCKMAP 必要时重建；`src/doom/p_blockmap.c` 提供构建 | 不沿用旧“不使用 BLOCKMAP/REJECT”。重建与过短 REJECT 的兼容行为由内核处理，M1 用获准异常样本核对；不将重建描述成 BSP 构建 |
| Hexen / UDMF | `src/doom/p_setup.c:557,1366` 存在 Hexen THINGS 分支；`README.md:57` 明确不支持完整 Boom/ZDoom 地图语义、DECORATE/MAPINFO | 首版不承诺 Hexen 格式或 UDMF；“存在分支”不等于所有动作/脚本语义可用。超出范围时不得以加载成功宣称完整兼容 |
| DeHackEd / BEX | `src/doom/d_main.c:1494,1855,2063,2084` 初始化并处理补丁，`src/doom/deh_*` 保留属性/状态/字符串解析；`README.md:59` 声明 BEX | 上游能力保留，M0 不开放通用补丁输入，也不加载额外补丁。M3 对外开放时单独测试顺序、状态表、错误恢复与会话污染 |
| 资源优先级 | `src/w_wad.c:103,264,401,557` 负责有序 WAD、名字查找、缓存与哈希；图与贴图等最终解析结果由这条链决定 | M0 只运行许可清单中的必要 PWAD。通用多 PWAD、补丁及 ETNINFO 为 B2/M3；Godot 不另选一个“看起来相同”的资源视图 |
| 特殊制图 | 上游 limit-removing，不意味着完整 Boom；ANIMATED、SWITCHES、MBF sky transfer、SMMU swirling flats、MUSINFO 的有限支持列于 `README.md:57` | 不把少数来源于 Boom/MBF 的功能扩大为 Boom/MBF/MBF21 兼容声明；深水/自引用等 M1 玩法与 M2 俯视分别验收 |
| demo / 网络 | `src/doom/d_net.c:71,93,96,257` 的单人必需回调与网络命名代码共存；`src/doom/g_game.c:2975,3068,3293` 有 demo 路径 | 保留必要编译/调度依赖；M0 不开放联机或 demo 产品能力。开发输入轨迹不是正式 demo 兼容承诺 |
| 原生跳跃 | `src/doom/g_game.c:729` 构造 `AFLAG_JUMP`；`src/doom/p_user.c:388` 根据 `critical->jump` 执行；`src/crispy.c` 控制单人有效配置 | 按用户裁定保留原生功能；原规则差分配置关闭可选物理增强，跳跃开启配置独立登记。ETN 跳跃算法不接入，姿态/光环/烟尘/音效归 M3 |

未实测项目在结果清单写“未验证”，不能写“不支持”，也不能用默认配置隐式决定是否启用增强。

### 1.1 Reference Configuration / 对照配置与观察钩子

本轮参考程序单独编译为 `crispy-doom.exe`，保留上游 `D_DoomLoop → TryRunTics → RunTic → G_Ticker`；`m0_reference.c` 只在命令构造后注入冻结输入、在每 tic 后记录状态。待测内核则由宿主调用 `m0_step`，不复用该入口生成参考期望。两端共享 `m0_observer.c` 的只读字段序列化，以避免序列化差异掩盖模拟差异；共同观察代码不提供模拟算法。

参考保留 `D_RunFrame` 的正常绘图与声音选择逻辑，仅在显示前令 `wipegamestate=gamestate`，关闭上游屏幕融化过渡：该过渡调用展示用 `M_Random`，其次数取决于显示循环。`prndindex`（玩法）、`crndindex` 和 `rndindex` 仍全部记录并逐 tic 比较，不通过删除 RNG 字段掩盖差异；内核 framebuffer 读取开启/关闭的轨迹另作验证。SUPERSEDED: 2026-11-17 实施中尝试的 `nodrawers=true` 方案已弃用，因为 `nodrawers && singletics` 同时跳过 `S_StartSound` 的 pitch RNG，会造成跳跃声音相关状态分歧。最终只关闭过渡动画，不关闭这条逻辑；这是明确冻结的对照显示配置，不代表所有上游显示模式与未来俯视方案都有相同展示 RNG。

配置禁用用户默认配置读写、额外 WAD/音乐包 autoload、网络、SDL_mixer 设备；使用软件调色板渲染、320×200、固定 35 tic/s、默认 jump=0，另设 jump=1 的原生跳跃用例。上游 `S_*` 逻辑源码仍编译保留，但 M0 实际为 `-nosound`；音频事件输出和设备接入属于 M1，不能以编译包含声音代码宣称音频已完成。

## 2. Runtime Inventory / R01–R15 调用与归属

这是完整继承边界。M0 最小链路不覆盖的模块仍归 M1，不能改名为后续新增玩法。

| ID | 实际调用/依赖 | 初始化、清理与数据归属 | M1 验证出口 |
|---|---|---|---|
| R01 启动/配置 | `D_DoomMain` → `DEH_Init`、`Z_Init`、`M_LoadDefaults`、WAD 初始化、`M_Init/R_Init/P_Init/S_Init`、`D_CheckNetGame`、`HU_Init/ST_Init`（`src/doom/d_main.c:1494,1502,1695,2392–2412`） | 包装独占启动，内核配置必须独立；禁用自动搜索/额外 autoload。argv、默认值、`crispy/critical` 属会话，不接管 ETN 入口 | 从干净目录启动，实际命令/配置与 WAD 顺序可重复 |
| R02 WAD/补丁 | `W_AddFile` → lump 表/哈希/缓存；`DEH_ParseCommandLine` 与嵌入补丁路径（见 §1） | 文件句柄、lump 缓存、DEH 可变表与字符串须纳入会话重建；只将最终资源数据复制给宿主 | 最小资源加载；通用资源覆盖与补丁专项为 M3 |
| R03 地图 | `G_DoLoadLevel` → `P_SetupLevel` → vertices/sectors/sides/lines/BLOCKMAP/nodes/REJECT/THINGS/specials（`src/doom/g_game.c:988`、`p_setup.c:1211–1380`） | 地图加载先清旧关卡标签、`P_InitThinkers`；topology、sector 和索引属于当前世界代次 | 起点/阻挡/跨 sector/节点/异常样本，原始数值逐 tic 对照 |
| R04 数值/RNG | `fixed_t=int`、`FRACBITS=16`、`TICRATE=35`；`M_ClearRandom` 清三组索引（`src/m_fixed.h:29,33`、`i_timer.h:25`、`doom/m_random.c:46–73`） | 定点、角度、RNG、thinker 顺序由内核持有。快照不能调用 RNG，也不能改变遍历顺序 | 冻结输入下原始整数/RNG/实体状态精确一致 |
| R05 玩家/碰撞 | `P_Ticker` → `P_PlayerThink`/`P_RunThinkers`；`P_MobjThinker` → `P_XYMovement/P_ZMovement`；XY → `P_TryMove/P_SlideMove`（`p_tick.c:131–155`、`p_mobj.c:163,307,587,596`） | 位置、动量、支撑、摩擦、跳跃、碰撞不委托 Godot；玩家实体引用在销毁/换图后失效 | 角落/窄道/高低差/原生跳跃；不套用 Stage0 的 525mu/s 和 32×32 求解器 |
| R06 战斗/AI/拾取 | `p_pspr.c` 状态/武器；`p_enemy.c` thinker 动作；`p_inter.c` 伤害/拾取；`p_sight.c` 可见性；`info.c` 状态表 | 与实体/thinker 生命周期一起保留；帧和 HUD 只读取结果，不反算命中 | hitscan/弹射物/爆炸/AI/伤害/拾取/钥匙/powerup 的获准样本 |
| R07 机关/高度 | `P_Ticker` → `P_UpdateSpecials/P_RespawnSpecials`（`p_tick.c:154–155`），线触发进入 `p_spec.c` 及 floor/door/plat/ceiling/light thinkers | special thinkers、sector/side 状态、按钮计时归内核；`p_floor.c:461` 读取真实 `textureheight` | use/cross/shoot、钥匙门、升降/压碎/传送/灯光及动态材质 |
| R08 流程 | 单人 `RunTic` 设置 `netcmds` 后 `G_Ticker`（`d_net.c:71–93`）；后者处理 `gameaction`、重生和 gamestate（`g_game.c:1443–1653`） | 继承 `ga_newgame/loadlevel/completed/worlddone/victory/loadgame/savegame`；不能只调用 `P_Ticker` | 新游戏、死后重开、普通/秘密出口、跨图、结束与暂停 |
| R09 结算/结束 | `G_DoCompleted` → `WI_Start`；`G_Ticker` 调 `WI_Ticker/F_Ticker`（`g_game.c:2118,1649,1653`） | 计时、统计、按键确认仍属于上游状态机；替换画面时不能空实现逻辑 | 两种出口/确认输入/图间携带/最终结束；Doom/Doom II 分别验证 |
| R10 存读档 | `G_DoSaveGame` → `P_ArchivePlayers/World/Thinkers/Specials`；`G_DoLoadGame` → 两遍扩展读取与 unarchive（`g_game.c:2476–2680`） | 保留基础/扩展载荷、对象引用修复、渲染重建；封套与额外续跑状态见 §3 | 不间断运行对照保存→读取→继续输入；禁止只比读档瞬间位置 |
| R11 逻辑渲染依赖 | `R_Init` → `R_InitData`、空间/角度/光照表等（`r_main.c:957`）；`R_PointInSubsector`（`:984`）；`R_InitTextures` → `textureheight`（`r_data.c:711,997`） | 保留被 gameplay 使用的空间查询与资源逻辑尺寸。美术替换不改贴图逻辑高度 | 按贴图高度升地板、出生 subsector、资源换皮前后规则一致 |
| R12 显示/HUD/菜单 | `D_Display` 及 `r_*` 软件渲染、`ST/HU` 显示、`M_Responder/M_Ticker` 输入/菜单 | M0 可通过 framebuffer 保留原画面；M2 替换时逐调用拆数据、逻辑与绘制。渲染不能拥有第二个模拟时钟 | 显示开关与快照频率不改变 gameplay 轨迹；菜单/失焦/退出可操作 |
| R13 声音/音乐 | `S_StartSound/S_StopSound/S_UnlinkSound`、`S_UpdateSounds`、`S_ChangeMusic`（`s_sound.c:511,532,705,871,979`）→ `i_sound` 平台后端 | 保留选择/顺序与对象解绑，平台输出可替换；一次事件不能因多次快照而重复播放 | 声音开始/停止/循环/换图/暂停、重复读取与清理；禁声探针不等于音频完成 |
| R14 平台/内存/错误 | `Z_Init/Z_Malloc/Z_Free/Z_FreeTags`（`z_zone.c:101,249,178,369`），`W_CloseFile`（`w_file.c:74`），`I_Quit/I_Error`（`i_system.c:261,288`） | 必须拆开会话终止与进程终止；内核与 Godot 之间不跨 CRT 随意释放。常规缺文件可返回，任意访问违规不能许诺恢复 | 初始化失败、反复建销、句柄/内存有界、超时/崩溃由外部监督判失败 |
| R15 demo/网络/其它游戏 | `d_net.c` 回调表同时服务单人；`d_loop.c` 持有 tic/命令调度；其它游戏独立目录 | 保留单人依赖；正式入口不接受未经支持的网络/demo/其它游戏参数，不整块删除 `d_net.c` | 单人最小链路与完整流程；扩展产品能力另立范围 |

## 3. Save Identity / 存档审计结论与 M1 实现要求

`src/doom/p_extsaveg.c:469–484` 的扩展表覆盖版本/文件名、击杀统计、总时间、闪烁灯、soundtarget、oldspecial、按钮、brain target、automap 标记、lookdir、MUSINFO；未登记 `rndindex/prndindex/crndindex`。`G_DoLoadGame` 在 `g_game.c:2536` 调用 `G_InitNew` 后恢复对象和扩展数据。由此不能直接声称“原样保留上游存档即可提供逐 tic 等价续跑”。

M0-D08 冻结为：M1 保留上游基础和扩展载荷，在 ETNDOOM 独立封套中记录 `schema`、内核 commit/补丁身份、ABI、规则配置、按加载顺序计算的资源内容哈希、游戏模式/地图，以及经实际审计需要补足的 RNG/调度状态；封套字段实现与完整恢复对照属于 M1。路径用于定位，文件内容用于身份；跨内核/跨资源/跨配置默认拒绝，不强行读取。不会将 Godot 快照当存档，也不承诺与不同端口存档互通。

写入在 tic 边界完成，临时文件成功后替换独立槽位；读档建立新世界代次，旧实体/声音/事件引用失效。M1 验收至少比较后续 350 tic 的玩家、thinkers/specials、RNG、机关与事件；仅“文件存在/能读/第一帧相同”不算完成。

## 4. Legacy Mapping / D01–D10 的版本依据

用户裁定全文保持在 [迁移表 §2.1](M0_LEGACY_MIGRATION.md#21-confirmed-migration-supplement--用户裁定补充表)。以下只补版本事实，不新增用户裁定：

| 旧项 | Crispy 版本依据 | 本次边界与后续出口 |
|---|---|---|
| D01 | `r_main.c:984` BSP subsector 查询，`p_map.c:489` 位置检查 | 继承内核；M2 表面拾取不得反写位置/通行 |
| D02 | `m_fixed.h:29,33` 16.16 定点；`p_mobj.c:307` Z 移动 | 原始整数用于比较，Godot 显示单向转换；M1 高度/负坐标对照 |
| D03 | `p_map.c:565,809` TryMove/SlideMove；`p_mobj.c:163` XY 分步 | 不接旧连续扫掠/多约束求解；M1 台阶/滑动/跨线测试 |
| D04 | `p_user.c:388`、`g_game.c:729`、`crispy.c` 的 jump/critical 路径 | 原生跳跃按其配置保留，M1 继承验证；ETN 表现 B2/M3 |
| D05 | `p_map.c:489,565` 开口/阻挡，`r_*` 画面 | 碰撞属内核，M2 可见性独立；不改变主项仍是既有建议的来源级别 |
| D06 | `p_pspr.c/p_map.c/p_mobj.c/p_inter.c` | 保留 Source Port 攻击；俯视朝向输入 B1/M2，ETN 命中增量 B2/M3 |
| D07 | `p_setup.c/p_extnodes.c/p_blockmap.c`，见 §1 | 完整保留内核解析和索引；Linux Doom 1.10 只具较早经典格式能力，不能代替 Crispy 行为证据 |
| D08 | `w_wad.c` 有序资源/查找，`d_main.c` 补丁流程 | 整项 B2/M3；M0 仅必要获准资源链与证据身份 |
| D09 | `p_setup.c:491,546` 装 THINGS/缺起点诊断；`p_mobj.c:879,962` 生成人物/地图对象 | 不继续“其它 THINGS 不生成”的旧阶段限制；M1 flags/实体/异常起点 |
| D10 | `p_mobj.c:645,879` 生成与 sector/floor 关联 | 出生由内核执行；M1 低净空/重叠/跨 sector，不承诺旧完整占地算法 |

## 5. Delivery / 授权与对应源码交付边界

Crispy `COPYING.md` 包含 GPLv2 正文，`src/doom/d_net.c:5–9` 等主体文件声明 GPL-2.0-or-later。正式分发必须保留实际纳入文件的版权/许可，并提供与二进制匹配的内核源码、修改补丁、桥接源码、构建与安装脚本、依赖锁和必要生成说明；只附上游首页链接不足以表达本项目的对应源码。SDL、GDExtension 绑定和编译运行库以实际构建清单逐项记录，不能按“使用了 Godot”推定其版本或许可文件已入包。

当前 ETN 根 `README.md:136` 明确“仓库目前未附带项目级 LICENSE”，且美术/音乐有独立权利方。用户此前的“完全开源”是条件性评估，不能被写成已选 GPLv3 或已有兼容授权。本次本地实现、构建和测试可继续；G1 的正式组合发布授权仍须根据实际组合范围与权利人许可关闭，不能因 DLL/PCK 分开自动判通过。本轮不替用户写项目许可证、不公开上传二进制、商业 WAD 或本体素材。

**用户确认（2026-11-17，来源：user）**：G1 授权“尚未确定”，明确标为待裁定。技术链路与本地回归成果可以独立交付，G1 以及依赖它的“M0 全部门槛已闭合”结论不能标通过。

详细待确认条目见 [LEARNINGS 的授权边界](../../LEARNINGS.md)。M4 发布前还须核对实际交付 ZIP 的每项依赖、许可证和源码归档哈希；源码可复现与可合法发布分别给出结论。
