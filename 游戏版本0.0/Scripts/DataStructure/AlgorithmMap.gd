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
var distance_map: Dictionary = {}

# 初始化AlgorithmMap 用一个fullmap
func _init(original: FullMap) -> void:
	base_map = original
	grid_map.clear()
	# 拷贝格子数据
	for coord in original.grid_map.keys():
		grid_map[coord] = original.grid_map[coord].clone()
		# 示例，获取所有格子构造value_map初始化value为0
		value_map[coord] = self.get_cell(coord).power
		distance_map[coord] = INF
	# 拷贝 owner_to_player 映射（深拷贝，避免污染）
	owner_to_player = {}
	for key in original.owner_to_player.keys():
		owner_to_player[key] = original.owner_to_player[key]
	# 拷贝当前回合数
	turn_count = original.turn_count

# 示例：设置某个坐标的value
func set_value(coord: Vector2i, val: float) -> void:
	value_map[coord] = val

# 示例：获取某个坐标的value
func get_value(coord: Vector2i) -> float:
	return value_map.get(coord, 0)

func set_distance(coord: Vector2i, dis :int) -> void:
	distance_map[coord] = dis
	
func get_distance(coord: Vector2i) -> int:
	return distance_map.get(coord, 0)
# get_neighbors函数等  fullmap和AlgorithmMap都需要的基础函数请见fullmap

# 在 AlgorithmMap.gd 中添加以下方法

func bfs_distance(start_node: Vector2i) -> void:
	# 重置所有距离为无穷大
	for coord in distance_map.keys():
		distance_map[coord] = INF
	# 初始化起点距离为0
	distance_map[start_node] = 0
	# 创建队列 (使用数组模拟队列)
	var queue: Array[Vector2i] = [start_node]
	# 开始BFS遍历
	while not queue.is_empty():
		var current = queue.pop_front()  # 从队列头部取出
		var current_distance = distance_map[current]
		# 获取所有邻居
		var neighbors = self.get_neighbors_state0(current)
		for neighbor in neighbors:
			# 如果邻居尚未访问过 (距离为无穷大)
			if distance_map[neighbor] == INF:
				# 更新邻居距离
				distance_map[neighbor] = current_distance + 1
				# 将邻居加入队列
				queue.append(neighbor)
