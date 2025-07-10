extends Node2D

@onready var color_layer: TileMapLayer = $loading_map/ColorLayer
@onready var loading_timer: Timer = $loading_map/loading_timer


# 材质ID用 0, 图块坐标用你说的格式
var loading_hex_coords: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, -1),
	Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 1)
]

var current_index: int = 0

func _ready():
	loading_timer.timeout.connect(_on_loading_timer_timeout)
	loading_timer.start()
	_update_loading_tile()

func _on_loading_timer_timeout():
	current_index = (current_index + 1) % loading_hex_coords.size()
	_update_loading_tile()

func _update_loading_tile():
	color_layer.clear()
	# 设置当前 tile，使用材质 ID = 0，图集坐标 (0, 0)，默认替代 tile = 0
	var current_coord = loading_hex_coords[current_index]
	color_layer.set_cell(current_coord, 0, Vector2i(0, 0), 0) # 图块ID 0，图集坐标 (0,0)
