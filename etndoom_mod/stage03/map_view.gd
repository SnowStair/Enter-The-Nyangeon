extends Node3D

const COORDINATES := preload("res://mods/etndoom_stage0/stage03/coordinates.gd")
var sections: Array = []
var geometry_points := PackedVector3Array()
var materials: Dictionary = {}

func material_for(name: String, source: Image, two_faces := false) -> StandardMaterial3D:
	var key := name + (":both" if two_faces else ":front")
	if materials.has(key):
		return materials[key]
	var image := source.duplicate() as Image
	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.texture_repeat = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.5
	# 单面实体墙从外侧看也遮挡；双 sidedef 必须各自背面剔除，避免共面深度竞争。
	material.cull_mode = BaseMaterial3D.CULL_DISABLED if two_faces else BaseMaterial3D.CULL_BACK
	materials[key] = material
	return material

func add_polygon(label: String, points: PackedVector3Array, uv: PackedVector2Array, indices: PackedInt32Array, material: Material) -> void:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	geometry_points.append_array(points)

func build(wad) -> void:
	var data: Dictionary = wad.data
	for i in data.floors.size():
		var floor: Dictionary = data.floors[i]
		var sector: Dictionary = data.sectors[floor.sector]
		var image: Image = wad.images[sector.floor_texture]
		var points := PackedVector3Array()
		var uv := PackedVector2Array()
		for p in floor.polygon:
			points.append(COORDINATES.world(p, sector.floor))
			uv.append(p / Vector2(image.get_size()))
		var indices := Geometry2D.triangulate_polygon(floor.polygon)
		# Godot 正面使用顺时针；在 x/z 平面上从 +Y 看是反向。
		for t in range(0, indices.size(), 3):
			var normal := (points[indices[t + 1]] - points[indices[t]]).cross(points[indices[t + 2]] - points[indices[t]])
			if normal.y > 0:
				var swap := indices[t + 1]
				indices[t + 1] = indices[t + 2]
				indices[t + 2] = swap
		add_polygon("Floor_%d" % i, points, uv, indices, material_for(sector.floor_texture, image))
	for index in data.lines.size():
		var line: Dictionary = data.lines[index]
		for back in [false, true]:
			var side_id: int = line.back if back else line.front
			if side_id == 65535:
				continue
			var side: Dictionary = data.sides[side_id]
			var front: Dictionary = data.sectors[side.sector]
			var other_id: int = line.front if back else line.back
			var other: Dictionary = {} if other_id == 65535 else data.sectors[data.sides[other_id].sector]
			var a: Vector2 = data.vertices[line.v2 if back else line.v1]
			var b: Vector2 = data.vertices[line.v1 if back else line.v2]
			var bottom_pegged: bool = (line.flags & 16) != 0
			var top_unpegged: bool = (line.flags & 8) != 0
			if other.is_empty():
				if side.middle != "-":
					var anchor: float = front.floor + wad.images[side.middle].get_height() if bottom_pegged else front.ceiling
					wall(wad, index, side_id, "middle", a, b, front.floor, front.ceiling, anchor + side.rowoffset)
			else:
				if other.ceiling < front.ceiling and side.upper != "-":
					var anchor: float = front.ceiling if top_unpegged else other.ceiling + wad.images[side.upper].get_height()
					wall(wad, index, side_id, "upper", a, b, other.ceiling, front.ceiling, anchor + side.rowoffset)
				if other.floor > front.floor and side.lower != "-":
					var anchor: float = front.ceiling if bottom_pegged else other.floor
					wall(wad, index, side_id, "lower", a, b, front.floor, other.floor, anchor + side.rowoffset)
				if side.middle != "-":
					var height: float = wad.images[side.middle].get_height()
					var lower := maxf(front.floor, other.floor)
					var upper := minf(front.ceiling, other.ceiling)
					var anchor := (lower + height if bottom_pegged else upper) + float(side.rowoffset)
					# masked middle 只显示一次纹理的有效高度，repeat 不扩大几何。
					wall(wad, index, side_id, "masked_middle", a, b, maxf(lower, anchor - height), minf(upper, anchor), anchor)

func wall(wad, line_id: int, side_id: int, kind: String, a: Vector2, b: Vector2, bottom: float, top: float, anchor: float) -> void:
	if top <= bottom:
		return
	var side: Dictionary = wad.data.sides[side_id]
	var texture: String = side["middle" if kind == "masked_middle" else kind]
	var image: Image = wad.images[texture]
	var width := float(image.get_width())
	var height := float(image.get_height())
	var u0 := float(side.textureoffset) / width
	var u1 := (float(side.textureoffset) + a.distance_to(b)) / width
	var v0 := (anchor - bottom) / height
	var v1 := (anchor - top) / height
	var points := PackedVector3Array([COORDINATES.world(a, bottom), COORDINATES.world(b, bottom), COORDINATES.world(b, top), COORDINATES.world(a, top)])
	# front 对应 WAD 线右侧，逻辑 Y 反号后位于 (−dv,+du) 一侧。
	add_polygon("Wall_%d_%d_%s" % [line_id, side_id, kind], points, PackedVector2Array([Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]), PackedInt32Array([0, 2, 1, 0, 3, 2]), material_for(texture, image, wad.data.lines[line_id].back == 65535))
	sections.append({"line": line_id, "side": side_id, "kind": kind, "texture": texture, "a": a, "b": b, "bottom": bottom, "top": top, "anchor": anchor, "u_offset": side.textureoffset, "texture_size": image.get_size()})
