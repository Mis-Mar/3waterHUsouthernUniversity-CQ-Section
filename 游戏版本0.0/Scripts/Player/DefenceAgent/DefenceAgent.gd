extends Node
class_name DefenceAgent

var agent_tpye: String = "Defence"
var search_algorithm: M2S_SearchAlgorithm
var algorithm_map: AlgorithmMap
var main_city: Vector2i

var general: General_Entity
var player_id: int
var player_map: PlayerMap
var distance_map: Dictionary

var crucial_point_list : Array[Vector2i]
var crucial_point_reachable : Array[Vector2i]
var city_id_reachable : Array[int]

var path_operations: Array
var path_class: int

signal path_add(path_class: int, _path_operations: Array[Vector2i])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	path_add.connect(on_path_add)

func _init(_main_city: Vector2i, _player_map: PlayerMap) -> void:
	self.player_id = general.player_id
	self.main_city = _main_city
	self.player_map = _player_map
	algorithm_map = AlgorithmMap.new(self.player_map, general.general_id)
	search_algorithm = M2S_SearchAlgorithm.new(self.algorithm_map)
	for coord in player_map.cell_map:
		distance_map[coord] = INF

func run() -> void:
	pass

func bfs_path_build() -> void:
	# 重置所有距离为无穷大
	for coord in distance_map.keys():
		distance_map[coord] = INF
	# 初始化起点距离为0
	distance_map[general.main_city] = 0
	# 创建队列 (使用数组模拟队列)
	var queue: Array[Vector2i] = [general.main_city]
	# 开始BFS遍历
	while not queue.is_empty():
		var current = queue.pop_front()  # 从队列头部取出
		var current_distance = distance_map[current]
		# 获取所有邻居
		var neighbors = player_map.get_neighbors_state1(current,general.general_id)
		for neighbor in neighbors:
			# 如果邻居尚未访问过 (距离为无穷大)
			if distance_map[neighbor] == INF:
				# 更新邻居距离
				distance_map[neighbor] = current_distance + 1
				# 将邻居加入队列
				queue.append(neighbor)

func is_city_path_reachable(ratio_param: float) -> bool:
	for city_id in player_map.city_id_of_general[general.general_id]:
		if distance_map[player_map.city_id_to_position[city_id]] != INF:
			city_id_reachable.append(city_id)
	if city_id_reachable.size() >= player_map.city_id_of_general[general.general_id].size() * ratio_param:
		return true
	else:
		#TODO 完成动作
		return false

func is_crucial_point_reachable(ratio_param: float) -> bool:
	for crucial_point in crucial_point_list:
		if distance_map[crucial_point] != INF:
			crucial_point_reachable.append(crucial_point)
	if  crucial_point_reachable.size() >= crucial_point_list.size() * ratio_param:
		return true
	else:
		#TODO 完成动作
		return false
	
func general_zone_fill() -> void:
	#维护general的zone_of_general
	pass

func path_manager() -> void:
	while !path_operations.is_empty():
		var AY: Array = path_operations.front()
		path_class = AY[0]
		while !path_operations.is_empty():
			AY = path_operations.front()
			if path_class == AY[0]:
				general.agent_path_output.emit(agent_tpye,AY[1])
			else:
				break
		#TODO 分类类比，单个输出
		pass

func on_path_add(_path_class: int, _path_operations: Array[Vector2i]) -> void:
	#读入新操作，删除优先级为0的操作（空地占领
	if(_path_class != 0):
		for AR in path_operations:
			if(AR[0] == 0):
				path_operations.erase(AR)
	for _path_operate in _path_operations:
		var AY: Array = [_path_class,_path_operate]
		self.path_operations.append(AY)
	path_manager()
