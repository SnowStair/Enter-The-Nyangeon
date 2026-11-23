extends Node2D

var bounds := Rect2()
var floor_texture: Texture2D
var wall_texture: Texture2D
const BAND := 16.0

func _draw() -> void:
	if floor_texture == null or wall_texture == null:
		return
	# nearest + 原始 texel 尺寸平铺；墙带向外延伸，内沿就是逻辑边界。
	draw_texture_rect(floor_texture, bounds, true)
	draw_texture_rect(wall_texture, Rect2(bounds.position - Vector2(BAND, BAND), Vector2(bounds.size.x + 2 * BAND, BAND)), true)
	draw_texture_rect(wall_texture, Rect2(Vector2(bounds.position.x - BAND, bounds.end.y), Vector2(bounds.size.x + 2 * BAND, BAND)), true)
	draw_texture_rect(wall_texture, Rect2(Vector2(bounds.position.x - BAND, bounds.position.y), Vector2(BAND, bounds.size.y)), true)
	draw_texture_rect(wall_texture, Rect2(Vector2(bounds.end.x, bounds.position.y), Vector2(BAND, bounds.size.y)), true)

