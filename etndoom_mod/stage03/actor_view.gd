extends MeshInstance3D
## 绕竖直轴朝向固定相机；主体可见高度为 56mu，光环只随主体等比缩放。
const HEIGHT := 56.0
var textures: Dictionary = {}
var frame_info: Dictionary = {}
var current_key := ""
var material := StandardMaterial3D.new()

func _ready() -> void:
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.5
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.cull_mode = BaseMaterial3D.CULL_BACK
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rotation.y = deg_to_rad(45.0)

func sync(player) -> void:
	position = Vector3(player.position.x, 0.0, player.position.y)
	var key: String = "%s:%d:%s" % [player.animation, player.frame, player.flip_h]
	if current_key == key:
		return
	current_key = key
	var info := prepare_frame(player, player.animation, player.frame, player.flip_h)
	material.albedo_texture = textures[key]
	var rect: Rect2 = info.quad_rect
	var quad := QuadMesh.new()
	quad.size = rect.size
	quad.center_offset = Vector3(rect.get_center().x, rect.get_center().y, 0)
	mesh = quad

func prepare_frame(player, animation: String, frame: int, flip: bool) -> Dictionary:
	var key := "%s:%d:%s" % [animation, frame, flip]
	if not textures.has(key):
		var source: Texture2D = player.frames.get_frame_texture(animation, frame)
		var original := source.get_image()
		var body := visible_rect(original)
		assert(body.size.y > 0, "Momoi 动画帧必须含 alpha cutout 后可见的主体像素")
		var units_per_pixel := HEIGHT / float(body.size.y)
		var halo: Image = player.halo_texture.get_image()
		# 复用 HaloRoot、原光环旋转与缩放；光环和透明留白不参与主体高度标定。
		var transform: Transform2D = player.halo_transform
		transform.origin += Vector2(original.get_size()) * 0.5
		var half := Vector2(halo.get_size()) * 0.5
		var bounds := Rect2(Vector2.ZERO, Vector2(original.get_size()))
		for corner in [-half, Vector2(half.x,-half.y), half, Vector2(-half.x,half.y)]:
			bounds = bounds.expand(transform * corner)
		var start := Vector2i(bounds.position.floor())
		var end := Vector2i(bounds.end.ceil())
		var composite := Image.create(end.x-start.x, end.y-start.y, false, Image.FORMAT_RGBA8)
		composite.fill(Color(0,0,0,0))
		var inverse := transform.affine_inverse()
		for y in composite.get_height():
			for x in composite.get_width():
				var sample := Vector2i((inverse * (Vector2(start) + Vector2(x+0.5,y+0.5)) + half).floor())
				if sample.x >= 0 and sample.y >= 0 and sample.x < halo.get_width() and sample.y < halo.get_height():
					composite.set_pixel(x,y,halo.get_pixelv(sample))
		composite.blend_rect(original, Rect2i(Vector2i.ZERO,original.get_size()), -start)
		var used := composite.get_used_rect()
		var image := composite.get_region(used)
		var origin := start + used.position
		var left := (origin.x - (body.position.x + body.size.x * 0.5)) * units_per_pixel
		var bottom := (body.end.y - origin.y - used.size.y) * units_per_pixel
		var size := Vector2(used.size) * units_per_pixel
		if flip:
			image.flip_x()
			left = -left - size.x
		textures[key] = ImageTexture.create_from_image(image)
		frame_info[key] = {"source_size": original.get_size(), "trim": used, "source_origin": start, "size": image.get_size(), "halo": player.halo_texture.resource_path, "body_trim": body, "units_per_pixel": units_per_pixel, "quad_rect": Rect2(Vector2(left, bottom), size)}
	return frame_info[key]

func visible_rect(image: Image) -> Rect2i:
	var minimum := image.get_size()
	var maximum := Vector2i.ZERO
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.5:
				minimum = minimum.min(Vector2i(x, y))
				maximum = maximum.max(Vector2i(x + 1, y + 1))
	return Rect2i(minimum, maximum - minimum)

func corners() -> PackedVector3Array:
	var points := PackedVector3Array()
	if mesh == null:
		return points
	var half: Vector2 = mesh.size * 0.5
	for p in [Vector3(-half.x, -half.y, 0), Vector3(half.x, -half.y, 0), Vector3(-half.x, half.y, 0), Vector3(half.x, half.y, 0)]:
		points.append(global_transform * (mesh.center_offset + p))
	return points
