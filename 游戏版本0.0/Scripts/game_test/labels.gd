#每个数字都有单独的label，这个节点存储了这些label，然后封装了方法
extends Control


@onready var color_layer: TileMapLayer = $"../ColorLayer"
@onready var map: Control = $".."


var number_labels := {}  # 用于记录每个 tile 的 label: Dictionary<Vector2i, Label>
var arrow_labels: Array[Label] = []
var CHAR_WIDTH = 85
var DEFAULT_LABEL_FONT_SIZE=200

var ARROW_SIZE=200
# 角度和方向的对应关系
const HEX_DIRECTION_ANGLES := [120, 60, 0, 300, 240, 180]
# 箭头显示的居中偏移量
const HEX_DIRECTION_OFFSETS := [
	Vector2(312, 118),   # DIR_DOWM_R
	Vector2(260, -220),   # DIR_UP_R
	Vector2(-55, -320), # DIR_UP
	Vector2(-312, -118),   # DIR_UP_L
	Vector2(-260, 220),    # DIR_DOWM_L
	Vector2(55, 320)    # DIR_DOWN
]

var DEFAULT_LABEL_COLOR=Color(1, 1, 1)# 标签颜色
# 显示某格子数字（底层封装）
func deep_update_label_on_tile(tile_coords: Vector2i, text: String, font_size: int, color: Color) -> void:
	var label: Label
	# 检查这个坐标，有label就复用
	if number_labels.has(tile_coords):
		label = number_labels[tile_coords]
		# 检查是否需要更新
		var current_text := label.text
		var current_font_size := label.get_theme_font_size("font_size")
		var current_color := label.modulate

		if current_text == text and current_font_size == font_size and current_color == color:
			return  # 所有属性都一样，不需要更新
	else:
		label = Label.new()
		label.add_theme_font_size_override("font_size", font_size)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(label)
		number_labels[tile_coords] = label
	# 更新 label 内容
	label.text = text
	label.modulate = color
	# 格子中心位置
	var tile_local_pos = map.main_layer.map_to_local(tile_coords)
	var global_pos = map.main_layer.to_global(tile_local_pos)
	var screen_pos = get_viewport().get_final_transform() * global_pos
	# 文本宽度估计（使用固定字符宽度估计）
	var total_text_width = text.length() * CHAR_WIDTH
	# 坐标居中偏移
	label.position = screen_pos - Vector2(float(total_text_width) / 2.0, CHAR_WIDTH * 1.3)



# ————————————————————外部接口部分

# 更新某格子的数字
func update_label_on_tile(tile_coords: Vector2i, text: String) -> void:
	deep_update_label_on_tile(tile_coords, text, DEFAULT_LABEL_FONT_SIZE, DEFAULT_LABEL_COLOR)
# 清除所有数字
func clear_all_numbers() -> void:
	for label in number_labels.values():
		label.queue_free()
	number_labels.clear()
	print("测试箭头")
# 绘制某格某方向的箭头
func draw_arrow_label(tile_coords: Vector2i, direction_index: int) -> void:
	if direction_index < 0 or direction_index >= Global.HEX_DIRECTIONS.size():
		push_error("Invalid direction index")
		return

	var label := Label.new()
	label.text = "↑"
	label.add_theme_font_size_override("font_size", DEFAULT_LABEL_FONT_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = DEFAULT_LABEL_COLOR
	label.rotation_degrees = HEX_DIRECTION_ANGLES[direction_index]

	var base_local_pos = map.main_layer.map_to_local(tile_coords)
	var base_global_pos = map.main_layer.to_global(base_local_pos)
	var base_screen_pos =get_viewport().get_final_transform() * base_global_pos

	var offset: Vector2 = HEX_DIRECTION_OFFSETS[direction_index]
	label.position = base_screen_pos + offset

	add_child(label)
	arrow_labels.append(label)  # 记录引用
# 清除所有箭头
func clear_all_arrows() -> void:
	for label in arrow_labels:
		if is_instance_valid(label):
			label.queue_free()
	arrow_labels.clear()

# 清除指定格子的数字
func clear_label_on_tile(tile_coords: Vector2i) -> void:
	if number_labels.has(tile_coords):
		number_labels[tile_coords].queue_free()
		number_labels.erase(tile_coords)
