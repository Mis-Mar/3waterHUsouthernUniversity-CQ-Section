#每个数字都有单独的label，这个节点存储了这些label，然后封装了方法
extends Control

@onready var main_layer: TileMapLayer = $"../MainLayer"
@onready var color_layer: TileMapLayer = $"../ColorLayer"

var labels := {}  # 用于记录每个 tile 的 label: Dictionary<Vector2i, Label>
var CHAR_WIDTH = 85
var DEFAULT_LABEL_FONT_SIZE=200
# var CHAR_WIDTH = 40
# var DEFAULT_LABEL_FONT_SIZE=80
var DEFAULT_LABEL_COLOR=Color(1, 1, 1)# 标签颜色
# 显示某格子数字（底层封装）
func deep_update_label_on_tile(tile_coords: Vector2i, text: String, font_size: int, color: Color) -> void:
	var label: Label
	# 检查这个坐标，有label就复用
	if labels.has(tile_coords):
		label = labels[tile_coords]
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
		labels[tile_coords] = label
	# 更新 label 内容
	label.text = text
	label.modulate = color
	# 格子中心位置
	var tile_local_pos = main_layer.map_to_local(tile_coords)
	var global_pos = main_layer.to_global(tile_local_pos)
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
func clear_all_labels() -> void:
	for label in labels.values():
		label.queue_free()
	labels.clear()
# 清除指定格子的数字
func clear_label_on_tile(tile_coords: Vector2i) -> void:
	if labels.has(tile_coords):
		labels[tile_coords].queue_free()
		labels.erase(tile_coords)
