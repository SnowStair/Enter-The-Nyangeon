# Stage 0 Implementation / 阶段 0 实施记录

> Scope / 范围：§1–§5 保留 0.1/0.2 历史实施与验收证据；§6 记录 0.3 当前实现、自动结果及人工验收；现行结论为 §6.6，Gate D 已完成。
> Source / 来源：code、test、用户于 2026-10-26 确认的 0.1/0.2 人工验收，以及 2026-10-30 的 0.3 人工反馈和最终接受条件。
> Date / 日期：2026-10-30（0.3 高度与自然投影比例复核通过，Gate D 完成；历史证据保留）

## 1. Source and Runtime / 源码与运行路径

开发源为 `E:/ETN_DOOM/etndoom_mod/`；Mod ID `etndoom_stage0`，版本 `0.1.0`，API 1。本机 Godot 输入路径为 `D:/Creating/Godot/Godot_v4.7.2-stable_win64_console.exe`（`4.7.2.stable.official.ed1daf0bf`）；监督器会优先选择同目录的 `Godot_v4.7.2-stable_win64.exe`，直接监督实际进程 PID，避免 console 转发程序留下子进程。物理为 Rapier2D `0.8.37`，渲染为 Vulkan / Forward+。

| 文件                                        | 职责与证据                                                                                  |
| ----------------------------------------- | -------------------------------------------------------------------------------------- |
| `etndoom_mod/mod.json`                    | 独立测试 Mod 的 manifest；不覆盖本体文件、不依赖 COOP。                                                  |
| `etndoom_mod/entry/stage0_entry.gd:8`     | 只解析准确的 Stage0 参数；无效/重复不接管；延迟通过 SceneTree 切场景，不注册场景门控。                                  |
| `etndoom_mod/stage0/stage0_wad.gd:15`     | 每份 WAD 一次读入及目录边界校验；后加载同名资源优先，地图按 MAP01 标记后的有序结构读取。                                     |
| `etndoom_mod/stage0/stage0_wad.gd:56`     | 限定 PLAYPAL 0、FLOOR0_1、CEIL1_1 格式校验、PNAMES/TEXTURE1/STARTAN2 四 patch 解码；缺失或不支持时报资源名与原因。 |
| `etndoom_mod/stage0/stage0.gd:73`         | 原 Momoi 实例入树前验证参数、断开旧根回调、同步释放玩法子树与相机、移除玩法组，并替换同一个 CharacterBody2D 根脚本。                 |
| `etndoom_mod/stage0/stage0_player.gd:16`  | 单个物理回调更新每轴速度、调用一次 move_and_slide、切换 idle/run、按水平输入更新朝向并更新光环锚点。                         |
| `etndoom_mod/stage0/stage0.gd:131`        | 从同一 bounds 派生一个 StaticBody2D、四个矩形形状；内沿与边界一致，厚度 32 向外，横墙覆盖四角。                           |
| `etndoom_mod/stage0/stage0_map_view.gd:8` | 地面按原尺寸平铺，nearest 过滤；16 单位墙带仅作俯视调试显示，向外绘制，不作为碰撞真源。                                      |
| `etndoom_mod/stage0/stage0.tscn`          | 重建 D05 的 10 个节点及原滚动背景资源、glow 配置，不运行 main.gd。                                           |
| `etndoom_mod/build_stage0.py`             | 用 SDK 的 pack_mod.gd 在最小隔离工程打 PCK，再生成契约 ZIP；明确白名单排除 IWAD、测试与本体文件。                       |

运行时 MAP01 来自 PCK 内 `res://mods/etndoom_stage0/wad/MAP01.wad`；外部 IWAD 仍从 `E:/ETN_DOOM/etndoom_mod/wad/DOOM2.WAD` 读取，不打包。源 WAD 均未修改。坐标保持 `(x,-y)` 与 1:1 单位，逻辑范围 `Rect2(-640,-512,1024,1024)`，出生点 `(-128,0)`。

Momoi 保留 7 个节点：同一物理根、根圆、Graphics、AnimatedSprite2D、HaloRoot、Halo、Shadow。提取速度 155、SPEED_TIME 0.2 后释放 Stats；实际根圆半径 7、偏移 `(0,-6)`。0.1 的根形状禁用、layer/mask 均为 0，无边界静态体；0.2 根 layer 为 1、mask 为 256，墙 layer 为 256。测试相机是场景自有的独立节点，zoom `(1,1)`、无偏移或平滑，在玩家更新后精确居中；背景跟随视野铺底，不会在 0.1 远离地图后露空。

## 2. Commands / 实际命令

构建：

```powershell
python E:\ETN_DOOM\etndoom_mod\build_stage0.py --godot "D:\Creating\Godot\Godot_v4.7.2-stable_win64_console.exe"
```

实际产物为 `E:/ETN_DOOM/etndoom_mod/build/etndoom_stage0.zip` 与 `.pck`。构建每次从当前源码生成，避免旧 PCK 冒充新实现。

完整自动回归（已实测）：

```powershell
& "C:\Users\雪楼梯_IceStair\AppData\Local\Programs\Python\Python313\python.exe" E:\ETN_DOOM\tests\run_stage0_checks.py
```

所用 Python 依赖为 numpy、Pillow、`omgifol==0.5.1`；后者安装于 `tests/.stage0_deps/`，只用于本地独立参考图。依赖安装命令见 `etndoom_mod/README.md`。

Stage0.2 从出生点到地图边缘的固定物理帧测算：

```powershell
& "C:\Users\雪楼梯_IceStair\AppData\Local\Programs\Python\Python313\python.exe" E:\ETN_DOOM\tests\run_stage0_measurement.py --godot "D:\Creating\Godot\Godot_v4.7.2-stable_win64_console.exe"
```

该入口重新构建并隔离安装真实 Stage0 Mod，通过 Mod entry 切入 0.2；在 60Hz 物理帧中从静止向东、向西移动，记录首次与四边静态碰撞的接触帧、位置、速度及碰撞余量。输出 `edge_measurement.json`、`result.json` 和逐帧运行日志保存在 `tests/stage0_results/<时间戳>/edge_measurement/`。

隔离人工入口（待用户实际操作）：

```powershell
python E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.1
python E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.2
```

人工入口同样先探测隔离 user://，走真实 ZIP 安装与票据重启，然后运行正常主场景和 Mod entry，**不加载回归移动驱动**。关闭窗口结束。两模式已通过 `--quit-after 120` 的正常启动烟测，证据为 `manual_entry_smoke.json`；该可选参数仅让 Godot 自动退出，不代表用户操作验收。原本体 `project.godot` 的 godot_ai 本地状态未修改；源码副本在 `tests/.stage0_fixture/project/` 中排除缺失的 `_mcp_game_helper` 配置，并独立导入资源，避免旧缓存或编辑器副作用影响原文件。

如需在已导出游戏中人工验收，在 MOD 页导入上面的 ZIP、启用并退出后执行：

```powershell
& "E:\ETN_DOOM\release\pak\Enter The Nyangeon v0.5.2.0-test.exe" -- --stage0=0.1
& "E:\ETN_DOOM\release\pak\Enter The Nyangeon v0.5.2.0-test.exe" -- --stage0=0.2
```

导出版命令供用户后续操作；本次没有安装到玩家真实目录，也没有将这些导出版命令宣称为已通过的自动用例。

## 3. Regression Evidence / 自动回归证据

完整结果：`E:/ETN_DOOM/tests/stage0_results/20261024_final/summary.json`，`ok=true`、`complete_matrix=true`，8 个用例全部通过，进程断言合计 21,147 条。安装阶段另检查 ZIP 成功与不热挂载，退出码 75、随机 nonce 票据相符后，使用同一环境重启。

| 类别 | 结果与证据 |
|---|---|
| 无参数、无效值、空值、缺值、同值重复、混合重复 | 各 7 条断言通过；实际 entry 已运行，正常场景未被接管，诊断与预期一致。各目录保留 run.log、command.json、result.json。 |
| 0.1 | `stage01/result.json`，2,496 条断言通过；四边严格越界后停留，速度/朝向/归一化/每轴加减速正确，无玩法组或旧玩法信号订阅。 |
| 0.2 | `stage02/result.json`，18,609 条断言通过；四边真实查询/接触、四角稳定、切向滑动和离墙通过，最大每帧位移受连续性断言限制。 |
| 坏数据与资源覆盖 | 截断 WAD、非矩形顶点、坏 flat 明确报错；附加 PLAYPAL/FLOOR0_1 的 PWAD 覆盖 IWAD，地图仍从有序结构读取。原文件不变。 |
| 独立素材参考 | `references/` 由 omgifol 从同一 IWAD 导出；记录工具版本、两份 WAD SHA256 与四个 patch 名。两种解码素材与参考逐像素完全一致。 |
| 完整视口截图 | 0.1 初始与四边越界共 5 张；0.2 初始、四边停止与四角共 9 张，均为完整 1280×720 PNG。`contact_sheet.png` 为便于查看的额外缩略总览。 |
| 场景像素 | `stage01/pixels.json` 与 `stage02/pixels.json` 均 `ok=true`；地图、墙带与角色合计 98,471 个采样通过。每张角色明亮内部采样 127–128 点，全部匹配。 |
| 反例 | `pixel_negative_control/pixels.json` 中 `ok=false` 是**预期结果**：空白完整截图同时被地图和角色像素断言拒绝；监督器确认该失败符合预期后才放行正例。 |
| 跨模式一致性 | `mode_consistency.json` 为 `ok=true`；初始位置/形状/相机/观察条件一致，两个素材图和初始完整视口图均逐像素完全相同。 |

### 3.1 Unit Measurement / 单位换算实测（2026-10-26）

最终证据：`tests/stage0_results/20261026_124953/edge_measurement/edge_measurement.json`；隔离安装、实际 PCK entry、首次墙体碰撞、每采样一次物理更新及碰墙前离散模型核对共 49 条断言通过。完整保存东、西各 201 条物理采样，未改变 Mod 的移动代码或参数。

东、西向均在第 201 个物理帧首次碰墙，首接触帧对应 `201/60 = 3.350s` **游戏物理时间**；不含进程启动、导入或场景加载时间。只用计时估算时必须采用实际的“每帧先更新速度、再移动”模型：

```text
dt = 1 / 60
v_n = min(155, v_(n-1) + 775 * dt), v_0 = 0
D_n = sum(v_i * dt, i=1..n)          # 没有墙时的理论根位移
D_200 = 502.458333，D_201 = 505.041667
k = logical_units_per_mu
(D_200 + 7) / 512 < k <= (D_201 + 7) / 512
```

计时提供约 `0.995036–1.000081` 的换算区间，包含 `k=1`；约 `0.006` 逻辑单位的实际接触余量远小于一个满速物理帧的 `2.583333` 逻辑单位。碰撞圆的水平偏移为 `0`，因此向东/西运动只需补回根圆半径 `7`，纵向偏移 `(0,-6)` 不影响这两向测量。

接触位置另作交叉核验：玩家根位移分别为 `504.99405`、`504.99359` 个逻辑单位，按 `(实际根位移 + 7) / 512` 得到平均 `k ≈ 0.999988`。结合该位置对末帧插值可估计 `3.34969s`，但此数值不属于纯计时独立测量。当前实现及本次决策采用精确坐标映射 `1 logical unit = 1 WAD map unit = 1mu`，约 `0.000012` 的差值来自接触余量与浮点误差，不另设换算系数。用户据此确认 V03 后续直接使用 `mu` 表示逻辑长度、速度和加速度。

新增测量分支后，原有 Stage0.2 定向回归也已通过：`tests/stage0_results/20261026_124542/summary.json`，18,609 条断言和 9 张完整视口截图的像素校验通过。

## 4. Pixel Conditions / 像素观察条件

视口采用本体设计分辨率 640×360、实际截图 1280×720；保存该帧相机中心、zoom、完整 stretch×canvas 变换、玩家根/形状中心、sprite 锚点、atlas 与帧区域。每次在 `RenderingServer.frame_post_draw` 捕获，固定角色动画至第 0 帧后恢复播放。

glow 正常启用，强度 0.3；CRT 为隔离存档默认关闭；F3 未开启，正常启动场景已由 entry 切走。背景 shader 的 TIME 区不参与静态颜色比较，背景本身仍启用。机器从 HDR 视口保存的原始 RGBH 数据生成 sRGB PNG，避免直接保存线性数据导致颜色过暗；`*_linear.png` 与 `.readback` 同时保留供诊断。

地图每隔 7 个截图像素采样，地图内核/墙带避开边缘 3 世界单位、角色附近 glow 区，以及距离 texel 切换线不足 0.02 世界单位的舍入歧义区。地图 RGB 每通道容差 5；角色从**本体原始 momoi.png** 按 atlas 区域与朝向计算，采不透明明亮内部像素（至少 30 点），RGB 容差 12、匹配率至少 92%，保留 HDR 描边与 glow。失败记录坐标、世界映射、预期/实际像素；不以截图存在替代像素通过。

实际物理断言独立于截图：根圆不得穿透内侧超过 0.15 世界单位；接触距离容差 0.3；角点持续顶住的漂移不得超过 0.15。这些容差不改变逻辑矩形或视觉位置。

## 5. Acceptance Status / 验收状态

代码、自动回归、完整截图与机器像素验证已完成；14 张截图也已逐帧查看，地图内外、Momoi、墙带、四角与 glow 显示符合记录。用户于 2026-10-26 确认亲自进行的 0.1/0.2 人工验收均符合预期，覆盖开发细化文档 §4.2、§5.2。该验收依据为用户明确确认；本记录不额外推断未明确说明的操作设备。

因此 Gate A、Gate B、Gate C 均已完成。Gate B 对应 0.1，Gate C 对应 0.2，二者自动、完整视口截图像素验证和用户人工验收均通过。Gate D 仍未完成：在本节 2026-10-26 历史记录时，0.3 的设计、实现及验收尚属后续工作；2026-10-30 的后续实现与最终验收见 §6（本段保留当时状态）。阶段 0.1/0.2 的验收结论不因此回退。未将 0.3 视作已验收，也未运行返回菜单或退出恢复。

## 6. Stage 0.3 Implementation / 阶段 0.3 实施（2026-10-30）

### 6.1 Runtime / 运行实现

Mod 版本为 `0.3.0`，构建输出仍是 `etndoom_mod/build/etndoom_stage0.zip`。共用 entry 增加 0.3 参数校验与入树前属性传递；`stage0/` 原有功能文件未修改，0.1/0.2 历史回归本轮未重跑。新模块如下：

| 文件 | 实际职责 |
|---|---|
| `stage03/coordinates.gd` | 世界映射 `(u,h,v)`、double 解析正反变换、屏幕方向逆投影、显式高度平面射线接口 |
| `stage03/wad.gd` | 五张固定 WAD 的真实字段、BSP/seg 地面裁切、PLAYPAL/flat/patch/texture 解码；仅复用旧读取器的底层容器/patch 函数 |
| `stage03/player.gd` | 同一 Momoi 物理根的唯一移动者；`32×32mu`、`525mu/s`、`1720mu/s²`，分别提供根/碰撞中心/脚底/后续阴影锚点接口 |
| `stage03/map_view.gd` | floor、one-sided middle、双面 upper/lower/masked middle；WAD 派生 UV、pegging、nearest+mipmap、实际尺寸 repeat、alpha cutout 深度 |
| `stage03/actor_view.gd` | 原 Momoi 主体可见高度标定 `56mu`，光环按局部锚点随主体等比缩放（修正说明见 §6.5）；绕竖直轴朝相机，脚底对齐；不渲染阴影 |
| `stage03/stage03.gd` / `.tscn` | 入树前隔离原玩法、矩形外框物理、D05 容器/滚动背景/glow、单相机、取景与 near/far |

物理与显示分离：内部 WAD 墙段和 sector 高差只产生表现几何，不增加内墙阻挡、高台/楼梯、玩家高度变化或 3D 物理。单 sidedef 实体墙双面可见，双 sidedef 的两个面各自背面剔除，既能看到近侧外墙又避免共面竞争；不使用墙厚、顶面、深度偏移或角色优先绘制。角色裁切阈值 `0.5` 是实施基线；用户完成首轮人工验证后反馈高度问题，修正已获确认，比例专项结论见 §6.6。

解析参照 `project/unproject` 使用 `PackedFloat64Array`，纯变换容差 `1e-5mu`；实际物理/渲染按 Godot float32 向量执行，窗口几何与射线往返按 `≤1px` 检查。角色保持原帧 duration，不把动画帧包围盒当作碰撞体。

### 6.2 Commands and Calibration / 命令与实机参数

```powershell
py -3 E:\ETN_DOOM\tests\run_stage03_checks.py
py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3
py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3 --map MAP01_BackWall.wad
py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3 --map MAP01_FrontWall.wad
py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3 --map MAP01_Texture.wad --overview
```

验收实际游戏参数为 `--stage0=0.3 --stage0-collision=on`。附加开发选项 `--stage0-map=<五张固定文件名之一>`、`--stage0-size=<640..1600 的 10mu 步长>`、`--stage0-view=follow|overview` 只用于 0.3。默认地图 MAP01、默认跟随 `size=960mu`；F2 切换同一相机的跟随/整图，`+` / `-` 按 `10mu` 缩放；人工监督器对应 `--map`、`--size`、`--overview`。非法/缺值/重复/跨阶段混用不接管正常启动；`off` 未作为验收用例。

固定 1600×900 设计画面、KEEP_HEIGHT；相机 Euler `(-45°,45°,0°)`。逻辑状态不含相机参数；跟随中心世界上移 `28mu`，玩家脚底仍为 `h=0`。本机 Godot 4.7.2 / Vulkan Forward+ / NVIDIA RTX 4060 Laptop GPU、Rapier2D 0.8.37。四图外框及最大墙高相同，因此本轮得到相同的以下区间（完整浮点值见各图截图 JSON）：

| 配置 | size（mu） | 相机距取景中心（mu） | d_min / d_max（mu） | margin（mu） | near / far（mu） |
|---|---:|---:|---|---:|---|
| 跟随，覆盖允许的全部跟随范围 | 默认 960；允许 640..1600 | 1128.840762 | 50.130190 / 2156.639712 | 42.130190 | 8 / 2198.769902 |
| overview，完整几何与角色范围 | 四图均 1400 | 568.799835 | 30.290192 / 1144.799774 | 22.290192 | 8 / 1167.089966 |

### 6.3 Independent Regression / 独立回归

初始四图矩阵位置（高度修正前历史证据，现行结果见 §6.5）：`tests/stage0_results/20261030_122100/stage03/on/`。监督器真实构建 ZIP、隔离 user://、调用 ModManager 安装、核对退出码 75/随机重启票据，再在同一隔离目录通过本体主场景与实际 PCK entry 启动。0.3 独立结果不替代 0.1/0.2 历史证据。常规命令会准备/导入隔离工程；本次末轮的 `--skip-import` 仅复用已完成导入的同一缓存，不跳过构建、安装、重启、entry 或运行检查。

`summary.json` 的 `ok=true`、`complete_matrix=true`：四图加三组非法实际入口共 7 个用例，730 条运行断言、647,102 个有效场景像素采样通过，五组合成反例全部拒绝。四图原素材完整 RGBA 比对通过；60 张截图已通过像素检查并生成逐图 `contact_sheet.png` 检视，四图整图对照为 `overview_comparison.png`。

- 四图分别保存固定哈希、原始 linedef/sidedef/sector 字段、源素材、墙段参数、相机/逻辑锚点、逐帧运动与碰撞结果。原始 WAD、IWAD 均未修改，IWAD 未打包。
- 每图 15 张完整截图：overview、出生点、地图中心、四边、四角、四边滑动；共 60 张。`*_linear.png` 与 `.readback` 保留原始 HDR 读回，展示 PNG 显式转换 sRGB。
- 独立 Python 从 WAD 二进制读取字段；omgifol 0.5.1 从同一 IWAD 解码素材并逐像素核对。地面像素参照直接对 sector 边界做奇偶射线判断，与运行时 BSP 裁切实现独立；墙面按原字段重新推导 section/UV。
- 像素参照使用固定 V01 相机基底的数学射线，与地面/墙/竖直角色求交，按深度与 `alpha<0.5` 丢弃计算可见像素。角色期望直接读取原主体/光环 PNG 和场景局部参数。投影图 RGB 每通道容差 6；不比较时变背景，但不屏蔽主要墙面、角色和透明孔洞。仅排除几何边缘 `2×size/900 mu`、各参与 mip 层 texel 边界 `0.02 texel` 及 alpha 阈值附近的不稳定采样。
- 本机纹理采样符合 mip 间线性混合与纹理足迹长轴 LOD：floor 的 footprint 为 `√2×size/900`，本夹具轴向墙面为 `2×size/900`；实际 LOD 保存在各图 `pixels.json`。这是采样参照条件，逻辑单位仍为 1mu。
- 自动覆盖八方向、半幅模拟输入、起步/制动/反向逐帧向量加速度、四边四角实际接触、滑动/离墙、640/960/1600 视野及 1280×720 窗口下的逻辑轨迹/接触不变、无原玩法与 MapBounds 接管。Front/Back 对照验证孔洞透视与角色局部遮挡。
- 五组**合成完整截图反例**保留同一元数据/独立期望：空白、错误正上方图、缺少压缩、镜像纹理方向及锚点偏移；必须全部被像素断言拒绝。它们是检测器有效性验证，不冒充另一轮真实错误相机运行。

失败证据保留在较早的 `20261030_115354`、`115556`、`120129` 等目录：包括窗口配置覆盖、旧测试输入丢失模拟强度、透明孔洞白色 RGB 污染 mipmap、仅用 seg 端点凸包造成 Texture 图地面缺片。均已按复现修正，没有覆盖失败图或降低原始素材逐像素要求。

### 6.4 Manual Acceptance and Handoff / 人工验收与交接

用户于 2026-10-30 明确已完成人工验证，反馈唯一问题是 Momoi 主体明显过矮，并新增 HTest。已按 §6.5 修正；用户随后确认高度正常，并允许忽略竖直 billboard 的自然投影缩短。§6.6 已验证此条件，Gate D 完成，依据包括用户确认和专项证据。返回菜单/重新进入和 `collision=off` 不属于本轮测试。

最终不带回归驱动的正常入口烟测：`py -3 tests/run_stage0_manual.py --stage 0.3 --quit-after 120`；本地证据 `tests/stage0_manual/0.3_25c9cbfa/smoke.json` 为 `ok=true`、`errors=[]`、`manual_acceptance=false`。这项证明实际入口可正常启动/退出，不证明用户手感验收。场景退出时主动释放本体自定义鼠标纹理，避免 RenderingServer 销毁后的 RID 报错；既有的退出资源计数警告仍由本地共用日志分类器精确区分。

阶段 1 可接收 `coordinates.gd` 的空间职责/变换接口、当前逻辑移动和锚点、五图 WAD 字段/采样实现及独立证据。D01 仍负责正式地图格式，D02/D05 仍负责真实高度与玩法墙体语义；不能将本次 BSP 静态夹具子集或表现高差声明为完整 Doom sector 玩法支持。提交与推送均未执行，tests/ 及构建产物仍只在本地保留。

全部 tests/ 内容只在本地使用，未提交；本次没有执行 git add、git commit 或 git push，也未改动本体功能代码、玩家真实存档或调试中的 mobile_hotfix。

### 6.5 Body Height Correction / 主体高度修正与 HTest（2026-10-30）

来源：user（首轮人工验证完成，仅指出 Momoi 视觉高度约 33mu，并新增 50mu sector 夹具）、code（源帧与缩放测量）、test（真实运行与独立像素参照）。本节是高度修正后的现行证据；§6.3 保留初始四图历史结果。

根因是将主体与光环的合成图整体缩到 56mu。待机第 0 帧主体可见范围为 `(22,15,21,34)px`，合成图为 `27×53px`，旧主体高度 `56×34/53=35.9245mu`。现以每帧主体 `alpha>=0.5` 的可见高度标定 56mu，主体底边中心落在 h=0；光环保持原局部变换并随主体等比缩放，待机整张合成几何约 87.2941mu。翻转围绕主体脚底，相机 near/far 使用各帧含光环的完整范围。旧“整张图 56mu”口径由用户反馈修正，不通过改变相机、深度或逻辑碰撞补偿。

新增 `MAP01_HTest.wad` 已加入构建、entry、场景和人工/自动入口白名单；原 WAD 字节未改。外框 `1024×1024mu`，逻辑 `u=[-640,384]`、`v=[-512,512]`，出生点 `(-128,0)`，高台位于 `v<-64`，floor=50mu。外框因 sector 分界被拆成 6 条单面 linedef；读取器改为验证每边有向区间的完整连续覆盖，缺口、重复重叠、反向仍拒绝。物理仍只有矩形外框，玩家可实际移动穿入高台，脚底保持 h=0。

最终命令与证据：

```powershell
py -3 E:\ETN_DOOM\tests\run_stage03_checks.py --skip-import --output E:\ETN_DOOM\tests\stage0_results\height_final_20261030\stage03\on
py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3 --map MAP01_HTest.wad --quit-after 120
```

常规完整回归可省略 `--skip-import`；本次复用已正常导入的隔离缓存，仍执行真实构建、安装、退出 75/随机票据、重启与 PCK entry。所有监督器串行运行。`height_final_20261030/stage03/on/summary.json`：`ok=true`、`complete_matrix=true`，五图加三组非法入口共 8 用例，938 条运行断言、1,371,307 个稳定像素采样通过。原四图各 15 张截图，HTest 为 34 张，共 94 张完整 1600×900 截图；各图另存 `contact_sheet.png` 供检视。五组合成反例继续全部被拒绝。

HTest 通过真实输入移动到高台内部约 `(-128,-204.2)`，再记录三档 size=640/960/1600 及两动画各四帧、左右翻转的 16 组合。独立参照从原 PNG/场景抽取主体掩码，区分主体与光环，要求 50mu 以上主体像素匹配、下部被高台遮挡，不能以仅光环可见通过：

| size | 露出且匹配的主体像素 | 露出光环像素 | 被遮挡的主体采样 |
|---|---:|---:|---:|
| 640 | 117 | 358 | 1719 |
| 960 | 32 | 138 | 777 |
| 1600 | 11 | 53 | 280 |

16 组动画/朝向各匹配 91–117 个主体像素，50mu 以下可见主体采样均为 0。修复前真实截图保留在 `height_before_render/stage03/on/`；三档相机用同一新判据均被拒绝，主体匹配数为 0，证据为 `height_negative_controls.json`。`height_comparison.png` 为 size=960 同一位置的修复前后最近邻放大对照，`height_frames.png` 为动画抽样图，不替代完整截图。

角色素材校验比较全部 alpha 与非零 alpha 像素的精确 RGBA；Godot 原贴图导入会扩散 alpha=0 像素的 RGB，不把这些不可见颜色当作高度/外观判据。角色无 mipmap；原 WAD 素材仍逐像素比较完整 RGBA。运行像素参照保留原容差，并把前方角色透明 texel 边界的 0.03texel 不稳定带同样排除：否则参考射线落在透明一侧时，会错误地把后方地面当作稳定样本。跑动帧的失败采样均位于精确整数 texel 边界，未扩大边界阈值。

原四图的 near/far 仍符合 §6.2；HTest 跟随 distance=1128.520762、near=8、far=2182.129902，overview size=1400、distance=568.479835、near=8、far=1150.449966。正常入口烟测见 `tests/stage0_manual/0.3_2bd0ecc5/smoke.json`，`ok=true`、`errors=[]`、`manual_acceptance=false`。

人工复验入口：

```powershell
py -3 E:\ETN_DOOM\tests\run_stage0_manual.py --stage 0.3 --map MAP01_HTest.wad
```

从出生点向屏幕右上移动穿入高台深处，确认能看到 Momoi 的主体头部，而非只有光环；可用 `+` 放大、`-` 缩小。用户首轮其他人工结果已记录；本节完成时高度仍待复验，随后用户接受与比例核验见 §6.6。构建包已更新；未暂存、提交或推送，tests/ 证据与构建产物仅本地保留。

### 6.6 Sprite Proportions and Acceptance / 精灵比例核验与验收完成（2026-10-30）

用户明确“缩放后高度没有问题”，并提出用 Momoi 原素材区分贴图缩放失真与竖直 billboard 的自然观察效果；若仅由后者导致变扁，则可忽略。此条件经以下独立对照成立，现有效果保留，功能代码、材质、相机、角色尺寸和地图均未修改。

从 `scenes/player/momoi/momoi.tscn` 的 SpriteFrames/AtlasTexture 配置提取 `sprites/player/momoi/momoi.png` 中待机与跑动各四帧，保存源区域、原始 64×64 帧、裁去透明边的主体及原 PNG SHA-256。光环独立合成，主体比例检查不包含光环。待机首帧主体为 `21×34px`；世界几何保持原宽高比，主体高 56mu；在 pitch=45° 正交相机下，竖直平面投影纵向每 texel 为横向的 `cos45=1/√2≈0.7071`。它是自然投影缩短，非贴图缩放错误，也非透视近大远小。

本地新增 `tests/stage03_sprite_proportions.py`，接入 `stage03_reference.py` 和正常 0.3 回归。仅对 MAP01 增加 18 张无遮挡截图：size=640 下两动画四帧双朝向，共 16 张；再加 size=960/1600 的待机首帧。逐项检查原合成纹理 alpha/可见颜色、世界每 texel 等比、竖直方向、屏幕 cos45 比例，以及原素材经过独立二维投影后的逐像素 RGB。比较不使用运行时 quad 尺寸生成期望颜色；沿用 0.03texel 取整边界排除与通道误差 6 上限。

```powershell
py -3 E:\ETN_DOOM\tests\run_stage03_checks.py --maps MAP01.wad --smoke --skip-import --output E:\ETN_DOOM\tests\stage0_results\sprite_proportions_20261030\stage03\on
```

真实构建、ZIP 安装、退出 75/票据、隔离重启和 PCK entry 均通过。`summary.json` 为 `ok=true`、`complete_matrix=false`：本轮仅为新增比例专项，不冒充完整五图重跑；既有完整五图证据仍为 §6.5。20 张完整 1600×900 截图（overview、spawn、18 张比例专项）、126 条运行断言、495,340 个场景像素通过。比例报告为 `MAP01/sprite_proportions/report.json`：

| 检查 | 结果 |
|---|---|
| 世界纵/横每 texel 比 | 0.999999911..1.000000126，等比 |
| 屏幕纵/横每 texel 比 | 0.707106718..0.707106870，符合 cos45 |
| 主体原图独立投影颜色 | 18 组、30,604 个稳定采样，最大 RGB 误差 0 |
| 完全面向相机的假设（纵向因子 1） | 18 组均不匹配 |
| 额外纵向压缩的假设（因子 0.5） | 18 组均不匹配 |

待机首帧在 size=640 下的连续投影尺寸为约 `48.640×55.685px`；若完全面向相机则为 `48.640×78.750px`。自然参照与真实截图一致；差异正是竖直平面与视线的夹角。对照图为 `MAP01/sprite_proportions/comparison.png`（原图正视、自然投影参照、真实截图），原始帧与实际截图裁片也保存在该目录。功能源码/场景和五张 PWAD 的 18 个文件哈希与专项开始前一致，见上级 `runtime_before.json`。

验收结论：用户此前完成其他人工验证，本轮明确接受高度，并允许忽略已证实的自然投影缩短；结合 §6.5 五图完整回归、§6.6 新增比例专项以及 §6.4 阶段 1 接口/边界交接记录，**Gate D 于 2026-10-30 完成，阶段 0.3 验收通过**。保留竖直 billboard，不额外拉伸、不切换模式。测试文件与证据仅本地保留，未暂存、提交或推送；不自动开始阶段 1。

### 6.7 Stage 0 Sign-off / 阶段 0 最终确认（2026-10-30）

用户明确确认“阶段 0 完成”，并授权提交至 `E:\ETN_DOOM` 的独立 Git 仓库。Gate A–D 全部完成；§6.5–§6.6 的完整五图结果、人工高度确认、自然投影比例专项与阶段 1 交接边界构成最终依据。源码、用户自制 HTest 与文档纳入本次提交；本地回归脚本/证据、构建产物和商业 IWAD 保持 Git 排除。推送仍由用户执行。
