extends BaseState_ExpansionAgent
class_name State_SearchingEmptycity

var Not_Found: Array[Vector2i] = agent.Not_Found
var search_pattern: int = self.PATTERN_SLEEP

const PATTERN_SLEEP := 0
const PATTERN_M2S := 1
const PATTERN_KAMIKAZE := 2

signal place_into_notfound()

func _ready() -> void:
	place_into_notfound.connect(self.on_place_not_found)
	agent.general.general_find_city.connect(on_city_find)
	pass
	
func enter() -> void:
	Not_Found = agent.Not_Found
	search_pattern = self.PATTERN_SLEEP
	while true:
		#do while
		is_vision_sufficient()
		if Not_Found.is_empty():
			break
		else:
			self.place_into_notfound.emit()
	if !agent.Not_Occupy.is_empty():
		state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.EMPTYCITY_OCCUPY)
	else:
		state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.EXPANSION_COMPLETE)

func is_vision_sufficient() -> void:
	#添加可抵达城市（视野之外
	var distance_map: Dictionary = {}
	for coord in agent.player_map.invis_state_map.keys():
		distance_map[coord] = INF
	var queue: Array[Vector2i] = [main_city]
	distance_map[main_city] = 0
	# 开始BFS遍历
	while not queue.is_empty():
		var current = queue.pop_front()  # 从队列头部取出
		var current_distance = distance_map[current]
		if agent.player_map.invis_state_map[current] == Global.INVIS_MOUNTAIN:
			if current not in Not_Found:
				self.place_into_notfound.emit()
				Not_Found.append(current)
		else:
			# 获取所有邻居
			var neighbors = agent.player_map.get_neighbors_state2(current,agent.general.general_id)
			for neighbor in neighbors:
				# 如果邻居尚未访问过 (距离为无穷大)
				if distance_map[neighbor] == INF:
					# 更新邻居距离
					distance_map[neighbor] = current_distance + 1
					# 将邻居加入队列
					queue.append(neighbor)

func to_found_empty_city() -> void:
	#FIXME 选择搜索方式，M2S搜索或者kamikaze搜索
	while !Not_Found.is_empty():
		var target_point = Not_Found.pop_front()
		if !search_empty_city(target_point,2,20):
			Not_Found.append(target_point)
		#self.dynamic_kamikaze_search_Not_Found(main_city)
	self.search_pattern = self.PATTERN_SLEEP

func search_empty_city(target_point: Vector2i,jump_param: int,estimated_demand: int) -> bool:
	self.search_pattern = self.PATTERN_M2S
	#前往可抵达城市
	var path_point: Array[Vector2i] = agent.player_map.build_Astar_path(self.agent.general.main_city,target_point)
	while !path_point.is_empty():
		var path = agent.search_algorithm.M2S_Search(target_point,estimated_demand,3,1,20,20)
		#HACK 待完成 参数设置
		var path_action = agent.search_algorithm.get_path_action()
		if path != [-1]:
			path_action.pop_back()#去尾
			if self.search_pattern != self.PATTERN_M2S:
				return false
			send_path(path_action)
			return true
	return false

func kamikaze_search(start_point: Vector2i, sight_range: int) -> void:
	self.search_pattern = self.PATTERN_KAMIKAZE
	var visited: Array[Vector2i] = [start_point]
	#TODO 考虑是否有必要？
	var cell: CellInfo = agent.player_map.get_cell(start_point)
	var direction: Vector2i
	while cell.get_power() > 1:
		direction = Not_Found_in_sight_direction(start_point, sight_range)
		if self.search_pattern != self.PATTERN_KAMIKAZE:
			return
		send_path([{
			"from": start_point,
			"dir": direction,
			"ratio": 1.0
		}])
		start_point += direction
		await agent.player_map.turn_updated
		if self.search_pattern != self.PATTERN_KAMIKAZE:
			return
		cell = agent.player_map.get_cell(start_point)

func Not_Found_in_sight_direction(start_point: Vector2i, sight_range: int) -> Vector2i:
	var cells_in_sight: Array[Vector2i] = agent.player_map.spiral_rings_traversal(start_point, sight_range)
	var direction_count: Dictionary = {}
	direction_count[Vector2i(1,0)] = 0
	var max_direction: Vector2i = Vector2i(1,0)
	for coord in cells_in_sight:
		var direction:Vector2i = agent.player_map.get_direction(start_point, coord)
		if agent.player_map.invis_state_map[coord] == Global.INVIS_MOUNTAIN:
			direction_count[direction] += 1
			if(direction_count[direction] > direction_count[max_direction]):
				max_direction = direction
		#TODO 开关：是否节约power
	return max_direction

func dynamic_kamikaze_search_Not_Found(start_point: Vector2i) -> void:
	self.search_pattern = self.PATTERN_KAMIKAZE
	#动态kamikaze搜索方法,抵达某个区域
	var visited: Array[Vector2i] = [start_point]
	var sight_range: Array = [1]
	var cell: CellInfo = agent.player_map.get_cell(start_point)
	var direction: Vector2i
	while cell.get_power() > 1:

		direction = dynamic_Not_Found_in_sight_direction(start_point, sight_range)
		if self.search_pattern != PATTERN_KAMIKAZE:
			return
		send_path([{
			"from": start_point,
			"dir": direction,
			"ratio": 1.0
		}])
		start_point += direction
		await agent.player_map.turn_updated
		if self.search_pattern != self.PATTERN_KAMIKAZE:
			return
		cell = agent.player_map.get_cell(start_point)
		
func dynamic_Not_Found_in_sight_direction(start_point: Vector2i, sight_range: Array) -> Vector2i:
	#动态更新sight方法
	var cells_in_sight: Array[Vector2i] = agent.player_map.spiral_rings_traversal(start_point, sight_range[0])
	
	var direction_count_Not_Found: Dictionary = {} #记录视野内含block节点数
	var direction_count_cost: Dictionary = {} #记录视野内节点总代价:value_map,敌负我正
	var sum_count_Not_Found: int
	var sum_count_cost: int
	var direction_ratio_Not_Found: Dictionary = {}
	var direction_ratio_cost: Dictionary = {}
	var direction_final_ratio: Dictionary = {}
	
	for direction in Global.HEX_DIRECTIONS:
		direction_count_Not_Found[direction] = 0
		direction_count_cost[direction] = 0
		
	var max_Not_Found_direction: Vector2i = Vector2i(1,0)
	var max_direction: Vector2i = Vector2i(1,0)
	
	for coord in cells_in_sight:
		var direction:Vector2i = agent.player_map.get_direction(start_point, coord)
		if agent.player_map.invis_state_map[coord] == Global.INVIS_MOUNTAIN:
			direction_count_Not_Found[direction] += 1
			if(direction_count_Not_Found[direction] > direction_count_Not_Found[max_Not_Found_direction]):
				max_Not_Found_direction = direction
		if agent.player_map.invis_state_map[coord] != Global.TERRAIN_MOUNTAIN:
			if agent.player_map.invis_state_map[coord] == Global.INVIS_EMPTY or agent.player_map.invis_state_map[coord] == Global.INVIS_WATER:
				direction_count_cost[direction] += 0
			else:
				direction_count_cost[direction] += agent.algorithm_map.value_map[coord]
		
	while direction_count_Not_Found[max_Not_Found_direction] != 0:
		sight_range[0] += 1
		var new_sight: Array[Vector2i] = agent.player_map.ring_traversal(start_point, sight_range[0])
		cells_in_sight.append(new_sight)
		for coord in new_sight:
			var direction:Vector2i = agent.player_map.get_direction(start_point, coord)
			if agent.player_map.invis_state_map[coord] == Global.INVIS_MOUNTAIN:
				direction_count_Not_Found[direction] += 1
				if(direction_count_Not_Found[direction] > direction_count_Not_Found[max_Not_Found_direction]):
					max_Not_Found_direction = direction
			if agent.player_map.invis_state_map[coord] != Global.TERRAIN_MOUNTAIN:
				if agent.player_map.invis_state_map[coord] == Global.INVIS_EMPTY or agent.player_map.invis_state_map[coord] == Global.INVIS_WATER:
					direction_count_cost[direction] += 0
				else:
					direction_count_cost[direction] += agent.algorithm_map.value_map[coord]
	
	for direction in direction_count_Not_Found:
		sum_count_Not_Found += direction_count_Not_Found[direction]
		sum_count_cost += direction_count_cost[direction]
	for direction in direction_count_Not_Found:
		direction_ratio_Not_Found[direction] = float(direction_count_Not_Found[direction] / sum_count_Not_Found)
		direction_ratio_cost[direction] = float(direction_count_cost[direction] / sum_count_cost)
		direction_final_ratio[direction] = float(direction_count_Not_Found[direction] + direction_ratio_cost[direction])
		if direction_final_ratio[direction] > direction_final_ratio[max_direction]:
			if agent.player_map.invis_state_map[start_point + max_direction] != Global.TERRAIN_MOUNTAIN:
				max_direction = direction
	return max_direction

func on_city_find(cityid:int,citypos:Vector2i) -> void:
	#add to not occupy
	Not_Found.erase(citypos)
	agent.Not_Occupy.append(citypos)
	self.search_pattern = self.PATTERN_SLEEP
	state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.EMPTYCITY_OCCUPY)

func on_place_not_found() -> void:
	#add to not found
	#activate search pattern
	if self.search_pattern == self.PATTERN_SLEEP:
		to_found_empty_city()
	else:
		pass
	
func send_path(path_operations: Array) -> void:
	agent.path_add.emit(0, path_operations)
	pass
