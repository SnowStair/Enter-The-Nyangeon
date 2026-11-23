# IsoDoom Sector Wall Rendering / isodoom Sector 墙体渲染参考

> Status / 状态：实现参考，不是 ETNDOOM 对完整 DOOM sector 兼容的承诺。当前 0.3 的墙面决策仅适用于 WAD linedef 对应的墙面本身，不实现墙体延展、闭合、厚度或顶面；已锁定当前渲染子集的纹理采样参数。本文件记录未来 DOOM sector 地图读取可借鉴的规则与配置边界。
> Source / 来源：`E:\isodoom\src\Map\WallSections.cs`、`WallPieces.cs`、`TextureWrap.cs`、`E:\isodoom\src\Render\LevelMesh.cs`、`WallCaps.cs`、`DoorLids.cs`、`Cutaway.cs`、`E:\isodoom\src\Game\Settings.cs`；与 `E:\ETN_DOOM\etndoom_mod\wad` 下阶段 0 四张回归 WAD 对照。
> Update / 补充来源：用户于 2026-10-28 确认阶段 0 的墙体几何范围，并采纳推荐的纹理密度、过滤、mipmap 与回绕方案；用户于 2026-10-29 确认 `MAP01.wad`、`MAP01_BackWall.wad`、`MAP01_FrontWall.wad`、`MAP01_Texture.wad` 均属于阶段 0 回归输入，且 Texture 夹具覆盖 `textureoffset` 与 `Upper/Lower Unpegged`；具体决策见 §5。
> Date / 日期：2026-10-29

## 1. What It Renders / 渲染对象

isodoom 不把每条 linedef 一律转成一张固定高度的墙。它先从 map 的 line、side、front/back sector 与纹理定义推导每个 side 实际需要显示的 wall section，再将 floor triangle、wall quad、补面几何放入 3D mesh，由正交相机、深度测试和 shader 统一显示。这个 sector 规则层比 Godot 的 3D mesh、材质 atlas、shader 或相机布置更适合 ETNDOOM 未来复用。

- 单面 linedef 的 middle texture 从 front sector 的 floor 延展到 ceiling，作为完整 wall section。
- 双面 linedef 不等同于实体墙：sector 高度差产生 upper / lower wall section；若配置 middle texture，则在两个 sector 的开口区间产生 masked middle，并按透明像素裁切。
- wall texture slot 为 `-` 时不绘制该 section；地图几何、阻挡标志与纹理显示是不同数据，不能以纹理缺失推断可通行。
- line 的方向与 side 决定 sidedef 的 `V1/V2`；反向 side 反转墙面延展方向。Wall section 的 U 使用 `textureoffset + 沿 sidedef 的距离`，V 使用 `texture_top - z`，并在 sector 高度变化时依据 linedef pegging 标志选择锚点。
- 普通 solid section 按规则纵向重复；masked middle 只画一次纹理高度并裁在开口内，不纵向平铺。

核心实现锚点：`WallSections.cs:98-102, 316-362`、`LevelMesh.cs:1268-1310, 1551-1557`。这些代码表达 vanilla Doom 的 wall span / texture pegging 语义，不意味着 ETNDOOM 必须重用相同的 C# 类或 mesh 结构。

## 2. Texture Coordinates / 纹理坐标

地面 flat 的 UV 以 map 平面位置采样，而不是把 flat 图像先拉伸成投影菱形。isodoom 的 floor vertex 保持 map X/Y 位置，并使用 `(x, -y)` 作为 UV；经固定相机投影后，方形 flat 才随地面几何成为菱形。墙面 texture offset、方向和上下锚点则独立于地面 UV。

`--level-tiling=vanilla|size` 选择两种 wall wrap：

| 模式 | 含义 |
|---|---|
| `vanilla`（默认） | 模拟原版列/行回绕：水平宽度采用不大于实际宽度的最高 2 次幂掩码，纵向按 Doom 的 128 行规则回绕；这与任意纹理尺寸取模不同。 |
| `size` | 按纹理真实宽、高取模回绕；更接近常见 source port 的直观尺寸回绕。 |

两者可能在非 2 次幂纹理、垂直超过 128 行的 wall 上产生不同像素。这个选项只改变渲染采样，不修改 WAD、高度或碰撞。依据：`TextureWrap.cs:4-20, 32-48`、`LevelScene.cs:2992-2993`。

## 3. Closing Gaps / 闭合与补面

### Wall caps

isodoom 的 `wall_caps` 默认开启。它不是把墙面纹理延长到更高，而是对满足条件的单面 linedef，在墙后方的 void 中生成一小段水平厚度/顶面，使有厚度的墙体边缘可见并在角落收口。

- 默认伸入 void `16mu`；角点采用有限斜接，最多延展 `4 × thickness`。
- 只处理有 front sector、middle texture 且无 `ML_TWOSIDED` 的墙；墙体围成的“小岛”包围宽高不得超过 `128mu`。
- 是否按相机朝向绘制会检查 wall face；背向相机的 cap 不单独浮现。

对应 `WallCaps.cs:77-84, 128-138, 161, 263-264` 与设置 `gameplay/wall_caps` / `--level-wall-caps`。这是一项有限显示补面算法，不等于把整张地图统一膨胀 16mu，也不参与逻辑阻挡。

### Door lids

`door_lids` 默认开启。它识别 floor 下存在相邻 sector 的薄 sector，在邻接 ceiling 的最低高度为该区域补一块水平 lid，以闭合门楣、窗上方或低矮通道的箱体；不是常规的“每个房间都画 ceiling”。

- 普通薄 sector 的厚度上限为 `32mu`；加载时 ceiling 不高于 floor 的闭合门可放宽到 `64mu`。
- lid 高度取相邻 sector 的最低 ceiling；仅在本 sector ceiling 低于该高度时显示。
- 门打开时，lid 仍可作为 lintel 顶面保留；sky ceiling 与不满足邻接/厚度条件的 sector 不补 lid。

对应 `DoorLids.cs:32-62, 203-230` 与 `gameplay/door_lids` / `--level-door-lids`。阈值属于 isodoom 为可读性制定的呈现策略，不是 DOOM 通行高度常量。

## 4. Visibility and Wall Options / 遮挡及墙面选项

| 设置 | isodoom 行为 | ETNDOOM 当前 0.3 的建议边界 |
|---|---|---|
| `gameplay/cutaway`：`cut/dither/off` | 玩家附近的墙按切除、抖动或完整显示处理；默认 `cut`。半径默认 `80mu`，高度默认 `32mu`。 | 阶段 0 明确不实现、不配置、不验收；不属于 V06 待裁定内容。若阶段 0 之后出现可读性需求，再另行评估。 |
| `gameplay/cutaway_things`、`cutaway_doors`、`cutaway_cap` | 分别控制被墙切除的物件、门是否保持完整、切面是否显示 floor cap。 | 依赖 cutaway 本身，0.3 不引入。 |
| `gameplay/wall_caps` | 开关单面墙后方的有限顶面补厚。 | 阶段 0 不生成 cap、闭合、加厚或顶面；仅绘制 linedef 对应的墙面。 |
| `gameplay/door_lids` | 开关薄 sector/门楣上方的 lid。 | 阶段 0 不生成 lid；Back/Front 双 sector 夹具也不启用此补面策略。 |
| `gameplay/upper_walls`：`doors/all` | 选择只画 door/lintel 等 upper，或画全部 sector ceiling 差形成的 upper wall；默认 `doors`。 | 0.3 须读取 Back/Front 的双面线与 sector 高差；按实际纹理槽/section 规则输出，不引入此可选过滤策略。 |
| `gameplay/masked_back`：`mirror/off` | 控制单面 masked middle 从背面可见时是否镜像绘制；默认 `mirror`。 | 当前 `STARTAN2` 为不透明 middle，不适用。 |
| `gameplay/height_cues`：`shade/edges/both/off` | 以面部明暗或边线提示高度差；默认 `shade`。 | 0.3 只有单一 floor/ceiling，不需要高度差 cue。 |
| `sprites/hidden`：`depth/upright` | 以实际深度或保持 upright 的 sprite 几何判断被墙遮挡；默认 `depth`。`sprites/wall_pull` 可将 sprite 朝镜头轻拉以减少穿墙。 | 阶段 0 不考虑 `upright hiding` 与 `wall pull`；Momoi 竖直外观仍按 V06 自然深度遮挡，不作可读性补偿。 |

设置定义见 `Settings.cs:104-109, 119-125, 132-133`，运行时更新见 `LevelScene.Settings.cs:621-664, 689-695`。cutaway 的样式、半径、物件与 door 行为分别可调；不应把所有选项合并成单个“墙透明”开关。

SUPERSEDED: 2026-10-29 旧“0.3 没有双面线与 sector 高差”仅适用于最简 `MAP01.wad`，不能覆盖 Back/Front 夹具；已按固定回归输入修正。

## 5. ETNDOOM Application / 对 ETNDOOM 的取舍

### 0.3 已确认的子集与未来边界

- **用户已确认**：地面 flat 按逻辑/WAD 平面坐标采样，UV 不随投影几何预先压成菱形；地面与墙面均按原纹理尺寸 `1 texel/mu`，nearest 过滤、启用 mipmap、不启用各向异性过滤，超出源纹理边界按实际宽高 repeat。`FLOOR0_1` 的重复周期为 `64mu`，`STARTAN2` 为 `128mu`。
- **用户已确认的墙体几何边界**：阶段 0 只绘制 WAD linedef 对应的墙面本身，不额外生成墙体延展、端部闭合、厚度或顶面，也不绘制常规 sector ceiling。当前 MAP01 单面墙表面的竖直区间来自 front sector floor `0mu` 到 ceiling `128mu`；它仅是渲染范围，不代表通行高度。
- **用户已确认的 WAD 贴图字段范围**：Front/Back 各自引用一个 sidedef；sidedef 的 upper/middle/lower texture、统一 `textureoffset`/`rowoffset` 和 sector index，以及 linedef 的 `Double Sided`、`Upper Unpegged`、`Lower Unpegged`，构成阶段 0 的贴图输入。运行时按 vanilla Doom 派生 U/V，不添加 WAD 不支持的独立 U/V、旋转、缩放或 skew。
- **阶段 0 的四张固定回归输入**：`MAP01.wad` 覆盖最简 one-sided middle；`MAP01_BackWall.wad` 与 `MAP01_FrontWall.wad` 覆盖双 sector、双面透明 `MIDGRATE` 墙和自然深度遮挡；`MAP01_Texture.wad` 覆盖 one-sided middle 的贴图属性字段及 `Upper/Lower Unpegged` flags。四张图必须从真实 WAD 字段驱动并分别保存解析/像素结果。
- `MAP01_Texture.wad` 当前使用 `SLADPOIS` middle，并以 flags `17`（`ML_BLOCKING | ML_DONTPEGBOTTOM`）和 flags `9`（`ML_BLOCKING | ML_DONTPEGTOP`）覆盖两类 pegging 输入；其中 one-sided middle 的垂直锚点由 `Lower Unpegged` 决定，`Upper Unpegged` 必须被正确读取但不能错误套用于 middle。

MAP01 事实来自 `etndoom_mod/wad/MAP01.wad`，当前读取器校验位于 `etndoom_mod/stage0/stage0_wad.gd:102-136`；资源尺寸/组成见 `ETNDOOM/ModdingDocs/Stage0/STAGE_0_DEVELOPMENT_DETAIL.md:209-210`。

### 留给未来 sector 阶段

- 四张阶段 0 夹具之外的复杂双面 upper/lower/masked-middle span 组合、动态 sector 高度变化、masked texture 的完整 alpha/裁切行为，以及 Doom/port wall tiling 差异。
- 从相邻 sector 生成 wall cap、door lid、可选 upper wall、背面 masked texture 和切墙可读性策略；这些策略不属于阶段 0 范围，未来是否采用需另行裁定。
- 能力应拆成“sector 几何规则、纹理锚点/采样、视觉遮挡、玩法阻挡”四层；不要让渲染 surface 自动决定可行走高度或 linedef 是否阻挡。

因此，未来只读取 DOOM WAD 时移植 isodoom 的 **规则与边界案例** 有价值；直接照搬其 Godot 3D mesh、atlas/shader、相机、光照或全部配置并非必要。ETNDOOM 应以 DOOM map 语义为依据，再为自身运行架构选择等价表现。

## 6. Source Anchors / 源码锚点

- 墙段与纹理锚点：`E:\isodoom\src\Map\WallSections.cs:98-102, 316-362`；UV/mesh 构建：`E:\isodoom\src\Render\LevelMesh.cs:1268-1310, 1551-1557`。
- flat UV 与墙 wrap：`E:\isodoom\src\Render\LevelMesh.cs:1277-1284`；`E:\isodoom\src\Map\TextureWrap.cs:4-48, 74-88`。
- 墙面有限补厚：`E:\isodoom\src\Render\WallCaps.cs:77-84, 128-138, 161, 263-264`。
- door lid：`E:\isodoom\src\Render\DoorLids.cs:32-62, 203-230`。
- 运行设置：`E:\isodoom\src\Game\Settings.cs:104-109, 119-125, 132-133`；`E:\isodoom\src\Game\LevelScene.Settings.cs:621-695`。
