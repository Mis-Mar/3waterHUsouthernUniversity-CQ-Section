extends BaseState_ExpansionAgent
class_name State_SearchingEmptycity

var Not_Found: Array[Vector2i]
var Vision_Sufficient: bool = false
var search_path: Array[Vector2i]
var search_pattern: int = self.PATTERN_SLEEP

const PATTERN_SLEEP := 0
const PATTERN_M2S := 1
const PATTERN_KAMIKAZE := 2


func enter() -> void:
	if not is_vision_sufficient():
		#FIXME 重构VS逻辑：NOTFOUND非空
		if found_empty_city():
			state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.EMPTYCITY_OCCUPY)
		else:
			#HACK 待完成 等待适当回合
			state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.SEARCHING_EMPTYCITY)
	else:
		state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.EXPANSION_COMPLETE)

func found_empty_city() -> bool:
	if(search_empty_city(2,20)):
		agent.act(search_path)
		#HACK 待完成 触发发现新城市，条件判断
		#agent.Not_Occupy.append()
		return true
	return false

func search_empty_city(jump_param: int,estimated_demand: int) -> bool:
	self.search_pattern = self.PATTERN_M2S
	#前往可抵达城市
	var target_point = Not_Found.pop_front()
	search_path.clear()
	var path_point: Array[Vector2i] = agent.player_map.build_Astar_path(self.agent.general.main_city,target_point)
	while !path_point.is_empty():
		target_point = path_point.pop_front()
		var path = agent.search_algorithm.M2S_Search(target_point,estimated_demand,3,1,20,20)
		#HACK 待完成 参数设置
		var path_action = agent.search_algorithm.get_path_action()
		if path != [-1]:
			path_action.pop_back()#去尾
			search_path = path_action
			if self.search_pattern != self.PATTERN_M2S:
				return false
			send_path(path_action)
			return true
		else:
			return false
	return false

func is_vision_sufficient() -> bool:
	#添加可抵达城市（视野之外
	#TODO check只指未知山地城市可达视野
	Vision_Sufficient = true
	Not_Found = agent.Not_Found
	
	var distance_map: Dictionary = {}
	for coord in agent.player_map.invis_state_map.keys():
		distance_map[coord] = INF
	var queue: Array[Vector2i] = [main_city]
	distance_map[main_city] = 0
	# 开始BFS遍历
	while not queue.is_empty():
		var current = queue.pop_front()  # 从队列头部取出
		var current_distance = distance_map[current]
		if agent.player_map.invis_state_map[current] == Global.INVIS_MOUNTAIN and current not in Not_Found:
			Not_Found.append(current)
			agent.Not_Found.append(current)
			Vision_Sufficient = false
			break
		# 获取所有邻居
		var neighbors = agent.player_map.get_neighbors_state2(current,agent.general.general_id)
		for neighbor in neighbors:
			# 如果邻居尚未访问过 (距离为无穷大)
			if distance_map[neighbor] == INF:
				# 更新邻居距离
				distance_map[neighbor] = current_distance + 1
				# 将邻居加入队列
				queue.append(neighbor)
	if Vision_Sufficient == false:
		return false
	else:
		return true

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
		#HACK 待完成 等待更新
		cell = agent.player_map.get_cell(start_point)

func Not_Found_in_sight_direction(start_point: Vector2i, sight_range: int) -> Vector2i:
	var cells_in_sight: Array[Vector2i] = agent.player_map.spiral_rings_traversal(start_point, sight_range)
	var direction_count: Dictionary = {}
	direction_count[Vector2i(0,0)] = 0
	var max_direction: Vector2i = Vector2i(0,0)
	for coord in cells_in_sight:
		var direction:Vector2i = agent.player_map.get_direction(start_point, coord)
		if agent.player_map.invis_state_map[coord] == Global.INVIS_MOUNTAIN:
			direction_count[direction] += 1
			if(direction_count[direction] > direction_count[max_direction]):
				max_direction = direction
		#TODO 开关：是否节约power
	return max_direction
		
func send_path(path_operations: Array) -> void:
	agent.path_add.emit(0, path_operations)
	pass
