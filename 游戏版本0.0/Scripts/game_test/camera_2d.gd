extends Camera2D

var is_dragging := false
var drag_start_mouse := Vector2()
var drag_start_position := Vector2()

# 缩放限制
const ZOOM_MIN := 0.01
const ZOOM_MAX := 0.5
const ZOOM_SPEED := 0.1
const ZOOM_LERP_SPEED := 7.0  # 插值速度，值越大缩放越快

var target_zoom: Vector2 = Vector2.ONE  # 初始目标

func _ready():
	target_zoom = zoom  # 初始化为当前 zoom

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# 拖动摄像机
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_dragging = true
				drag_start_mouse = event.position
				drag_start_position = global_position
			else:
				is_dragging = false

		# 滚轮缩放
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom *= 1.0 + ZOOM_SPEED
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom *= 1.0 - ZOOM_SPEED

		# 限制 zoom 范围（以 X 分量为准）
		var z = clamp(target_zoom.x, ZOOM_MIN, ZOOM_MAX)
		target_zoom = Vector2(z, z)

func _process(delta: float) -> void:
	# 平滑缩放（插值逼近目标 zoom）
	zoom = zoom.move_toward(target_zoom, delta * ZOOM_LERP_SPEED*zoom.x)

	# 拖动摄像机
	if is_dragging:
		var drag_offset = drag_start_mouse - get_viewport().get_mouse_position()
		global_position = drag_start_position + drag_offset / zoom
