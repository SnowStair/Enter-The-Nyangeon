extends RefCounted

## 仅支持 Stage0 矩形图与限定素材；不是正式地图格式/完整 WAD loader。
var error := ""
var archives: Array = []
var data: Dictionary = {}
var images: Dictionary = {}
var palette := PackedByteArray()
var decoded_patches: Array[String] = []

func fail(message: String) -> bool:
	error = message
	return false

func read_archive(path: String, magic: String) -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 12 or bytes.slice(0, 4).get_string_from_ascii() != magic:
		fail("%s：缺失、截断或不是 %s" % [path, magic])
		return {}
	var count := bytes.decode_s32(4)
	var offset := bytes.decode_s32(8)
	if count < 0 or offset < 12 or offset > bytes.size() or count > (bytes.size() - offset) / 16:
		fail(path + "：lump 目录越界")
		return {}
	var entries: Array = []
	for i in count:
		var pos := offset + i * 16
		var start := bytes.decode_s32(pos)
		var size := bytes.decode_s32(pos + 4)
		var name := lump_name(bytes, pos + 8)
		if start < 0 or size < 0 or start > bytes.size() - size:
			fail("%s：%s 数据越界" % [path, name])
			return {}
		entries.append({"name": name, "start": start, "size": size})
	return {"bytes": bytes, "entries": entries}

func lump_name(bytes: PackedByteArray, offset: int) -> String:
	var end := offset
	while end < offset + 8 and bytes[end] != 0:
		end += 1
	return bytes.slice(offset, end).get_string_from_ascii().to_upper()

func entry_bytes(archive: Dictionary, entry: Dictionary) -> PackedByteArray:
	return archive.bytes.slice(entry.start, entry.start + entry.size)

func lump(name: String) -> PackedByteArray:
	# 后加载覆盖，且同一 WAD 内最后一个同名 lump 优先。
	for a in range(archives.size() - 1, -1, -1):
		for i in range(archives[a].entries.size() - 1, -1, -1):
			var entry: Dictionary = archives[a].entries[i]
			if entry.name == name:
				return entry_bytes(archives[a], entry)
	fail("缺少资源 lump：" + name)
	return PackedByteArray()

func open(iwad_path: String, map_path: String) -> bool:
	error = ""
	archives.clear()
	images.clear()
	decoded_patches.clear()
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
	for name in ["FLOOR0_1", "CEIL1_1"]:
		var bytes := lump(name)
		if bytes.size() != 4096:
			return fail(name + "：flat 必须为 64×64、4096 字节")
		if name == "FLOOR0_1":
			images[name] = flat_image(bytes)
	if not read_texture():
		return false
	data["resource_names"] = ["FLOOR0_1", "STARTAN2", "CEIL1_1"]
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
	var map_lumps: Dictionary = {}
	for i in names.size():
		var entry: Dictionary = archive.entries[marker + 1 + i]
		if entry.name != names[i]:
			return fail("MAP01：地图 lump 次序不支持，预期 " + names[i])
		map_lumps[names[i]] = entry_bytes(archive, entry)
	var vertices: PackedByteArray = map_lumps.VERTEXES
	var lines: PackedByteArray = map_lumps.LINEDEFS
	var sides: PackedByteArray = map_lumps.SIDEDEFS
	var sectors: PackedByteArray = map_lumps.SECTORS
	var things: PackedByteArray = map_lumps.THINGS
	if vertices.size() != 16 or lines.size() != 56 or sides.size() != 120 or sectors.size() != 26 or things.size() != 10:
		return fail("MAP01：只支持四顶点/四单面边/单 sector/单玩家出生点的阶段 0 矩形")
	var points: Array[Vector2] = []
	for i in 4:
		points.append(Vector2(vertices.decode_s16(i * 4), -vertices.decode_s16(i * 4 + 2)))
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return fail("MAP01：矩形宽高必须为正")
	var corners := [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]
	var edges: Array = []
	var used_corners: Array = []
	for p in points:
		if not p in corners or p in used_corners:
			return fail("MAP01：顶点不是四个不同的矩形角点")
		used_corners.append(p)
	for i in 4:
		var off := i * 14
		var v1 := lines.decode_u16(off)
		var v2 := lines.decode_u16(off + 2)
		var side := lines.decode_u16(off + 10)
		if v1 >= 4 or v2 >= 4 or v1 == v2 or side >= 4 or lines.decode_u16(off + 12) != 65535:
			return fail("MAP01：LINEDEFS 顶点/单面侧索引无效")
		if points[v1].x != points[v2].x and points[v1].y != points[v2].y:
			return fail("MAP01：矩形边必须平行于坐标轴")
		var key := Vector2i(mini(v1, v2), maxi(v1, v2))
		if key in edges:
			return fail("MAP01：重复边，矩形未闭合")
		edges.append(key)
		var s := side * 30
		if sides.decode_u16(s + 28) != 0 or lump_name(sides, s + 20) != "STARTAN2" or lump_name(sides, s + 4) != "-" or lump_name(sides, s + 12) != "-":
			return fail("MAP01：只支持 sector 0 的 STARTAN2 单面墙")
	if lump_name(sectors, 4) != "FLOOR0_1" or lump_name(sectors, 12) != "CEIL1_1" or sectors.decode_s16(2) <= sectors.decode_s16(0):
		return fail("MAP01：sector 素材引用或平面高度无效")
	if things.decode_u16(6) != 1:
		return fail("MAP01：只接受一个 type 1 玩家出生点")
	var spawn := Vector2(things.decode_s16(0), -things.decode_s16(2))
	if not bounds.has_point(spawn):
		return fail("MAP01：出生点必须在矩形内")
	data = {"map_id": "MAP01", "bounds": bounds, "spawn": spawn, "origin": Vector2.ZERO}
	return true

func palette_color(index: int) -> Color:
	return Color8(palette[index * 3], palette[index * 3 + 1], palette[index * 3 + 2])

func flat_image(bytes: PackedByteArray) -> Image:
	var result := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			result.set_pixel(x, y, palette_color(bytes[y * 64 + x]))
	return result

func read_texture() -> bool:
	var pnames := lump("PNAMES")
	var textures := lump("TEXTURE1")
	if pnames.size() < 4 or textures.size() < 4:
		return fail("PNAMES/TEXTURE1：缺失或截断")
	var patch_count := pnames.decode_s32(0)
	var texture_count := textures.decode_s32(0)
	if patch_count < 0 or patch_count > (pnames.size() - 4) / 8 or texture_count < 0 or texture_count > (textures.size() - 4) / 4:
		return fail("PNAMES/TEXTURE1：目录越界")
	var target := -1
	for i in texture_count:
		var off := textures.decode_s32(4 + i * 4)
		if off < 4 or off > textures.size() - 22:
			return fail("TEXTURE1：纹理定义越界")
		if lump_name(textures, off) == "STARTAN2":
			target = off
	if target < 0:
		return fail("TEXTURE1：缺少 STARTAN2 定义")
	var width := textures.decode_u16(target + 12)
	var height := textures.decode_u16(target + 14)
	var count := textures.decode_u16(target + 20)
	if width != 128 or height != 128 or count != 4 or target + 22 + count * 10 > textures.size():
		return fail("STARTAN2：只支持当前 128×128、4 patch 定义")
	var result := Image.create(width, height, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	for i in count:
		var off := target + 22 + i * 10
		var patch_index := textures.decode_u16(off + 4)
		if patch_index >= patch_count or textures.decode_s16(off + 6) != 1 or textures.decode_s16(off + 8) != 0:
			return fail("STARTAN2：patch 索引/stepdir/colormap 不支持")
		var name := lump_name(pnames, 4 + patch_index * 8)
		var patch := patch_image(name)
		if patch == null:
			return false
		# patch 左上角由 texture 定义给出；patch 自带的 sprite offset 不参与组合。
		result.blend_rect(patch, Rect2i(Vector2i.ZERO, patch.get_size()), Vector2i(textures.decode_s16(off), textures.decode_s16(off + 2)))
	images["STARTAN2"] = result
	return true

func patch_image(name: String) -> Image:
	var bytes := lump(name)
	if bytes.size() < 8:
		fail(name + "：patch 头截断")
		return null
	var width := bytes.decode_u16(0)
	var height := bytes.decode_u16(2)
	if width <= 0 or height <= 0 or width > 4096 or height > 4096 or 8 + width * 4 > bytes.size():
		fail(name + "：patch 尺寸或列目录无效")
		return null
	var result := Image.create(width, height, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	for x in width:
		var pos := bytes.decode_u32(8 + x * 4)
		while true:
			if pos >= bytes.size():
				fail(name + "：patch 列缺少结束标记")
				return null
			var top := int(bytes[pos])
			if top == 255:
				break
			if pos + 4 > bytes.size():
				fail(name + "：patch post 头截断")
				return null
			var length := int(bytes[pos + 1])
			if top + length > height or pos + length + 4 > bytes.size():
				fail(name + "：不支持的 tall patch 或 post 越界")
				return null
			for y in length:
				result.set_pixel(x, top + y, palette_color(bytes[pos + 3 + y]))
			pos += length + 4
	decoded_patches.append(name)
	return result
