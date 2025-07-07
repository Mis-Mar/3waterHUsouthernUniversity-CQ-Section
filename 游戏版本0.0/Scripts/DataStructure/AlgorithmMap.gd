# AlgorithmMap.gd
# 算法地图继承自fullmap，因为有 例如 价值点 这种新的维度，需要新的变量
extends PlayerMap
class_name AlgorithmMap

# 原始地图只读引用，用于获取真实游戏状态（注意只是引用，不要做更改）
var player_map: PlayerMap
var general_id: int

# 算法专用的附加内容（这只是示例，看你需要什么用什么类型）
var value_map: Dictionary = {}  # 己方节点=power，敌方节点=-power，山地=-INF，未知空地水域=0
var distance_map: Dictionary = {}

# 初始化AlgorithmMap 用一个PlayerMap
func _init(original: PlayerMap, _general_id: int) -> void:
	player_map = original
	self.general_id = general_id
	player_id = original.player_id
	cell_map.clear()
	# 引用 general_id_to_player_id 映射（深拷贝，避免污染）
	general_id_to_player_id = original.general_id_to_player_id
	invis_state_map = original.invis_state_map
	general_to_capital = original.general_to_capital
	city_position_to_id = original.city_position_to_id
	city_id_to_position = original.city_id_to_position
	city_id_to_general = original.city_id_to_general
	city_id_of_general = original.city_id_of_general
	# 直接引用原地图的cellinfo
	cell_map=original.cell_map
	turn_count = original.turn_count
	
	# valuemap,distancemap更新未知节点
	for coord in original.invis_state_map:
	#HACK bug from,why main city in invis_state_map
		if invis_state_map[coord] == Global.INVIS_MOUNTAIN:
			value_map[coord] = -INF
		else:
			value_map[coord] = 0
		distance_map[coord] = INF
	#HACK 待完成 添加对敌方未知的预估功能，maybe in  set_value()？
	# valuemap,distancemap更新已知节点
	for coord in original.cell_map.keys():
		if self.get_cell(coord).get_type() == Global.TERRAIN_MOUNTAIN:
			value_map[coord] = -INF
		elif general_id_to_player_id[self.get_cell(coord).get_general_id()] == player_id:
			value_map[coord] = self.get_cell(coord).get_power()
		else:
			value_map[coord] = -self.get_cell(coord).get_power()
		distance_map[coord] = INF
	
	# 拷贝当前回合数
	print("此时的basemap")
	print(player_map.cell_map.keys())
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
