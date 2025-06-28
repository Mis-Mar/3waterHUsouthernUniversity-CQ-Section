# AlgorithmMap.gd
# 算法地图继承自fullmap，因为有 例如 价值点 这种新的维度，需要新的变量
extends FullMap
class_name AlgorithmMap

# 原始地图只读引用，用于获取真实游戏状态（注意只是引用，不要做更改）
var base_map: FullMap

# ——除了原fullmap的引用，AlgorithmMap自己继承了fullmap的所有变量（如下），可以随便改
#var grid_map: Dictionary = {}  # Dictionary<Vector2i, GridCell>所有格子的字典，就当CellInfo类型的二维数组来用
#var owner_to_player: Dictionary = {}# 表格，一个owner有一个player，一个player对应多个owner 值为0表示未被控制,-1表示已经消灭
#var turn_count: int = 0  # 回合总数
#const HEX_DIRECTIONS := [# 六边形邻接向量，见global.gd有全局变量
	#Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1),
	#Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0)
#]

# 算法专用的附加内容（这只是示例，看你需要什么用什么类型）
var value_map: Dictionary = {}  # 例如影响力、评分

# 初始化AlgorithmMap 用一个fullmap
func _init(original: FullMap) -> void:
	base_map = original
	grid_map.clear()
	# 拷贝格子数据
	for coord in original.grid_map.keys():
		grid_map[coord] = original.grid_map[coord].clone()
		# 示例，获取所有格子构造value_map初始化value为0
		value_map[coord] = 0
	# 拷贝 owner_to_player 映射（深拷贝，避免污染）
	owner_to_player = {}
	for key in original.owner_to_player.keys():
		owner_to_player[key] = original.owner_to_player[key]
	# 拷贝当前回合数
	turn_count = original.turn_count

# 示例：设置某个坐标的value
func set_value(coord: Vector2i, val: int) -> void:
	value_map[coord] = val

# 示例：获取某个坐标的value
func get_value(coord: Vector2i) -> int:
	return value_map.get(coord, 0)

# get_neighbors函数等  fullmap和AlgorithmMap都需要的基础函数请见fullmap
