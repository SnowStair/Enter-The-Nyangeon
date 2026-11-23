# M0 Selection and Build / 已定选型与构建边界

> Date / 日期：2026-11-18。
> Status / 状态：首个内核 Crispy Doom 已确认；2026-11-17 已实现并构建内核/参考程序与真实宿主桥接，固定身份和本地复现见 §9。完整探针结论见验收记录；G1 正式组合发布授权按用户答复保留待裁定。
> Source / 来源：user（确认 Crispy Doom 7.2 为首个内核及有限端口接入原则）、code（仓库、固定版本源码与路线评估）；M0 宿主运行已验证且人工验收于 2026-11-18 通过；完整 M1 能力仍待验证。
> Navigation / 导航：[M0 总览](README.md)；运行证据要求见[探针与验收](M0_PROBES_AND_ACCEPTANCE.md)。

## 1. Selection / 已确认内核与其它端口定位

**首个内核已确认为 Crispy Doom 7.2，无需重新选择。** 最终接入 GZDoom/UZDoom，并保留切换至已移植端口的能力；首版按 Crispy 实际需求实现，不强求完全公共接口或通用适配器。版本身份见 §8.1，构建锁与真实宿主结果见 §9，M0 已于 2026-11-18 完成人工验收。SUPERSEDED: 此前“构建与宿主验收仍待完成”的状态。

> History / 历史：SUPERSEDED: 2026-11-17，原“Crispy 与 DSDA 同列首轮主候选、GZDoom/UZDoom 仅在其它路线失败后补评”的角色表已被用户的首版选型与长期方向取代。原四候选的取舍依据保留在 §8.2；不再作为当前待执行的选型任务。

| 对象 | 当前定位 | 后续工作或使用边界 |
|---|---|---|
| Crispy Doom 7.2 | 已确认的首个内核 | 完成实际版本的兼容边界、完整流程、库化依赖、构建与 ETN 接入验证 |
| GZDoom/UZDoom 系 | 已确认的最终方向 | 后续确定具体分支/版本并接入；与 Crispy 的复用和差异按实际需求处理 |
| Chocolate Doom | 原版行为对照；未选为首个内核 | 可用于研究 Vanilla 行为，不新增一套正式移植任务 |
| Boom / 原始 PrBoom | 已比较但未采用的首版方案 | 保留选型依据；仅出现具体障碍或需求变化时重新评估 |
| DSDA-Doom / 其它 PrBoom 系分支 | 历史研究与条件性备选 | 非当前首轮开发对象，不把分支能力混算为原始 PrBoom 能力 |
| 原始 linuxdoom-1.10 | 行为/依赖结构参照 | 不承担当前正式内核角色 |
| IsoDoom | 模拟与表现分层参照 | 不将其 C#/.NET 运行要求视为当前 ETN 普通 PCK 已具备的能力 |

Crispy 本地源码 `E:/crispy-doom` 的已记录 HEAD 为 `35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2`，对应 `crispy-doom-7.2-1-g35b49519`；7.2 tag 为 `fdeabe4c23a833534b70aa84a22f1685aae7125d`。两者不能混记，实际构建所用 commit 与补丁须进入 §4 构建锁，不自动追踪 `master`/`latest`。DSDA 的 `eb8eb98ec97d378b5d58936de820c0a6610b912c` 仅为[路线评估 §8](../DOOM_CORE_ROUTE_EVALUATION.md)中的历史资料锚点，不是选定依赖。上述源码身份均不代表已成功构建。

## 2. Evidence / 证据等级与实施审计表

每项标记 `文档声明 / 固定版本源码核对 / 参考构建实测 / ETN 实测 / 未知`，附 URL 或 `file:line`、commit、命令、结果路径。未知不能填“不支持”，上游可运行不能填“ETN 已支持”。

| 维度 | 已选 Crispy 内核必须核实的问题 | 类型 |
|---|---|---|
| 近期兼容 | Doom/Doom II 游戏模式与 IWAD 识别、limit-removing 的具体限制、配置/可选增强对行为的影响 | 硬条件 |
| 游戏流程 | 难度、死亡重开、普通/秘密出口、跨图、结算/结束、暂停、存读档是否可保留 | 硬条件 |
| 库化切入 | 主循环、命令生成、全局变量、资源初始化、`exit/abort`、反复建销的最小改动范围 | 硬条件 |
| 宿主接入 | Win64 构建、C/C++ ABI、GDExtension 时序、依赖 DLL 与实际 ETN 可达性 | 硬条件 |
| 资源/格式 | 见 §3，逐格式、逐补丁类型核实 | 硬条件与范围选择 |
| 授权与来源 | 代码/依赖/媒体的许可证，组合分发及对应源码交付方案 | 硬条件 |
| 升级成本 | 上游维护、修改点数量与位置、补丁能否独立重放、未来 Boom/MBF21 的更换代价 | 取舍项 |
| 性能/调试 | 批量取状态成本、日志能力、固定输入、可重置性、目标机器测量 | 取舍项 |

当前按已选 Crispy 完成上述审计；未知项须补证据，不以未知项打零分，也不因构建或宿主验证尚未完成而将内核名称重新标为待选。若出现实际阻塞，记录影响与替代方案后再评审，不自行撤销已确认选型。

已确认选择及未选方案的依据见 §8；后续补齐实际构建身份、尚存风险及重新评审触发条件。不能只写“更轻量”或“更强大”，也不以文件数推算工期。

## 3. Compatibility Matrix / 格式与兼容设置逐项核实

> Revision / 修订（2026-11-16，来源：user）：按 [迁移裁定](M0_LEGACY_MIGRATION.md) §2.1、§3，M0 仅加载用户明确给定并允许的 WAD；2026-11-17 已获准 `DOOM2.WAD + MAP01.wad` 用于自制图自动回归及人工验证；单独 `DOOM2.WAD` 主要用于人工验证，自动回归仅验证正确加载。完整路径见[探针清单 §4.1](M0_PROBES_AND_ACCEPTANCE.md#41-approved-wads--当前获准加载清单2026-11-17)，不得自动发现或回退到其它资源。下表用于已选 Crispy 的能力审计；D08 的通用 PWAD/其它资源能力为 B2/M3，不要求在 M0 实测所有资源/补丁行，也不以样本要求扩大许可清单。D07 地图行为由选定 Source Port 自带解析器决定，Linux Doom 的有限能力单独记录。

| 特征行 | 需要记录的行为与样本 |
|---|---|
| IWAD / 游戏模式 | Doom、Doom II；具体版本、episode/map 命名、任务包另列；不以一个 DOOM2.WAD 代表全部 |
| 地图基础 | 经典 Doom 格式；缺失/损坏 lump、索引错误的处理；Hexen 格式/UDMF 单列为首版范围外 |
| 节点 | 经典 NODES、扩展/压缩节点、GL 节点分别列；有无回退、运行时构建及所需依赖 |
| 加速数据 | BLOCKMAP/REJECT 的使用、校验、修复/重建行为及配置；不机械套用旧 D07 |
| 补丁 | 外部 DeHackEd、WAD 内 DEHACKED、BEX、加载顺序、修改状态表/文本/资源名分别核实 |
| 资源覆盖 | 一个 IWAD + 有序 PWAD、重名 lump、贴图表/PNAMES/patch/flat/sprite/声音的解析顺序 |
| 地图选择/元数据 | 同名地图组选择、起始图、秘密出口、地图序列；MAPINFO/UMAPINFO 等不默认支持 |
| 特殊制图 | 自引用 sector、深水/透明门等按具体样本拆分内核与俯视表现结论 |
| 扩展规则 | Boom、MBF、MBF21 分别记录上游能力；首版是否开放另定，不由链接进库自动开放 |
| demo / 网络 | 开发用固定输入工具不等于原版 demo 兼容；单人验证不等于联机支持 |

每行至少填：`上游能力/证据 → 本项目计划支持或排除 → 有效配置 → 验证样本 → 当前结果 → 失败呈现方式`。无法可靠预检的格式要写“加载时诊断/检测有限”，不能保证所有不支持 WAD 都能提前识别。

**固定源码补证（2026-11-17）**：[M0_SOURCE_AUDIT.md](M0_SOURCE_AUDIT.md) §1 已逐项列出上述能力、开放范围、错误路径及后续验证归属。该表证据等级统一为“固定版本源码核对”，不将尚未运行的格式/补丁项目标为 ETN 已支持；M0 的真实配置、样本与结果仍按探针证据记录。

配置身份记录游戏模式、难度、兼容级别/选项、自动瞄准、可选增强、随机初始化方法及补丁顺序。随机初态不一定是一个 seed；必须按实际 Crispy 版本的 RNG 表/索引/流定义记录。上游默认配置不可作为未记录的隐含条件。

## 4. Host Fingerprint / 真实宿主与构建锁

建议把以下字段作为一份构建锁记录；目录与文件名由 M0 执行时确定，以下不是已有脚本：

| 记录组 | 必填字段 |
|---|---|
| ETN | exe 相对交付目录位置与 SHA-256、应用版本、实际引擎版本/构建、架构、发布/调试特征、加载器版本/源码基线 |
| 内核 | 仓库 URL、tag（可选）、完整 commit、源包 SHA-256、补丁顺序/哈希、许可证位置 |
| 工具链 | 编译器/链接器/Windows SDK/CMake 或实际构建工具版本、目标架构、优化与数值相关选项、CRT 策略 |
| Godot 接口 | `godot-cpp` 版本/commit、API JSON/生成来源及哈希、扩展最低版本、入口符号、debug/release 库选择 |
| 依赖 | 每项版本/哈希、静态或动态链接、构建来源、是否进入发布包、是否为必需或可禁用功能 |
| 命令/产物 | 从干净目录开始的命令、环境要求、输出路径、产物哈希、日志与构建返回码 |

`project.godot` 的 feature 标记、开发机 Godot 路径、exe 文件名均不能单独证明发布版的真实引擎/API。先通过运行时探针读取，再验证扩展 API；不得为了适配内核而悄悄重导出本体。

本仓库正式源码及固定版本依赖应可独立取得并构建；选择 vendoring 或固定版本拉取时说明离线复现、上游补丁和授权文件如何管理。`E:/DOOMSourceCode`、`E:/isodoom`、`E:/DOOM/UZDoom-trunk` 只作研究参照，不能出现在正式构建依赖中。测试日志/二进制/商业 WAD 按仓库约定不提交。

## 5. Packaging / 安装、加载与更新链

本轮核对到的事实：

- `script/mod_installer.gd:4,59,85` 校验 ZIP 布局并提取条目；不是只提取 PCK 的白名单。`:48,51` 通过目录重命名交换旧/新安装。
- `script/mod_manager.gd:18,19` 当前限制为 2000 条目、256 MB 累计解压；`:194` 处理安装根，`:582` 挂载 PCK，`:1059` 延迟创建 entry。边界检查须以当前源码为准。
- `etndoom_mod/build_stage0.py:23,28,50` 当前构建仅收集既定资源，并只把 manifest/PCK 放入 ZIP。它没有实现原生库打包链。

**推荐先验证的布局**：ZIP 根含 `mod.json`、PCK、物理 `native/<平台>/<构建身份>/` 库与描述文件、许可证材料。PCK 内只含模组命名空间资源及引导脚本；正式 Mod ID 在 M0-D03 锁定，不提前复用 Stage0 ID 覆盖既有测试。

必须由 P2 回答以下问题，回答前布局仅为提案：

1. entry 怎样取得本次实际安装根，区分 `user://mods/` 与 exe 邻接 `mods/`；不能写死开发机路径或靠当前工作目录。
2. `.gdextension` 描述文件如何定位物理 DLL 及其传递依赖，中文/空格路径是否成功；PCK 虚拟路径不能未经验证就当作 OS 可加载路径。
3. 运行期显式加载扩展的初始化级别、返回状态和类注册是否可用；先运行纯 GDScript 引导，再加载引用原生类型的消费者，避免解析/`preload` 时类尚未注册。
4. 缺库、缺依赖、架构/API 不匹配时能否留在可操作菜单；错误应包含阶段、路径、预期与实际身份。
5. 更新/卸载时已加载 DLL 的文件占用与安装目录交换怎样交互。库留驻进程与会话可重建是两件事。

P5 若证明安装器目录交换受占用影响，先评估模组可控制的、按构建身份隔离的加载副本/缓存方案（须定义校验、旧版本清理与卸载行为）；或明确退出后更新的可执行流程。不能把“重启就行”当作已证明安装事务可完成，更不能默认修改安装器。缓存方案也须检查用户可见卸载后的残留和下一次清理时机。

## 6. Licensing and Delivery / 授权与交付审计

**当前裁定状态（2026-11-17，来源：user）**：用户明确答复 G1 授权“尚未确定”，保留待裁定；本轮继续本地实现/验证，不替用户选许可证，不把技术通过等同于正式组合发布许可已经闭合。

按实际构建 commit 逐项记录内核、依赖库、构建工具随包部分、声音/字体等媒体的实际授权及分发义务。GPL 内核与宿主组合发布的方案须明确；“DLL/PCK 分开”不自动解决组合发布问题，当前文档不作授权已满足的结论。此项来自现有路线 §6 的约束，是选型可交付性的一部分。

交付计划需说明对应源码、修改补丁、构建说明、版权/许可证如何随版本提供；不捆绑商业 IWAD，不从本体发布包抽取资源另行分发。若授权资料或 ETN 许可条件不足，记录缺项与可行替代，不能直接标记 G1 通过。

## 7. Decision Output / 当前选择与构建记录

SUPERSEDED: 2026-11-17，实施前的待填写模板已由以下真实记录替代，历史选型过程保留在§8。

```text
选型状态：已确认 Crispy Doom 7.2（user）；M0 技术自动验证完成，G1 授权待裁定
7.2 tag commit：fdeabe4c23a833534b70aa84a22f1685aae7125d
已记录本地 HEAD：35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2（7.2-1；差异见 §8.1）
实际构建 commit / 补丁身份：同上述 HEAD；build_native.py 与 native/build/build-lock.json
参考构建 / ETN 宿主 / 工具链身份：§9；真实 ETN/Godot 4.7.2 x64，GCC 16.2.0
首版支持范围及显式排除：两种获准 WAD，MAP01；关闭音频/网络，完整流程及资源API归M1
选择理由与未选方案：§8.2；可运行证据见探针§9
原生库安装、加载、更新、卸载方案：新Mod ID + 物理hash缓存 + 每会话core DLL；P2/P5已验证
授权与对应源码交付方案：§6、§9；G1按用户答复尚未确定/待裁定
P0–P5结果：tests/m0_results/final_delivery_20261117/delivery.json
影响 M1 的旧规则裁定：迁移表§2.1，固定源码审计§4
重新选型触发条件：具体宿主/重置阻塞或近期强制Boom需求；不因远期功能多自行换内核
```

实际命令必须在执行后记录；不得编造 Crispy 的 CMake 选项、可用构建脚本或探针通过日志。

## 8. First Port Recommendation / 首版四候选评估（2026-11-16）

本节保留选型依据与来源；当前结论为 Crispy Doom 7.2 已确认，非待推荐状态。

### 8.1 Conclusion / 结论与状态

> Confirmation / 版本确认（2026-11-17，来源：user）：试验内核已确认为 **Crispy Doom 7.2**，无需重新选择。SUPERSEDED: 此前仅记“内核名称确认、7.2 为建议”的不完整状态。以下 7.2 tag 与本地 HEAD 是不同源码身份；实施时明确记录实际使用的 commit 及相对 tag 补丁，不能将本地 `7.2-1` 标作纯 7.2 tag，本轮不切换或修改源码。构建锁与运行验收仍待完成。

> Decision / 裁定（2026-11-16，来源：user）：**确认 Crispy Doom 为首个内核**。用户提供工作区源码 `E:/crispy-doom`；本轮只读核实工作区干净，origin 为 `https://github.com/fabiangreffrath/crispy-doom.git`，HEAD 为 `35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2`，`git describe` 为 `crispy-doom-7.2-1-g35b49519`。相对 7.2 tag 仅多一项 `src/hexen/p_extnodes.c` 的指针初始化修复（`Hexen: initialize poly pointer in ZDBSP (#1439)`）。以用户提供的当前源码继续 M0 审计，未切回 tag；此记录为本地源码身份，不表示完整构建锁或运行验收已通过。正式依赖纳入与独立构建方案仍按 §4 收口，不将本地绝对路径硬编码进交付构建。

> History / 历史：SUPERSEDED: 2026-11-16–17，原“建议采用 Crispy、7.2 为建议基线、选型未确认”的结论已由用户确认取代；当前正文直接表达确认状态，历史比较依据保留。

**首版内核与试验版本已确认为 Crispy Doom 7.2。** 官方 release 为 `crispy-doom-7.2`（2026-10-12），此前通过 GitHub API 核对其 commit 为 `fdeabe4c23a833534b70aa84a22f1685aae7125d`。已完成文档与局部源码核对，尚未编译、加载 WAD 或在 ETN 运行；M0-D01 的内核/试验版本选择已确认，实际构建锁及运行 Gate 仍待完成。

用户已明确长期目标为 GZDoom/UZDoom 和既有端口切换；具体最终分支/版本、切换交互及各端口支持范围尚待后续确定。已确认方向为 **Crispy → 接入 GZDoom/UZDoom，保留 Crispy 后端**，不要求依次移植四个候选。兼容顺序仍为原版 → limit-removing → 后续扩展；高级格式支持应另行验收。

### 8.2 Comparison / 与 M0–M1 的匹配

| 候选 | 已核对的上游定位/能力 | 对本项目的判断 |
|---|---|---|
| Chocolate Doom | 3.1.1；仍维护；保留 Vanilla 的行为、bug 与静态限制；现代跨平台 C/SDL 实现 | 能承载原版完整流程，适合作原版对照；但 limit-removing 需另做或再换内核。最终还要保留后端时，这一步会增加长期维护对象，首选价值不及 Crispy |
| Crispy Doom | 7.2；仍维护；基于 Chocolate，定位 limit-removing Vanilla；原生可选跳跃、垂直观察/瞄准；支持部分 Boom 来源扩展，不支持完整 Boom/ZDoom 地图 | 与近期范围最贴合；继承经典完整流程，又减少自行解除原版限制的工作。已确认为首个内核；宿主适配成本仍需实测 |
| Boom | 2.02 历史项目；已停止开发；原版面向 DOS/DJGPP；解除限制并提供广义线型、传送带、深水等扩展 | 玩法范围足够，但现代 Win64/宿主平台适配会承担额外工作；首版暂不需要完整 Boom 扩展，未采用原始 Boom 为开发基线 |
| PrBoom | 原始 2.5.0；已停止开发；跨平台 SDL；Doom/Boom/MBF 和兼容级别 | 若近期要求 Boom/MBF，可优先于原始 Boom；本轮范围下需处理更广的兼容配置且基线陈旧，保留为条件性备选。不能把 PrBoom+/DSDA 的 MBF21 等能力算到它名下 |

本表不是实测工期排序。PrBoom 的 libretro 分支有库化先例，但属于独立分支；帧/音频回调不等于已具备 ETN 所需的地图、实体和流程接口，不能据此宣称原始 PrBoom 可直接嵌入。即使采用 PrBoom 系，未来接入 GZDoom/UZDoom 仍需核对并处理宿主集成差异，不要求预建通用适配器。

### 8.3 Code Evidence / Crispy 的固定版本源码依据

以下锚点均基于 7.2 tag 的 commit `fdeabe4c23a833534b70aa84a22f1685aae7125d`，可从 [固定版本源码](https://github.com/fabiangreffrath/crispy-doom/tree/fdeabe4c23a833534b70aa84a22f1685aae7125d)定位：

- `README.md:14,24,32,57`：limit-removing Vanilla 定位；明确不支持广义 linedef/sector、DECORATE/MAPINFO。支持少数 ANIMATED/SWITCHES/MBF sky transfer 不等于支持完整 Boom/MBF。
- `README.md:38,55`、`src/doom/g_game.c:729`、`src/doom/p_user.c:388`：已有可选跳跃，输入使用 `cmd->arti` 的 `AFLAG_JUMP`，玩法读取 `critical->jump`。按用户迁移裁定保留原生实现并验证；不移植旧 ETN 跳跃，也不把 Crispy 的跳跃参数当成 UZDoom 参数。建议原规则对照配置关闭可选物理增强，另设启用跳跃的继承验证配置；两种配置均须明确记录。
- `src/doom/g_game.c:1443,2476,2588`：存在完整 `G_Ticker`、读档和存档入口；M1 必须保留这些流程及其依赖，不只搬运 `P_Ticker`。
- `src/doom/d_main.c:554,590,2486`：当前主循环仍由 `TryRunTics` 驱动，`D_DoomLoop` 不返回；`src/doom/g_game.c:2557` 读档仍调用渲染初始化。这证明它不是现成的可重入库，固定步进、平台服务、退出错误及反复建销仍需改造。
- `CMakeLists.txt:36,37,40,58,61,67,73`：已有 CMake、SDL2，以及 SDL2_net/SDL2_mixer 开关与其它可选依赖探测；这些是构建切入点，不表示关闭音频后已满足 M1，也不证明能直接生成 ETN 可加载 DLL。

建议先用 Doom/Doom II 运行目标建立参考构建；不为 M0 增加 Heretic/Hexen/Strife 的支持承诺。最小显示可评估复用软件帧缓冲至 Godot 纹理，以验证真实操作与流程；是否便宜须由探针决定，最终俯视仍为 M2。

### 8.4 Backend Strategy / 为长期切换保留什么

**修订（2026-11-16，来源：user）**：支持的端口数量有限，可能仅 Crispy 与 GZDoom/UZDoom；移植 Crispy 时不过度追求完全公共接口及各端口的通用适配器。SUPERSEDED: 此前“首版预建统一接口、能力模型和各端口独立适配器”的建议。M0–M1 优先实现直接、够用的 Crispy 接入，允许专用字段与调用；以后接入第二个内核时再提取实际重复部分或局部调整。

建议将切换定义为退出当前会话后选择另一端口，重新开始或读取该端口兼容的存档；**不预设跨端口热切换当前世界、存档互通或同一 WAD 全端口可运行**。这是技术边界建议，用户只确认了可切换目标，尚未裁定切换粒度。原生 DLL 可驻留，状态必须分开；错误、音频、输入、配置路径及全局状态不得串用。

当前仍需明确输入/tic、状态读取、内存寿命、错误、会话清理及存档身份；这些是 Crispy 宿主集成的实际要求。数值转换与接口扩展按实际需求处理，不提前建设覆盖 GZDoom/UZDoom 的通用数据模型。详细边界见 [桥接 §1.1](M0_BRIDGE_CONTRACT.md#11-backends--多端口边界建议)。

### 8.5 Validation and Sources / 后续冻结条件与资料边界

M0 仍需完成固定版本参考构建、真实 ETN 原生加载、获准 WAD 的真实步进/可操作运行、退出重入与错误路径探针；M1 验证战斗、机关、普通/秘密出口、死亡重开、暂停、跨图及存读档。2026-11-17 WAD 允许清单已给定，见探针 §4.1；本轮仅更新文档，未加载资源。若 Crispy 的宿主/重置障碍使适配成本明显失衡，或 Boom 成为近期硬要求，再重评备选；不能只为“将来功能更多”扩张 M0。

检索方式：读取用户给定四个 DoomWiki 页面；查询官方 GitHub `releases/latest`、tag 对应 commit、固定 tag 下 README/CMake/三份玩法源码，以及最近更新的少量开放 issues。未使用截图，结论不依赖视觉效果；未运行 `um kb`（当前 PATH 无该命令），未安装工具。

- [Chocolate Doom](https://doomwiki.org/wiki/Chocolate_Doom)、[Crispy Doom](https://doomwiki.org/wiki/Crispy_Doom)、[Boom](https://doomwiki.org/wiki/Boom)、[PrBoom](https://doomwiki.org/wiki/PrBoom)：本轮已读，社区二手资料，用于定位、维护状态与历史区分；不替代固定源码或宿主验证。
- [Crispy 7.2 官方发行](https://github.com/fabiangreffrath/crispy-doom/releases/tag/crispy-doom-7.2)、[固定 README](https://github.com/fabiangreffrath/crispy-doom/blob/fdeabe4c23a833534b70aa84a22f1685aae7125d/README.md)：一手资料；发行、功能边界及源码锚点已核对。
- [官方 issue #1438](https://github.com/fabiangreffrath/crispy-doom/issues/1438)：DeHackEd flag 与击杀计数冲突的开放报告，作为未来补丁覆盖回归线索；本轮未复现，不据此认定所有 WAD 受影响或候选不可用。其余少量 issue 检查不构成全量缺陷审计。

普通 HTTP 读取 DoomWiki 返回 403，随后浏览器正常访问成功；raw GitHub 连接重置后通过官方 API 成功读取对应源码。PrBoom 的现代库化成本、四候选之间的实际性能差异，以及 GZDoom/UZDoom 的最终嵌入方案尚无实测结论。

## 9. Implemented Build Lock / 实际构建与交付边界（2026-11-17）

Source / 来源：code | test。SUPERSEDED: 上文 §7、§8 的“尚未构建/本轮仅文档”描述属于实施前记录；当前身份与命令以本节及机器生成锁为准。内核版本/继承/长期端口方向未改变。

| 项目 | 固定身份或记录位置 |
|---|---|
| 内核源包 | 本仓库 `etndoom_mod/vendor/crispy-doom-35b49519.tar.gz`；SHA-256 `3e15a65dbb3602447465dd543eef8892c834e7ab026149fa3ded92caa8096b46`；commit `35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2` |
| 补丁与内核封装 | `etndoom_mod/build_native.py:prepare_source` 按明确锚点重放；`native/m0_core.c`、`m0_observer.c`、`m0_memory.*`；补丁驱动与全部源码 SHA 记录在锁中 |
| 编译器/链接器 | GCC 16.2.0，MinGW-W64 x86_64-ucrt-posix-seh（Brecht Sanders r1）；GNU ld 2.47.20260726；CMake 4.4.2、Ninja 1.13.2；Windows UCRT，不使用 MSVC/Windows SDK 构建路线 |
| 编译选项 | 内核 Release、C99、`-fwrapv -fno-strict-aliasing -static-libgcc`；桥接 C11/O2；完整命令由 CMake 日志和锁记录，不以文档替代实际参数 |
| 唯一非系统动态依赖 | SDL2 2.32.10，官方 MinGW x64 包 SHA `83a5d74012311edc3c0d40ea6faecbe57ad692aa033fa5dc273cc937e3938ff2`；DLL SHA `53e8fa7e9ed43c30bd650c39396f0d9d2067d2fff0b926c9433b75202592e4aa`；zlib 许可 |
| 未启用依赖 | SDL2_net/SDL2_mixer、PNG/FluidSynth/libsamplerate 均关闭；不宣称完成音频设备、网络或压缩节点扩展能力 |
| Godot 接口 | `gdextension/gdextension_interface.h`，SHA `640b48188708ba0016f8d7ace9e0e1d3279a41fa1226c59ff3193b15538bd254`，从 4.7.2 导出；Godot C ABI，**未使用 godot-cpp**；入口 `etndoom_m0_init`，SCENE 级注册 |
| 真实宿主 | `release/pak/Enter The Nyangeon v0.5.2.0-test.exe`，SHA `aaf8b276d6b5dea55f83960608436368817bd6b7656170759a19f78506754c1d`；实际 Godot `4.7.2-stable official ed1daf0bf001b61586d9930840f2f1394092c079`，x86_64、非 debug/editor |
| 内核/参考锁 | `etndoom_mod/native/build/build-lock.json`、`native/reference_build/build-lock.json`；记录来源、工具、完整命令、返回码日志、实际产物/补丁/源码哈希 |
| 模组包锁 | `etndoom_mod/build/m0/build_lock.json`；PCK/ZIP/桥接DLL/内核/SDL 哈希、Godot 构建工具、资源白名单与 source_files |

标准构建命令：

```powershell
py -3 etndoom_mod/build_native.py --all
py -3 etndoom_mod/build_m0.py
```

源码随仓库锁定；SDL 开发包按 `vendor/dependencies.json` 的固定 URL 和哈希放入 `native/downloads/`，构建会强制校验。解压源码/依赖和生成物在本仓库的忽略目录内，不访问 `E:/crispy-doom` 或旧 ETN 仓库。独立空构建验证已执行：

```powershell
py -3 etndoom_mod/build_native.py --all --build-root tests/m0_clean_native_20261117
```

证据 `tests/m0_clean_native_20261117/verification/summary.json`：新目录内 core/reference 均构建成功，初态和 350 tic 精确一致，销毁后登记分配数为 0。PE 时间戳等使不同重建的二进制 SHA 可能不同；本轮证明固定源码可重建并行为一致，不宣称字节可复现构建。每次测试必须对应当次锁，不能沿用上次产物哈希。

安装 ZIP 仅有模组命名空间 PCK、manifest、三份原生 DLL 与许可；使用新 Mod ID `etndoom_m0`，不覆盖 Stage0。本地路径 `user://mods/etndoom_m0/native/` 是安装源，实际从 `user://etndoom_m0/native/<manifest_sha256>/` 内容缓存加载；每次逐文件验证 SHA，更新成功后在新进程加载新 build，并清理非当前旧缓存。卸载不运行 entry，最后缓存通过退出后的本地显式清理工具处理。

现有许可证原文保存在 `vendor/Crispy-Doom-COPYING.md`、`vendor/SDL2-LICENSE.txt` 和 Godot 接口头；实际 ZIP 必须带这些材料。对应源码交付方案为固定 Crispy 源包 + 实际补丁驱动 + native/bridge/GDScript 源码 + 构建/安装说明 + dependencies/build locks，后续公开版本按最终组合范围补足宿主对应源码及授权。G1 已由用户明确“尚未确定／待裁定”；本轮可交付本地技术验证成果，不能标注正式发布授权已通过。
