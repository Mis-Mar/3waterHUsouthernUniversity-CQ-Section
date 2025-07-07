extends Node
class_name DefenceAgent

var agent_tpye: String = "Defence"
var search_algorithm: M2S_SearchAlgorithm
var algorithm_map: AlgorithmMap
var main_city: Vector2i

const CONCENTRATION := 2

var general: General_Entity
var player_id: int
var player_map: PlayerMap
var distance_map: Dictionary

var block_point : Dictionary #Dictionary嵌套Array构成二维数组，第一维blockid，第二维pointpos
var point_to_block : Dictionary #vector2i to blockid 逆向索引
var edge_count_block : Dictionary #blockid 到 边总数的索引
var block_count : int = 0 # start with 1

var city_id_reachable : Array[int]
var city_id_invaded : Array[int]
var city_id_abandoned : Array[int]

var crucial_point_reachable : Array[Vector2i]
var crucial_point_invaded : Array[Vector2i]
var crucial_point_abandoned : Array[Vector2i]

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
		point_to_block[coord] = 0

func run() -> void:
	pass

func DIV_general_zone() -> void:
	general.zone_of_general.clear()
	var visited: Dictionary
	for pos in player_map.cell_map:
		visited[pos] = false
	var queue: Array[Vector2i] = [main_city]
	visited[main_city] = true
	# 开始BFS遍历
	while not queue.is_empty():
		var current = queue.pop_front()  # 从队列头部取出
		visited[current] = true
		if player_map.get_cell(current).get_general_id() == general.general_id:
			#内层BFS，获得区块
			if point_to_block[current] == 0:
				build_block(current)
		if player_map.invis_state_map[current] == Global.TERRAIN_CITY :
			general.city_id_in_zone.append(player_map.city_position_to_id[current])
		if current in general.crucial_point_list and player_map.get_cell(current).get_general_id() == general.general_id:
			general.crucial_point_of_general.append(current)
		# 获取所有邻居
		var neighbors = player_map.get_neighbors_state5(current,general.general_id)
		for neighbor in neighbors:
			# 如果邻居尚未访问过 (距离为无穷大)
			if visited[neighbor] == false:
				# 将邻居加入队列
				queue.append(neighbor)
				general.zone_of_general.append(neighbor)
	#计算general总拥有
	for block in block_point:
		general.point_of_general.append_array(block_point[block])
		general.edge_of_general += edge_count_block[block]
	general.calculate_full_power()
	general.calculate_mean_power()
	general.calculate_connection_degree()
	#TODO check again

func build_block(start_point: Vector2i) -> void:
	block_count += 1
	point_to_block[start_point] = block_count
	block_point[block_count] = []
	block_point[block_count].append(start_point)
	var queue: Array[Vector2i] = [start_point]
	# 开始BFS遍历
	while not queue.is_empty():
		var current = queue.pop_front()  # 从队列头部取出
		if point_to_block[current] == 0:
			point_to_block[current] = block_count
			block_point[block_count].append(current)
		# 获取所有邻居
		var neighbors = player_map.get_neighbors_state1(current,general.general_id)
		for neighbor in neighbors:
			if point_to_block[current] == 0:
				# 将邻居加入队列
				queue.append(neighbor)
				edge_count_block[block_count] += 1

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

func is_city_occupyed(ratio_param: float) -> bool:
	for city_id in general.city_id_in_zone:
		if city_id not in general.city_id_of_general:
			city_id_invaded.append(city_id)
	if general.city_id_of_general.size() >= general.city_id_in_zone.size() * ratio_param:
		return true
	else:
		#TODO DOSOMETHING
		return false

func is_crucial_point_occupyed(ratio_param: float) -> bool:
	for crucial_point in general.crucial_point_list:
		if crucial_point not in general.crucial_point_of_general:
			crucial_point_invaded.append(crucial_point)
	if general.crucial_point_of_general.size() >= general.crucial_point_list.size() * ratio_param:
		return true
	else:
		#TODO DOSOMETHING
		return false

func is_city_path_reachable(ratio_param: float) -> bool:
	for city_id in general.city_id_of_general:
		if distance_map[player_map.city_id_to_position[city_id]] != INF:
			city_id_reachable.append(city_id)
		else:
			city_id_abandoned.append(city_id)
	if city_id_reachable.size() >= general.city_id_of_general.size() * ratio_param:
		return true
	else:
		#TODO DOSOMETHING
		return false

func is_crucial_point_reachable(ratio_param: float) -> bool:
	for crucial_point in general.crucial_point_list:
		if distance_map[crucial_point] != INF:
			crucial_point_reachable.append(crucial_point)
		else:
			crucial_point_abandoned.append(crucial_point)
	if  crucial_point_reachable.size() >= general.crucial_point_list.size() * ratio_param:
		return true
	else:
		#TODO 完成动作
		return false
	
func general_zone_fill() -> void:
	#TODO 维护general的zone_of_general
	pass

func defend_main_city(demand_param: float,range_threshold: int) -> void:
	self.concentrate_power(main_city,demand_param,range_threshold)
	#TODO 更多可写？

func concentrate_power(target_point: Vector2i,demand_param: float,range_threshold: int) -> void:
	var avaliable_power: int = 0
	for city_id in general.city_id_of_general:
		avaliable_power += algorithm_map.value_map[player_map.city_id_to_position[city_id]]
	for crucial_point in general.crucial_point_of_general:
		avaliable_power += algorithm_map.value_map[crucial_point]
	var path = search_algorithm.M2S_Search(target_point,avaliable_power * demand_param,3,1,10,range_threshold)
	if path != [-1]:
		path = search_algorithm.get_all_coords()
		self.path_add.emit(self.CONCENTRATION, path)

func hunt_enemy_power() -> void:
	#TODO 先集中再A*索敌
	pass

func path_manager() -> void:
	#TODO 改写这块
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
	#TODO 改写这块
	if(_path_class != 0):
		for AR in path_operations:
			if(AR[0] == 0):
				path_operations.erase(AR)
	for _path_operate in _path_operations:
		var AY: Array = [_path_class,_path_operate]
		self.path_operations.append_array(AY)
	path_manager()
