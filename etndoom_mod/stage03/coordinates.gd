extends RefCounted
## 逻辑 (u,v,h) 是唯一真源；解析投影只供输入与独立对照，不能叠加到 3D 上。
const A := 1.0 / sqrt(2.0)
const B := 0.5
const C := A

static func world(logical: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(logical.x, height, logical.y)

static func logical(point: Vector3) -> Vector3:
	return Vector3(point.x, point.z, point.y)

static func project(point: PackedFloat64Array, origin := PackedFloat64Array([0.0, 0.0])) -> PackedFloat64Array:
	# Godot 的 Vector2/3 分量是 float32；解析参照保留 double，满足 1e-5mu 往返容差。
	return PackedFloat64Array([origin[0] + (point[0] - point[1]) * A, origin[1] + (point[0] + point[1]) * B - point[2] * C])

static func unproject(point: PackedFloat64Array, height: float, origin := PackedFloat64Array([0.0, 0.0])) -> PackedFloat64Array:
	var a := (point[0] - origin[0]) / A
	var b := (point[1] - origin[1] + C * height) / B
	return PackedFloat64Array([(a + b) * 0.5, (b - a) * 0.5, height])

static func input_velocity(screen: Vector2, digital: bool = false) -> Vector2:
	var strength := 1.0 if digital and screen != Vector2.ZERO else minf(screen.length(), 1.0)
	var direction := screen.normalized()
	return Vector2(direction.x * A + direction.y, direction.y - direction.x * A).normalized() * strength * 525.0

static func window_to_logical(camera: Camera3D, pixels: Vector2, height: float) -> Vector3:
	# 撤销最终窗口拉伸后，显式与调用者选择的高度平面求交。
	var viewport_point := camera.get_viewport().get_stretch_transform().affine_inverse() * pixels
	var origin := camera.project_ray_origin(viewport_point)
	var direction := camera.project_ray_normal(viewport_point)
	return logical(origin + direction * ((height - origin.y) / direction.y))
