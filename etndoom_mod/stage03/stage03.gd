extends Node2D

const PLAYER_PATH := "res://scenes/player/momoi/momoi.tscn"
const SOURCE_WAD := "E:/Enter-The-Nyangeon-ETNDoom/etndoom_mod/wad/DOOM2.WAD"
const COORDINATES := preload("res://mods/etndoom_stage0/stage03/coordinates.gd")
const WAD_SCRIPT := preload("res://mods/etndoom_stage0/stage03/wad.gd")
const PLAYER_SCRIPT := preload("res://mods/etndoom_stage0/stage03/player.gd")
const MAP_VIEW := preload("res://mods/etndoom_stage0/stage03/map_view.gd")
const ACTOR_VIEW := preload("res://mods/etndoom_stage0/stage03/actor_view.gd")
const FOCUS_HEIGHT := 28.0
const MAPS := ["MAP01.wad", "MAP01_BackWall.wad", "MAP01_FrontWall.wad", "MAP01_Texture.wad", "MAP01_HTest.wad"]

@export var stage := "0.3"
@export var collision_enabled := true
@export var map_name := "MAP01.wad"
@export var game_size := 960.0
@export var overview := false
var ready_ok := false
var failure := ""
var wad
var player
var map_view
var actor
var camera: Camera3D
var boundary: StaticBody2D
var follow_depth: Dictionary = {}
var overview_depth: Dictionary = {}
var overview_focus := Vector3.ZERO
var overview_size := 1400.0
var saved_window: Dictionary = {}

func _ready() -> void:
	var window := get_window()
	saved_window = {"size": window.content_scale_size, "mode": window.content_scale_mode, "aspect": window.content_scale_aspect}
	window.content_scale_size = Vector2i(1600, 900)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.size = Vector2i(1600, 900)
	wad = WAD_SCRIPT.new()
	if not map_name in MAPS or not wad.open(SOURCE_WAD, "res://mods/etndoom_stage0/wad/" + map_name):
		abort("WAD 读取失败：" + wad.error)
		return
	map_view = MAP_VIEW.new()
	map_view.name = "WadPresentation"
	$FloorLayer.add_child(map_view)
	map_view.build(wad)
	player = adapt_player()
	if player == null:
		abort(failure)
		return
	player.position = wad.data.spawn
	$YSort/PlayerRoot.add_child(player)
	$BattleRoom.position = wad.data.bounds.get_center()
	if collision_enabled:
		create_boundary()
	actor = ACTOR_VIEW.new()
	actor.name = "MomoiBillboard"
	$Presentation.add_child(actor)
	actor.sync(player)
	camera = Camera3D.new()
	camera.name = "Stage03Camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.rotation_degrees = Vector3(-45.0, 45.0, 0.0)
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	$Presentation.add_child(camera)
	camera.make_current()
	calculate_framing()
	sync_observation()
	process_physics_priority = 100
	ready_ok = true
	print("STAGE03_READY " + JSON.stringify(report()))

func _exit_tree() -> void:
	# 本体自定义鼠标持有压缩贴图；退出测试场景时先释放，避免渲染器销毁后的 RID 泄漏。
	DisplayServer.cursor_set_custom_image(null)
	if not saved_window.is_empty():
		get_window().content_scale_size = saved_window.size
		get_window().content_scale_mode = saved_window.mode
		get_window().content_scale_aspect = saved_window.aspect

func abort(reason: String) -> void:
	failure = reason
	push_error("[Stage0.3] " + map_name + "：" + reason)

func all_nodes(node: Node) -> Array:
	var nodes: Array = [node]
	for child in node.get_children():
		nodes.append_array(all_nodes(child))
	return nodes

func adapt_player():
	var packed := load(PLAYER_PATH) as PackedScene
	if packed == null:
		failure = "无法加载固定 Momoi 场景"
		return null
	var instance = packed.instantiate()
	if not instance is CharacterBody2D or not instance.has_node("CollisionShape2D") or not instance.has_node("Graphics/AnimatedSprite2D/HaloRoot") or not instance.has_node("Graphics/Halo"):
		failure = "Momoi 原场景缺少物理根/形状/动画帧"
		instance.free()
		return null
	var frames: SpriteFrames = instance.get_node("Graphics/AnimatedSprite2D").sprite_frames
	var halo: Sprite2D = instance.get_node("Graphics/Halo")
	var halo_texture: Texture2D = halo.texture
	var halo_transform := Transform2D(halo.rotation, halo.scale, halo.skew, instance.get_node("Graphics/AnimatedSprite2D/HaloRoot").position)
	var shape: CollisionShape2D = instance.get_node("CollisionShape2D")
	var nodes := all_nodes(instance)
	var disconnected := 0
	for node in nodes:
		for signal_info in node.get_signal_list():
			for connection in node.get_signal_connection_list(signal_info.name):
				if connection.callable.get_object() == instance:
					node.disconnect(signal_info.name, connection.callable)
					disconnected += 1
		for group in node.get_groups():
			node.remove_from_group(group)
	# 新适配实例入树前剥离原玩法；旧场景/旧适配代码和资源原件不修改。
	for i in range(nodes.size() - 1, 0, -1):
		var node: Node = nodes[i]
		if node != shape:
			node.get_parent().remove_child(node)
			node.free()
	shape.set_script(null)
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(32, 32)
	shape.position = Vector2.ZERO
	shape.disabled = not collision_enabled
	instance.set_script(PLAYER_SCRIPT)
	instance.body_shape = shape
	instance.frames = frames
	instance.halo_texture = halo_texture
	instance.halo_transform = halo_transform
	instance.collision_layer = 1 if collision_enabled else 0
	instance.collision_mask = 256 if collision_enabled else 0
	instance.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	instance.adaptation = {"source": PLAYER_PATH, "same_body_id": instance.get_instance_id(), "old_ready": instance.is_node_ready(), "removed_connections": disconnected}
	return instance

func create_boundary() -> void:
	var bounds: Rect2 = wad.data.bounds
	var thickness := 32.0
	boundary = StaticBody2D.new()
	boundary.name = "MapBoundary"
	boundary.collision_layer = 256
	boundary.collision_mask = 0
	var rectangles := [Rect2(bounds.position - Vector2(thickness, thickness), Vector2(bounds.size.x + 2 * thickness, thickness)), Rect2(Vector2(bounds.position.x - thickness, bounds.end.y), Vector2(bounds.size.x + 2 * thickness, thickness)), Rect2(bounds.position - Vector2(thickness, 0), Vector2(thickness, bounds.size.y)), Rect2(Vector2(bounds.end.x, bounds.position.y), Vector2(thickness, bounds.size.y))]
	for rect in rectangles:
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collider.shape = shape
		collider.position = rect.get_center()
		boundary.add_child(collider)
	$Logic.add_child(boundary)

func calculate_framing() -> void:
	var bounds: Rect2 = wad.data.bounds.grow(-16.0)
	var positions := [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]
	var geometry: PackedVector3Array = map_view.geometry_points.duplicate()
	var focuses := PackedVector3Array()
	var max_width := 0.0
	var min_height := 0.0
	var max_height := 0.0
	for animation in player.frames.get_animation_names():
		if not animation in ["idle", "run"]:
			continue
		for i in player.frames.get_frame_count(animation):
			var info: Dictionary = actor.prepare_frame(player, animation, i, false)
			var rect: Rect2 = info.quad_rect
			# 主体为 56mu，光环可能更高；包括水平翻转后的全部可视范围。
			max_width = maxf(max_width, 2.0 * maxf(absf(rect.position.x), absf(rect.end.x)))
			min_height = minf(min_height, rect.position.y)
			max_height = maxf(max_height, rect.end.y)
	var right := Vector3(COORDINATES.A, 0, -COORDINATES.A)
	for p in positions:
		focuses.append(COORDINATES.world(p, FOCUS_HEIGHT))
		for h in [min_height, max_height]:
			for sign_value in [-1.0, 1.0]:
				geometry.append(COORDINATES.world(p, h) + right * max_width * 0.5 * sign_value)
	follow_depth = depth_config(geometry, focuses)
	var overview_points: PackedVector3Array = map_view.geometry_points.duplicate()
	overview_points.append_array(actor.corners())
	var inverse := camera.basis.inverse()
	var box := Rect2(Vector2.ZERO, Vector2.ZERO)
	for i in overview_points.size():
		var p := inverse * overview_points[i]
		var xy := Vector2(p.x, p.y)
		box = Rect2(xy, Vector2.ZERO) if i == 0 else box.expand(xy)
	var center := box.get_center()
	overview_focus = camera.basis * Vector3(center.x, center.y, 0.0)
	overview_size = ceilf(maxf(box.size.y, box.size.x / (16.0 / 9.0)) / 0.8 / 10.0) * 10.0
	overview_depth = depth_config(geometry, PackedVector3Array([overview_focus]))

func depth_config(points: PackedVector3Array, focuses: PackedVector3Array) -> Dictionary:
	var q_min := INF
	var q_max := -INF
	for focus in focuses:
		for point in points:
			var q := camera.basis.z.dot(point - focus)
			q_min = minf(q_min, q)
			q_max = maxf(q_max, q)
	var margin := maxf(8.0, 0.02 * (q_max - q_min))
	var distance := maxf(256.0, q_max + margin + 8.0)
	return {"distance": distance, "d_min": distance - q_max, "d_max": distance - q_min, "margin": margin, "near": maxf(0.1, distance - q_max - margin), "far": distance - q_min + margin}

func sync_observation() -> void:
	actor.sync(player)
	$Control.size = get_viewport_rect().size
	$Control/ColorRect.size = $Control.size
	$Control/TextureRect.size = $Control.size
	var focus := overview_focus if overview else COORDINATES.world(player.global_position, FOCUS_HEIGHT)
	var depth: Dictionary = overview_depth if overview else follow_depth
	camera.position = focus + camera.basis.z * float(depth.distance)
	camera.size = overview_size if overview else game_size
	camera.near = depth.near
	camera.far = depth.far

func set_game_size(value: float) -> void:
	game_size = clampf(roundf(value / 10.0) * 10.0, 640.0, 1600.0)
	if ready_ok:
		sync_observation()

func _physics_process(_delta: float) -> void:
	if ready_ok:
		sync_observation()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not ready_ok:
		return
	match event.keycode:
		KEY_F2:
			overview = not overview
		KEY_MINUS, KEY_KP_SUBTRACT:
			set_game_size(game_size + 10)
		KEY_EQUAL, KEY_KP_ADD:
			set_game_size(game_size - 10)
	sync_observation()

func report() -> Dictionary:
	return {"stage": stage, "map": map_name, "map_sha256": wad.data.map_sha256, "iwad_sha256": wad.data.iwad_sha256, "collision_enabled": collision_enabled, "game_size": game_size, "overview_size": overview_size, "focus_height": FOCUS_HEIGHT, "keep_aspect": "KEEP_HEIGHT", "follow_depth": follow_depth, "overview_depth": overview_depth, "ready": ready_ok, "failure": failure}
