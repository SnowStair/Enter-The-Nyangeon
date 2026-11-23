extends "res://mods/etndoom_stage0/stage0/stage0_wad.gd"
## 0.3 的静态夹具读取器。复用容器/patch 解码，不改变旧矩形读取器的拒绝规则。

func open(iwad_path: String, map_path: String) -> bool:
	error = ""
	archives.clear()
	images.clear()
	decoded_patches.clear()
	data.clear()
	for spec in [[iwad_path, "IWAD"], [map_path, "PWAD"]]:
		var archive := read_archive(spec[0], spec[1])
		if archive.is_empty():
			return false
		archives.append(archive)
	if not read_map():
		return false
	palette = lump("PLAYPAL")
	if palette.size() < 768 or palette.size() % 768 != 0:
		return fail("PLAYPAL：基础调色板格式无效")
	var flats: Array = []
	var walls: Array = []
	for sector in data.sectors:
		for name in [sector.floor_texture, sector.ceiling_texture]:
			if not name in flats:
				flats.append(name)
	for side in data.sides:
		for name in [side.upper, side.middle, side.lower]:
			if name != "-" and not name in walls:
				walls.append(name)
	for name in flats:
		var bytes := lump(name)
		if bytes.size() != 4096:
			return fail(name + "：flat 必须为 64×64")
		images[name] = flat_image(bytes)
	for name in walls:
		if not decode_texture(name):
			return false
	data.resource_names = flats + walls
	data.map_sha256 = FileAccess.get_sha256(map_path)
	data.iwad_sha256 = FileAccess.get_sha256(iwad_path)
	data.map_file = map_path.get_file()
	return true

func read_map() -> bool:
	var archive: Dictionary = archives[1]
	var marker := -1
	for i in archive.entries.size():
		if archive.entries[i].name == "MAP01":
			marker = i
	var names := ["THINGS", "LINEDEFS", "SIDEDEFS", "VERTEXES", "SEGS", "SSECTORS", "NODES", "SECTORS", "REJECT", "BLOCKMAP"]
	if marker < 0 or marker + names.size() >= archive.entries.size():
		return fail("MAP01：缺少地图标记或结构 lump")
	var lumps: Dictionary = {}
	for i in names.size():
		var entry: Dictionary = archive.entries[marker + 1 + i]
		if entry.name != names[i]:
			return fail("MAP01：地图 lump 次序无效：" + names[i])
		lumps[names[i]] = entry_bytes(archive, entry)
	var strides := {"THINGS": 10, "LINEDEFS": 14, "SIDEDEFS": 30, "VERTEXES": 4, "SEGS": 12, "SSECTORS": 4, "SECTORS": 26}
	for key in strides:
		if lumps[key].is_empty() or lumps[key].size() % strides[key] != 0:
			return fail("MAP01：" + key + " 记录截断或为空")
	var points := PackedVector2Array()
	var bytes: PackedByteArray = lumps.VERTEXES
	for i in range(0, bytes.size(), 4):
		points.append(Vector2(bytes.decode_s16(i), -bytes.decode_s16(i + 2)))
	var sectors: Array = []
	bytes = lumps.SECTORS
	for i in range(0, bytes.size(), 26):
		var sector := {"floor": bytes.decode_s16(i), "ceiling": bytes.decode_s16(i + 2), "floor_texture": lump_name(bytes, i + 4), "ceiling_texture": lump_name(bytes, i + 12), "light": bytes.decode_u16(i + 20), "special": bytes.decode_u16(i + 22), "tag": bytes.decode_u16(i + 24)}
		if sector.ceiling <= sector.floor:
			return fail("SECTORS：静态 sector 高度无效")
		sectors.append(sector)
	var sides: Array = []
	bytes = lumps.SIDEDEFS
	for i in range(0, bytes.size(), 30):
		var side := {"textureoffset": bytes.decode_s16(i), "rowoffset": bytes.decode_s16(i + 2), "upper": lump_name(bytes, i + 4), "lower": lump_name(bytes, i + 12), "middle": lump_name(bytes, i + 20), "sector": bytes.decode_u16(i + 28)}
		if side.sector >= sectors.size():
			return fail("SIDEDEFS：sector 索引越界")
		sides.append(side)
	var lines: Array = []
	bytes = lumps.LINEDEFS
	for i in range(0, bytes.size(), 14):
		var line := {"v1": bytes.decode_u16(i), "v2": bytes.decode_u16(i + 2), "flags": bytes.decode_u16(i + 4), "special": bytes.decode_u16(i + 6), "tag": bytes.decode_u16(i + 8), "front": bytes.decode_u16(i + 10), "back": bytes.decode_u16(i + 12)}
		if line.v1 >= points.size() or line.v2 >= points.size() or line.v1 == line.v2 or line.front >= sides.size() or (line.back != 65535 and line.back >= sides.size()):
			return fail("LINEDEFS：顶点/sidedef 索引无效")
		if ((line.flags & 4) != 0) != (line.back != 65535):
			return fail("LINEDEFS：Double Sided 与 back 索引不一致")
		lines.append(line)
	var bounds := Rect2(points[0], Vector2.ZERO)
	for line in lines:
		bounds = bounds.expand(points[line.v1]).expand(points[line.v2])
	# sector 分界可把矩形边切成多条 linedef；仍须完整、有向、无重叠地覆盖四边。
	if not has_rectangle_outline(points, lines, bounds):
		return fail("MAP01：不支持缺少矩形外框的夹具")
	bytes = lumps.THINGS
	if bytes.size() != 10 or bytes.decode_u16(6) != 1:
		return fail("THINGS：只接受单个 type 1 出生点")
	var spawn := Vector2(bytes.decode_s16(0), -bytes.decode_s16(2))
	if not bounds.grow(-16.0).has_point(spawn):
		return fail("THINGS：32×32 玩家出生范围超出外框")
	var segs: Array = []
	bytes = lumps.SEGS
	for i in range(0, bytes.size(), 12):
		var seg := {"v1": bytes.decode_u16(i), "v2": bytes.decode_u16(i + 2), "line": bytes.decode_u16(i + 6), "side": bytes.decode_u16(i + 8)}
		if seg.v1 >= points.size() or seg.v2 >= points.size() or seg.line >= lines.size() or seg.side > 1:
			return fail("SEGS：顶点/line/side 索引无效")
		var side_index: int = lines[seg.line].front if seg.side == 0 else lines[seg.line].back
		if side_index >= sides.size():
			return fail("SEGS：引用不存在的背面")
		seg.sector = sides[side_index].sector
		segs.append(seg)
	var subsectors: Array = []
	bytes = lumps.SSECTORS
	for i in range(0, bytes.size(), 4):
		var count := bytes.decode_u16(i)
		var start := bytes.decode_u16(i + 2)
		if count == 0 or start + count > segs.size():
			return fail("SSECTORS：seg 范围无效")
		var sector: int = segs[start].sector
		for j in range(start, start + count):
			if segs[j].sector != sector:
				return fail("SSECTORS：同一凸子区包含不同 sector")
		subsectors.append({"sector": sector, "start": start, "count": count})
	var floors := build_floors(lumps.NODES, subsectors, segs, points, bounds)
	if floors.is_empty():
		return false
	data = {"map_id": "MAP01", "bounds": bounds, "spawn": spawn, "origin": Vector2.ZERO, "vertices": points, "lines": lines, "sides": sides, "sectors": sectors, "floors": floors}
	return true

func has_rectangle_outline(points: PackedVector2Array, lines: Array, bounds: Rect2) -> bool:
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return false
	var corners := [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]
	for i in 4:
		var a: Vector2 = corners[i]
		var edge: Vector2 = corners[(i + 1) % 4] - a
		var length := edge.length()
		var tangent := edge / length
		var spans: Array[Vector2] = []
		for line in lines:
			var start: Vector2 = points[line.v1] - a
			var end: Vector2 = points[line.v2] - a
			if line.back != 65535 or edge.cross(start) != 0 or edge.cross(end) != 0:
				continue
			var lo := start.dot(tangent)
			var hi := end.dot(tangent)
			if lo < 0 or hi > length or hi <= lo:
				return false
			spans.append(Vector2(lo, hi))
		spans.sort_custom(func(x: Vector2, y: Vector2) -> bool: return x.x < y.x)
		var cursor := 0.0
		for span in spans:
			if span.x != cursor:
				return false
			cursor = span.y
		if cursor != length:
			return false
	return true

func clip_half_plane(polygon: PackedVector2Array, origin: Vector2, direction: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	if polygon.is_empty():
		return result
	var previous := polygon[-1]
	var previous_distance := direction.cross(previous - origin)
	for point in polygon:
		var distance := direction.cross(point - origin)
		if (distance >= 0) != (previous_distance >= 0):
			result.append(previous.lerp(point, previous_distance / (previous_distance - distance)))
		if distance >= 0:
			result.append(point)
		previous = point
		previous_distance = distance
	var unique := PackedVector2Array()
	for point in result:
		if unique.is_empty() or point.distance_to(unique[-1]) > 0.00001:
			unique.append(point)
	if unique.size() > 1 and unique[0].distance_to(unique[-1]) <= 0.00001:
		unique.resize(unique.size() - 1)
	return unique

func build_floors(bytes: PackedByteArray, subsectors: Array, segs: Array, points: PackedVector2Array, bounds: Rect2) -> Array:
	if bytes.size() % 28 != 0:
		fail("NODES：记录截断")
		return []
	var count := bytes.size() / 28
	var rectangle := PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)])
	var queue: Array = [{"child": int(count) - 1 if count > 0 else 32768, "polygon": rectangle, "depth": 0}]
	var visited: Dictionary = {}
	var floors: Array = []
	while not queue.is_empty():
		var item: Dictionary = queue.pop_back()
		var child: int = item.child
		var polygon: PackedVector2Array = item.polygon
		if item.depth > count + 1 or visited.has(child):
			fail("NODES：重复子节点或循环引用")
			return []
		visited[child] = true
		if child & 32768:
			var index := child & 32767
			if index >= subsectors.size():
				fail("NODES：subsector 索引越界")
				return []
			var sub: Dictionary = subsectors[index]
			for j in range(sub.start, sub.start + sub.count):
				var a := points[segs[j].v1]
				var b := points[segs[j].v2]
				polygon = clip_half_plane(polygon, a, b - a)
			if polygon.size() < 3:
				fail("SSECTORS：BSP/seg 裁切后无有效地面")
				return []
			floors.append({"sector": sub.sector, "polygon": polygon, "subsector": index})
		else:
			if child < 0 or child >= count:
				fail("NODES：节点索引越界")
				return []
			var off := child * 28
			var origin := Vector2(bytes.decode_s16(off), -bytes.decode_s16(off + 2))
			var direction := Vector2(bytes.decode_s16(off + 4), -bytes.decode_s16(off + 6))
			if direction == Vector2.ZERO:
				fail("NODES：零长度分割线")
				return []
			for side in 2:
				queue.append({"child": bytes.decode_u16(off + 24 + side * 2), "polygon": clip_half_plane(polygon, origin, direction if side == 0 else -direction), "depth": item.depth + 1})
	if floors.size() != subsectors.size():
		fail("NODES：存在未引用 subsector")
		return []
	return floors

func decode_texture(name: String) -> bool:
	var pnames := lump("PNAMES")
	var definitions := lump("TEXTURE1")
	if pnames.size() < 4 or definitions.size() < 4:
		return fail("PNAMES/TEXTURE1：缺失或截断")
	var patch_count := pnames.decode_s32(0)
	var count := definitions.decode_s32(0)
	if patch_count < 0 or patch_count > (pnames.size() - 4) / 8 or count < 0 or count > (definitions.size() - 4) / 4:
		return fail("PNAMES/TEXTURE1：目录越界")
	var target := -1
	for i in count:
		var off := definitions.decode_s32(4 + i * 4)
		if off < 4 or off > definitions.size() - 22:
			return fail("TEXTURE1：定义越界")
		if lump_name(definitions, off) == name:
			target = off
	if target < 0:
		return fail("TEXTURE1：缺少 " + name)
	var width := definitions.decode_u16(target + 12)
	var height := definitions.decode_u16(target + 14)
	var patches := definitions.decode_u16(target + 20)
	if width == 0 or height == 0 or width > 4096 or height > 4096 or target + 22 + patches * 10 > definitions.size():
		return fail(name + "：尺寸/patch 定义无效")
	var result := Image.create(width, height, false, Image.FORMAT_RGBA8)
	# Color.TRANSPARENT 的 RGB 为白色；孔洞必须清零，否则 mipmap 会带入白边。
	result.fill(Color(0, 0, 0, 0))
	for i in patches:
		var off := target + 22 + i * 10
		var index := definitions.decode_u16(off + 4)
		if index >= patch_count or definitions.decode_s16(off + 6) != 1 or definitions.decode_s16(off + 8) != 0:
			return fail(name + "：patch 索引/stepdir/colormap 不支持")
		var patch := patch_image(lump_name(pnames, 4 + index * 8))
		if patch == null:
			return false
		result.blend_rect(patch, Rect2i(Vector2i.ZERO, patch.get_size()), Vector2i(definitions.decode_s16(off), definitions.decode_s16(off + 2)))
	images[name] = result
	return true
