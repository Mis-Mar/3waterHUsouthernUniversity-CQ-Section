extends Camera2D

# 鼠标控制偏移灵敏度
@export var offset_strength := 100.0
# 平滑插值速度
@export var smooth_speed := 5.0
# 浮动运动的幅度（像素）
@export var idle_float_amplitude := 20.0
# 浮动速度（频率因子，越大越快）
@export var idle_float_speed := 1.0

# 目标偏移
var target_offset: Vector2 = Vector2.ZERO
# 浮动时间累计
var time_passed := 0.0

func _process(delta: float) -> void:
	time_passed += delta

	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()

	# 鼠标相对中心的偏移，范围 -1 到 1
	var mouse_offset = (mouse_pos - viewport_size / 2.0) / (viewport_size / 2.0)
	mouse_offset = mouse_offset.clamp(Vector2(-1, -1), Vector2(1, 1))

	# 鼠标控制目标偏移
	var mouse_target = mouse_offset * offset_strength

	# 加上一个正弦波动的偏移（即使鼠标静止也在动）
	var idle_wave = Vector2(
		sin(time_passed * idle_float_speed),
		cos(time_passed * idle_float_speed * 0.8)
	) * idle_float_amplitude

	target_offset = mouse_target + idle_wave

	# 平滑插值偏移
	offset = offset.lerp(target_offset, delta * smooth_speed)
