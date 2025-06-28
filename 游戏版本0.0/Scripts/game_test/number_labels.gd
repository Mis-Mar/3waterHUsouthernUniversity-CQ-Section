#每个数字都有单独的label，这个节点存储了这些label，然后封装了方法
extends Control

@onready var main_layer: TileMapLayer = $"../MainLayer"
@onready var color_layer: TileMapLayer = $"../ColorLayer"

var labels := {}  # 用于记录每个 tile 的 label: Dictionary<Vector2i, Label>

var CHAR_WIDTH = 85
var DEFAULT_LABEL_FONT_SIZE=200
var DEFAULT_LABEL_COLOR=Color(1, 1, 1)
# 显示某格子数字（底层封装）
func _create_label_on_tile(tile_coords: Vector2i, number: int, font_size: int, color: Color) -> void:
	# 如果已有 label，先删掉
	if labels.has(tile_coords):
		labels[tile_coords].queue_free()
		labels.erase(tile_coords)
	var label := Label.new()
	label.text = str(number)
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# 格子中心位置
	var tile_local_pos = main_layer.map_to_local(tile_coords)
	var global_pos = main_layer.to_global(tile_local_pos)
	var screen_pos = get_viewport().get_final_transform() * global_pos
	# 字符宽度计算
	var digit_count = str(number).length()
	var total_text_width = digit_count * (CHAR_WIDTH)
	# 坐标居中偏移
	label.position = screen_pos - Vector2(float(total_text_width) / 2.0, CHAR_WIDTH * 1.3)
	add_child(label)
	labels[tile_coords] = label



# ————————————————————外部接口部分
# 更新某格子的数字
func update_label_on_tile(tile_coords: Vector2i,number: int) -> void:
	_create_label_on_tile(tile_coords, number, DEFAULT_LABEL_FONT_SIZE, DEFAULT_LABEL_COLOR)
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
