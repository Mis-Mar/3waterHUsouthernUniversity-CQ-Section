extends Node
class_name DefenceAgent

var agent_tpye: String = "Defence"
var search_algorithm: M2S_SearchAlgorithm
var algorithm_map: AlgorithmMap
var main_city: Vector2i

var auto_HUNT_defend: bool = false
var current_state: int = self.STATE_SLEEP

const STATE_SLEEP := 0
const STATE_ZONE_DIV := 1
const STATE_MAIN_GATHER := 2
const STATE_HUNT_DEFEND := 3
const STATE_NORMAL_GATHER := 4
const STATE_CITY_DEFEND := 5
const STATE_CPOINT_DEFEND := 6
const STATE_CITY_ACHIEVE := 7
const STATE_CPOINT_ACHIEVE := 8
const STATE_EMPTY_DEFEND := 9
const STATE_REMAIN_POWER_DEAL := 10

const PATHCLASS_CONCENTRATION := 2
const PATHCLASS_OCCUPYCITY := 3
const PATHCLASS_OCCUPYCPOINT := 4
const PATHCLASS_CONNECTCITY := 5
const PATHCLASS_CONNECTCPOINT := 6
const PATHCLASS_OCCUPYEMPTY := 7
const PATHCLASS_MOVETOCITY := 8

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

var path_operations: PriorityQueue
var path_current_class: int = -1 #当前path_manager操作等级

var is_path_manager_working: bool = false

signal path_add(path_class: int, _path_operations: Array)
signal end_manual_concentrate()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	path_add.connect(on_path_add)
	general.general_occupy_cell.connect(block_updated_positive)
	general.general_occupy_cell.connect(on_be_occupied_cell)

func _init(_main_city: Vector2i, _player_map: PlayerMap,_general:General_Entity) -> void:
	general=_general
	self.player_id = general.player_id
	self.main_city = _main_city
	self.player_map = _player_map
	self.current_state = self.STATE_SLEEP
	algorithm_map = AlgorithmMap.new(self.player_map, general.general_id)
	search_algorithm = M2S_SearchAlgorithm.new(self.algorithm_map)
	for coord in player_map.cell_map:
		distance_map[coord] = INF
		point_to_block[coord] = 0

func clear_path_list() -> void:
	self.path_operations.clear()
	self.path_current_class = -1
	self.is_path_manager_working = false

func defend_class_trend() -> void:
	self.current_state = self.STATE_SLEEP
	self.clear_path_list()
	self.bfs_path_build()
	self.DIV_general_zone()
	self.is_city_occupyed(1.0)
	self.is_crucial_point_occupyed(1.0)
	self.is_city_path_reachable(1.0)
	self.is_crucial_point_reachable(1.0)
	self.general_zone_fill(1.0)
	#HACK 根据区域内敌我兵力数量对比设置ratio
	self.current_state = self.STATE_SLEEP
	
func urgent_defend_class_trend() -> void:
	self.current_state = self.STATE_SLEEP
	self.clear_path_list()
	self.bfs_path_build()
	self.is_city_occupyed(1.0)
	self.is_crucial_point_occupyed(1.0)
	self.DIV_general_zone()
	self.is_city_path_reachable(1.0)
	self.is_crucial_point_reachable(1.0)
	self.general_zone_fill(1.0)
	#HACK 根据区域内敌我兵力数量对比设置ratio
	self.current_state = self.STATE_SLEEP

func defend_main_city(demand_param: float,range_threshold: int) -> void:
	self.current_state = self.STATE_MAIN_GATHER
	self.concentrate_power(main_city,demand_param,range_threshold)
	self.current_state = self.STATE_SLEEP
#TODO 更多可写？

#HACK 待完成 单独写函数控制王城防御和集中,使用信号调用，对应ui

func concentrate_power(target_point: Vector2i,demand_param: float,range_threshold: int) -> void:
	var start_state : int
	if target_point == main_city:
		self.current_state = self.STATE_MAIN_GATHER
		start_state = self.STATE_MAIN_GATHERn
	else:
		self.current_state = self.STATE_NORMAL_GATHER
		start_state = self.STATE_NORMAL_GATHER
	var avaliable_power: int = 0
	for city_id in general.city_id_of_general:
		avaliable_power += algorithm_map.value_map[player_map.city_id_to_position[city_id]]
	for crucial_point in general.crucial_point_of_general:
		if crucial_point not in general.city_id_of_general:
			avaliable_power += algorithm_map.value_map[crucial_point]
	var path = search_algorithm.M2S_Search(target_point,avaliable_power * demand_param,3,1,10,range_threshold)
	if path != [-1]:
		path = search_algorithm.get_path_action()
		if self.current_state != start_state:
			return
		self.path_add.emit(self.PATHCLASS_CONCENTRATION, path)
	self.current_state = self.STATE_SLEEP
	self.end_manual_concentrate.emit()

func DIV_general_zone() -> void:
	self.current_state = self.STATE_ZONE_DIV
	#建立复杂度 O（n2），故只可用于初始化，之后动态更新
	general.zone_of_general.clear()
	block_count = 0
	point_to_block.clear()
	block_point.clear()
	edge_count_block.clear()
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
	self.current_state = self.STATE_SLEEP


func block_updated_positive(pos:Vector2i,_cell_info:CellInfo,enemy_general_id:int) -> void:
	#接受更新，动态更新block，仅当拓展时使用
	var neighbors = player_map.get_neighbors_state1(pos,general.general_id)
	var near_block: Array[int]
	for neighbor in neighbors:
		if point_to_block[neighbor] not in near_block:
			near_block.append(point_to_block[neighbor])
	
	if near_block.is_empty():
		#孤立节点
		block_count += 1
		point_to_block[pos] = block_count
		block_point[block_count].append(pos)
		edge_count_block[block_count] = 0
	else:
		var min_block_id: int = near_block.min()
		block_point[min_block_id].append(pos)
		near_block.erase(min_block_id)
		for block in near_block:
			for point in block_point[block]:
				point_to_block[point] = min_block_id
				block_point[min_block_id].append(point)
			block_point[block].clear()
			edge_count_block[min_block_id]  += edge_count_block[block]
			edge_count_block[block] = 0
		point_to_block[pos] = min_block_id
		edge_count_block[min_block_id]  += neighbors.size()

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
	self.current_state = self.STATE_CITY_DEFEND
	for city_id in general.city_id_in_zone:
		if city_id not in general.city_id_of_general:
			city_id_invaded.append(city_id)
	if general.city_id_of_general.size() >= general.city_id_in_zone.size() * ratio_param:
		return true
	else:
		#occupy_invaded_city
		return false
	self.current_state = self.STATE_SLEEP


func occupy_invaded_city() -> void:
	self.current_state = self.STATE_CITY_DEFEND
	var path_all: Dictionary = {}
	var min_path_id: int = -1
	for target_city_id in city_id_invaded:
		var target_city_pos = player_map.city_id_to_position[target_city_id]
		var demand: int = player_map.get_cell(target_city_pos).get_power()
		path_all[target_city_id] = search_algorithm.M2S_Search(target_city_pos,demand,3,1,10,50)
		#HACK 待完成 写 range阈值和参数设置
		if path_all[target_city_id] != [-1]:
			path_all[target_city_id] = search_algorithm.get_path_action()
			if min_path_id == -1 or path_all[target_city_id].size() < path_all[min_path_id].size():
				min_path_id = target_city_id
	if self.current_state != self.STATE_CITY_DEFEND:
		return
	if min_path_id != -1:
		self.path_add.emit(self.PATHCLASS_OCCUPYCITY, path_all[min_path_id])
	self.current_state = self.STATE_SLEEP


func is_crucial_point_occupyed(ratio_param: float) -> bool:
	self.current_state = self.STATE_CPOINT_DEFEND
	for crucial_point in general.crucial_point_list:
		if crucial_point not in general.crucial_point_of_general:
			crucial_point_invaded.append(crucial_point)
	if general.crucial_point_of_general.size() >= general.crucial_point_list.size() * ratio_param:
		return true
	else:
		#occupy_invaded_Cpoint
		return false
	self.current_state = self.STATE_SLEEP


func occupy_invaded_Cpoint() -> void:
	self.current_state = self.STATE_CPOINT_DEFEND
	var path_all: Dictionary = {}
	var min_path_id: Vector2i = crucial_point_invaded[0]
	for target_Cpoint in crucial_point_invaded:
		var demand: int = player_map.get_cell(target_Cpoint).get_power()
		path_all[target_Cpoint] = search_algorithm.M2S_Search(target_Cpoint,demand,3,1,10,50)
		#HACK 待完成 写 range阈值和参数设置
		if path_all[target_Cpoint] != [-1]:
			path_all[target_Cpoint] = search_algorithm.get_path_action()
			if path_all[target_Cpoint].size() < path_all[min_path_id].size():
				min_path_id = target_Cpoint
	if self.current_state != self.STATE_CPOINT_DEFEND:
		return
	if path_all[min_path_id] != [-1]:
		self.path_add.emit(self.PATHCLASS_OCCUPYCPOINT, path_all[min_path_id])
	self.current_state = self.STATE_SLEEP


func is_city_path_reachable(ratio_param: float) -> bool:
	self.current_state = self.STATE_CITY_ACHIEVE
	for city_id in general.city_id_of_general:
		if distance_map[player_map.city_id_to_position[city_id]] != INF:
			city_id_reachable.append(city_id)
		else:
			city_id_abandoned.append(city_id)
	if city_id_reachable.size() >= general.city_id_of_general.size() * ratio_param:
		return true
	else:
		return false
	self.current_state = self.STATE_SLEEP


func connect_abandoned_city(city_id: int):
	self.current_state = self.STATE_CITY_ACHIEVE
	var city_pos: Vector2i = player_map.city_id_to_position[city_id]
	var city_block: int = point_to_block[city_pos]
	self.dynamic_kamikaze_search_block(main_city,city_block,self.CITY_ACHIEVE)
	#TODO anything else?
	self.current_state = self.STATE_SLEEP


func is_crucial_point_reachable(ratio_param: float) -> bool:
	self.current_state = self.STATE_CPOINT_ACHIEVE
	for crucial_point in general.crucial_point_list:
		if distance_map[crucial_point] != INF:
			crucial_point_reachable.append(crucial_point)
		else:
			crucial_point_abandoned.append(crucial_point)
	if  crucial_point_reachable.size() >= general.crucial_point_list.size() * ratio_param:
		return true
	else:
		return false
	self.current_state = self.STATE_SLEEP


func connect_abandoned_Cpoint(Cpoint: int):
	self.current_state = self.STATE_CPOINT_ACHIEVE
	var Cpoint_block: int = point_to_block[Cpoint]
	self.dynamic_kamikaze_search_block(main_city,Cpoint_block,self.CPOINT_ACHIEVE)
	#TODO anything else?
	self.current_state = self.STATE_SLEEP


func general_zone_fill(ratio: float) -> void:
	self.current_state = self.STATE_EMPTY_DEFEND
	var unoccupied_points: Array[Vector2i]
	for point in general.zone_of_general:
		if player_map.invis_state_map[point] != Global.TERRAIN_MOUNTAIN:
			if point not in general.point_of_general:
				unoccupied_points.append(point)
	while general.point_of_general.size() < general.zone_of_general.size() * ratio:
		var point: Vector2i = unoccupied_points.pop_front()
		var achieve: bool = false
		if player_map.cell_map.has(point):
			for neighbor in player_map.get_neighbors_state6(point,general.general_id):
				if player_map.get_cell(neighbor).get_power() > player_map.get_cell(point).get_power() + 1:
					if self.current_state != self.STATE_EMPTY_DEFEND:
						return
					#中断操作
					self.path_add.emit(self.PATHCLASS_OCCUPYEMPTY,[{
						"from": neighbor,
						"dir": neighbor - point,
						"ratio": 1.0
					}])
					await player_map.turn_updated
					if self.current_state != self.STATE_EMPTY_DEFEND:
						return
					if player_map.get_cell(point).get_general_id() in player_map.general_id_to_player_id[general.player_id]:
						achieve = true
					break
		if not achieve:
			unoccupied_points.append(point)
	self.current_state = self.STATE_SLEEP

func hunt_enemy_power() -> void:
	self.current_state = self.STATE_HUNT_DEFEND
	#HACK 待完成 先集中再A*索敌
	self.current_state = self.STATE_SLEEP
	
func dynamic_kamikaze_search_block(start_point: Vector2i, target_block: int,start_state: int) -> void:
	self.current_state = start_state
	#动态kamikaze搜索方法,抵达某个区域
	var visited: Array[Vector2i] = [start_point]
	var sight_range: Array = [1]
	var cell: CellInfo = player_map.get_cell(start_point)
	var direction: Vector2i
	while cell.get_power() > 1:

		direction = Block_points_in_sight_direction(start_point, sight_range, target_block)
		if self.current_state != start_state:
			return
		self.path_add.emit(self.PATHCLASS_CONNECTCITY if start_state==self.STATE_CITY_ACHIEVE else self.PATHCLASS_CONNECTCPOINT,[{
			"from": start_point,
			"dir": direction,
			"ratio": 1.0
		}])
		start_point += direction
		await player_map.turn_updated
		await general.general_occupy_cell
		if self.current_state != start_state:
			return
		if point_to_block[target_block].is_empty():
			self.move_power_to_nearest_city(start_point)
			return
		cell = player_map.get_cell(start_point)
	self.current_state = self.STATE_SLEEP

func Block_points_in_sight_direction(start_point: Vector2i, sight_range: Array, target_block: int) -> Vector2i:
	#动态更新sight方法
	var cells_in_sight: Array[Vector2i] = player_map.spiral_rings_traversal(start_point, sight_range[0])
	
	var direction_count_tarBlock: Dictionary = {} #记录视野内含block节点数
	var direction_count_cost: Dictionary = {} #记录视野内节点总代价:value_map,敌负我正
	var sum_count_tarBlock: int
	var sum_count_cost: int
	var direction_ratio_tarBlock: Dictionary = {}
	var direction_ratio_cost: Dictionary = {}
	var direction_final_ratio: Dictionary = {}
	
	for direction in Global.HEX_DIRECTIONS:
		direction_count_tarBlock[direction] = 0
		direction_count_cost[direction] = 0
		
	var max_block_direction: Vector2i = Vector2i(1,0)
	var max_direction: Vector2i = Vector2i(1,0)
	
	for coord in cells_in_sight:
		var direction:Vector2i = player_map.get_direction(start_point, coord)
		if self.point_to_block[coord] == target_block:
			direction_count_tarBlock[direction] += 1
			if(direction_count_tarBlock[direction] > direction_count_tarBlock[max_block_direction]):
				max_block_direction = direction
		if player_map.invis_state_map[coord] != Global.TERRAIN_MOUNTAIN:
			direction_count_cost[direction] += algorithm_map.value_map[coord]
		
	while direction_count_tarBlock[max_block_direction] != 0:
		sight_range[0] += 1
		var new_sight: Array[Vector2i] = player_map.ring_traversal(start_point, sight_range[0])
		cells_in_sight.append(new_sight)
		for coord in new_sight:
			var direction:Vector2i = player_map.get_direction(start_point, coord)
			if self.point_to_block[coord] == target_block:
				direction_count_tarBlock[direction] += 1
				if(direction_count_tarBlock[direction] > direction_count_tarBlock[max_block_direction]):
					max_block_direction = direction
			if player_map.invis_state_map[coord] != Global.TERRAIN_MOUNTAIN:
				direction_count_cost[direction] += algorithm_map.value_map[coord]
				
	for direction in direction_count_tarBlock:
		sum_count_tarBlock += direction_count_tarBlock[direction]
		sum_count_cost += direction_count_cost[direction]
	for direction in direction_count_tarBlock:
		direction_ratio_tarBlock[direction] = float(direction_count_tarBlock[direction] / sum_count_tarBlock)
		direction_ratio_cost[direction] = float(direction_count_cost[direction] / sum_count_cost)
		direction_final_ratio[direction] = float(direction_ratio_tarBlock[direction] + direction_ratio_cost[direction])
		if direction_final_ratio[direction] > direction_final_ratio[max_direction]:
			if player_map.invis_state_map[start_point + max_direction] != Global.TERRAIN_MOUNTAIN:
				max_direction = direction
	return max_direction

func move_power_to_nearest_city(start_point: Vector2i) -> void:
	#直接general内A*最短路径，用于处理多余兵力
	self.current_state = self.STATE_REMAIN_POWER_DEAL
	var path_all: Dictionary = {}
	var min_path_id: int = -1
	for target_city_id in general.city_id_of_general:
		var target_city_pos = player_map.city_id_to_position[target_city_id]
		var coord_path = self.player_map.build_Astar_path_in_general(start_point,target_city_pos,general.general_id)
		if coord_path != [-1]:
			path_all[target_city_id] = self.player_map.coord_path_to_actions(coord_path)
			if min_path_id == -1 or path_all[target_city_id].size() < path_all[min_path_id].size():
				min_path_id = target_city_id
	if self.current_state != self.STATE_REMAIN_POWER_DEAL:
		return
	if min_path_id != -1:
		self.path_add.emit(self.PATHCLASS_MOVETOCITY, path_all[min_path_id])
	self.current_state = self.STATE_SLEEP

func path_manager() -> void:
	#两层循环，外层读取优先队列低优先级工作，内层逐步执行操作
	self.is_path_manager_working = true
	while !path_operations.is_empty():
		path_current_class = path_operations.peek_priority()
		var insert_replace: bool = false
		for path in path_operations.peek():
			if path_current_class != path_operations.peek_priority():
				insert_replace = true
				break
			general.agent_path_output.emit(agent_tpye,path)
			await player_map.turn_updated
		if not insert_replace:
			path_operations.pop()
	self.is_path_manager_working = false

func on_path_add(_path_class: int, _path_operations: Array) -> void:
	#读入新操作，删除正在进行的低优先级工作
	if _path_class < path_current_class or path_current_class == -1:
		path_operations.pop()
	path_operations.push(_path_class,_path_operations)
	if not is_path_manager_working:
		path_manager()

func on_be_occupied_cell(pos:Vector2i,_cell_info:CellInfo,enemy_general_id:int) -> void:
	#敌方入侵控制全局中断操作,回滚工作流状态
	if self.current_state == self.STATE_MAIN_GATHER or self.current_state == self.STATE_NORMAL_GATHER:
		await self.end_manual_concentrate
	if self.auto_HUNT_defend == true:
		hunt_enemy_power()
		#HACK 待完善hunt的使用
	if _cell_info.get_type() == Global.TERRAIN_CITY:
		self.urgent_defend_class_trend()
	else:
		self.defend_class_trend()
	#TODO 检查是否这样即可？divzone是否可优化？
