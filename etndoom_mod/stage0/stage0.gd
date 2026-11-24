extends Node2D

const PLAYER_PATH := "res://scenes/player/momoi/momoi.tscn"
const SOURCE_WAD := "E:/Enter-The-Nyangeon-ETNDoom/etndoom_mod/wad/Third Party WAD/DOOM2.WAD"
const MAP_PATH := "res://mods/etndoom_stage0/wad/MAP01.wad"
const PLAYER_SCRIPT := preload("res://mods/etndoom_stage0/stage0/stage0_player.gd")
const WAD_SCRIPT := preload("res://mods/etndoom_stage0/stage0/stage0_wad.gd")
const MAP_VIEW := preload("res://mods/etndoom_stage0/stage0/stage0_map_view.gd")
const WALL_THICKNESS := 32.0

@export var stage := "0.1"
var collision_enabled := false
var ready_ok := false
var failure := ""
var wad
var player
var camera: Camera2D
var map_view: Node2D
var boundary: StaticBody2D

func _ready() -> void:
	collision_enabled = stage == "0.2"
	if not stage in ["0.1", "0.2"]:
		abort("无效阶段：" + stage)
		return
	wad = WAD_SCRIPT.new()
	if not wad.open(SOURCE_WAD, MAP_PATH):
		abort(wad.error)
		return
	map_view = MAP_VIEW.new()
	map_view.name = "WadMap"
	map_view.bounds = wad.data.bounds
	map_view.floor_texture = ImageTexture.create_from_image(wad.images.FLOOR0_1)
	map_view.wall_texture = ImageTexture.create_from_image(wad.images.STARTAN2)
	map_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_view.z_index = -1
	$FloorLayer.add_child(map_view)
	$BattleRoom.position = wad.data.bounds.get_center()
	player = adapt_player()
	if player == null:
		abort(failure)
		return
	player.position = wad.data.spawn
	$YSort/PlayerRoot.add_child(player)
	if collision_enabled:
		create_boundary()
	camera = Camera2D.new()
	camera.name = "Stage0Camera"
	camera.position_smoothing_enabled = false
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position = player.global_position
	add_child(camera)
	camera.make_current()
	process_physics_priority = 100
	sync_observation()
	ready_ok = true
	print("STAGE0_READY " + JSON.stringify(report()))

func abort(reason: String) -> void:
	failure = reason
	push_error("[Stage0] 资源/适配失败 stage=%s map=MAP01 player=%s collision=%s：%s" % [stage, PLAYER_PATH, collision_enabled, reason])

func report() -> Dictionary:
	return {"stage": stage, "map_id": "MAP01", "bounds": str(wad.data.bounds), "size": str(wad.data.bounds.size), "spawn": str(wad.data.spawn), "origin": str(wad.data.origin), "player": PLAYER_PATH, "collision_enabled": collision_enabled, "last_position": str(player.global_position) if is_instance_valid(player) else "", "ready": ready_ok, "failure": failure}

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
	var required := ["Stats", "CollisionShape2D", "Graphics", "Graphics/AnimatedSprite2D", "Graphics/Halo", "Graphics/AnimatedSprite2D/HaloRoot", "Shadow"]
	for path in required:
		if not instance.has_node(path):
			failure = "Momoi 缺少必要节点：" + path
			instance.free()
			return null
	var stats = instance.get_node("Stats")
	var speed := float(stats.MAX_SPEED)
	var duration := float(stats.SPEED_TIME)
	var shape := instance.get_node("CollisionShape2D") as CollisionShape2D
	if not instance is CharacterBody2D or not is_equal_approx(speed, 155.0) or not is_equal_approx(duration, 0.2) or not shape.shape is CircleShape2D or not is_equal_approx(shape.shape.radius, 7.0) or shape.position != Vector2(0, -6):
		failure = "Momoi 基础移动参数/根圆与 D06 不符"
		instance.free()
		return null
	var nodes := all_nodes(instance)
	var connections := 0
	var old_ready := false
	for node in nodes:
		old_ready = old_ready or node.is_node_ready() or node.is_inside_tree()
		for signal_info in node.get_signal_list():
			for connection in node.get_signal_connection_list(signal_info.name):
				# 只清旧根回调；Container 等引擎内部连接由节点析构维护。
				if connection.callable.get_object() == instance:
					node.disconnect(signal_info.name, connection.callable)
					connections += 1
		for group in node.get_groups():
			node.remove_from_group(group)
	# 精确白名单；先断开旧连接，再同步释放所有不保留节点，不使用 queue_free。
	var keep := [".", "CollisionShape2D", "Graphics", "Graphics/AnimatedSprite2D", "Graphics/Halo", "Graphics/AnimatedSprite2D/HaloRoot", "Shadow"]
	for i in range(nodes.size() - 1, 0, -1):
		var node: Node = nodes[i]
		if not str(instance.get_path_to(node)) in keep:
			node.get_parent().remove_child(node)
			node.free()
	for node in all_nodes(instance):
		if node != instance:
			node.set_script(null)
	instance.set_script(PLAYER_SCRIPT)
	instance.max_speed = speed
	instance.speed_time = duration
	instance.body_shape = shape
	instance.sprite = instance.get_node("Graphics/AnimatedSprite2D")
	instance.halo = instance.get_node("Graphics/Halo")
	instance.halo_root = instance.get_node("Graphics/AnimatedSprite2D/HaloRoot")
	instance.sprite.play("idle")
	instance.sprite.set_frame_and_progress(0, 0.0)
	instance.collision_layer = 1 if collision_enabled else 0
	instance.collision_mask = 256 if collision_enabled else 0
	shape.disabled = not collision_enabled
	instance.adaptation = {"source": PLAYER_PATH, "same_body_id": instance.get_instance_id(), "old_ready": old_ready, "removed_connections": connections, "retained_nodes": all_nodes(instance).size()}
	return instance

func create_boundary() -> void:
	var bounds: Rect2 = wad.data.bounds
	var t := WALL_THICKNESS
	boundary = StaticBody2D.new()
	boundary.name = "MapBoundary"
	boundary.collision_layer = 256
	boundary.collision_mask = 0
	# 横墙扩展覆盖四角；所有内侧来自同一个 bounds，厚度只向外。
	var rectangles := {
		"North": Rect2(bounds.position - Vector2(t, t), Vector2(bounds.size.x + 2 * t, t)),
		"South": Rect2(Vector2(bounds.position.x - t, bounds.end.y), Vector2(bounds.size.x + 2 * t, t)),
		"West": Rect2(bounds.position - Vector2(t, 0), Vector2(t, bounds.size.y)),
		"East": Rect2(Vector2(bounds.end.x, bounds.position.y), Vector2(t, bounds.size.y))}
	for side in rectangles:
		var rect: Rect2 = rectangles[side]
		var collider := CollisionShape2D.new()
		collider.name = side
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collider.shape = shape
		collider.position = rect.get_center()
		boundary.add_child(collider)
	add_child(boundary)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(camera):
		sync_observation()

func sync_observation() -> void:
	camera.position = player.global_position
	camera.force_update_scroll()
	# 背景跟随视野无限铺底；原滚动材质参数保持不变，场内由不透明地面覆盖。
	var view_size := get_viewport_rect().size / camera.zoom
	$Control.position = player.global_position - view_size
	$Control.size = view_size * 2.0
	$Control/ColorRect.size = $Control.size
	$Control/TextureRect.size = $Control.size
