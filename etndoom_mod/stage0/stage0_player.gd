extends CharacterBody2D

## 只驱动原 Momoi 实例的平面移动与外观，不继承 Player 协议。
var max_speed := 155.0
var speed_time := 0.2
var body_shape: CollisionShape2D
var sprite: AnimatedSprite2D
var halo: Sprite2D
var halo_root: Node2D
var physics_ticks := 0
var move_calls := 0
var last_move_frame := -1
var duplicate_move := false
var adaptation: Dictionary = {}

func _physics_process(delta: float) -> void:
	physics_ticks += 1
	var frame := Engine.get_physics_frames()
	if last_move_frame == frame:
		duplicate_move = true
	last_move_frame = frame
	var direction := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	if Game.control_mode == 0:
		direction = direction.normalized()
	var acceleration := max_speed / speed_time
	velocity.x = move_toward(velocity.x, direction.x * max_speed, acceleration * delta)
	velocity.y = move_toward(velocity.y, direction.y * max_speed, acceleration * delta)
	move_calls += 1
	move_and_slide()
	if direction.x != 0:
		sprite.flip_h = direction.x < 0
	var next_animation := "run" if velocity.length_squared() > 0.01 else "idle"
	if sprite.animation != next_animation:
		sprite.play(next_animation)
	# 沿用局部锚点；不用原版准星/跳跃/受击更新链。
	halo.position = sprite.position + halo_root.position

