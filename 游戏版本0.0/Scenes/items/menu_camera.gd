extends Camera2D

# 偏移灵敏度（越大偏移越明显）
@export var offset_strength := 100.0
# 平滑插值速度（越大越快）
@export var smooth_speed := 5.0

# 屏幕中心与当前目标偏移量
var target_offset: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	
	# 计算鼠标相对于中心的偏移，范围 -1 到 1
	var mouse_offset = (mouse_pos - viewport_size / 2.0) / (viewport_size / 2.0)
	mouse_offset = mouse_offset.clamp(Vector2(-1, -1), Vector2(1, 1))
	
	# 应用灵敏度，得到目标偏移
	target_offset = mouse_offset * offset_strength
	
	# 使用线性插值使偏移平滑
	offset = offset.lerp(target_offset, delta * smooth_speed)
