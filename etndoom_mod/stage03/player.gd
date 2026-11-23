extends CharacterBody2D

const COORDINATES := preload("res://mods/etndoom_stage0/stage03/coordinates.gd")
const MAX_SPEED := 525.0
const ACCELERATION := 1720.0
var body_shape: CollisionShape2D
var frames: SpriteFrames
var halo_texture: Texture2D
var halo_transform: Transform2D
var adaptation: Dictionary = {}
var animation := "idle"
var flip_h := false
var frame := 0
var animation_time := 0.0
var animate := true
var physics_ticks := 0
var move_calls := 0
var last_move_frame := -1
var duplicate_move := false

func root_logical() -> Vector2:
	return global_position

func collision_center() -> Vector2:
	return body_shape.global_position

func foot_logical() -> Vector3:
	return Vector3(global_position.x, global_position.y, 0.0)

func shadow_anchor() -> Vector3:
	return foot_logical()

func _physics_process(delta: float) -> void:
	physics_ticks += 1
	var tick := Engine.get_physics_frames()
	duplicate_move = duplicate_move or tick == last_move_frame
	last_move_frame = tick
	var input := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	velocity = velocity.move_toward(COORDINATES.input_velocity(input), ACCELERATION * delta)
	move_calls += 1
	move_and_slide()
	if input.x != 0.0:
		flip_h = input.x < 0.0
	var next := "run" if velocity.length_squared() > 0.01 else "idle"
	if next != animation:
		animation = next
		animation_time = 0.0
		frame = 0
	if animate:
		animation_time += delta
		var duration := frames.get_frame_duration(animation, frame) / frames.get_animation_speed(animation)
		while animation_time >= duration:
			animation_time -= duration
			frame = (frame + 1) % frames.get_frame_count(animation)
			duration = frames.get_frame_duration(animation, frame) / frames.get_animation_speed(animation)
