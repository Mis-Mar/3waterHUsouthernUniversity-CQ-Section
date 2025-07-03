extends BaseState_ExpansionAgent
class_name State_SearchingEmptycity

var Not_Found: Array[Vector2i]
var Vision_Sufficient: bool = false
var searh_path: Array[Vector2i]

func enter() -> void:
	if not is_vision_sufficient():
		if found_empty_city():
			state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.EMPTYCITY_OCCUPY)
		else:
			#TODO 等待适当回合
			state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.SEARCHING_EMPTYCITY)
	else:
		state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.EXPANSION_COMPLETE)

func found_empty_city() -> bool:
	if(search_empty_city(2,20)):
		agent.act(searh_path)
		#TODO 触发发现新城市，条件判断
		#agent.Not_Occupy.append()
		return true
	return false

func search_empty_city(jump_param: int,estimated_demand: int) -> bool:
	#前往可抵达城市
	var target_point = Not_Found.pop_front()
	searh_path.clear()
	#TODO 构建A*路径
	var path_point: Array[Vector2i] = []
	while !path_point.is_empty():
		target_point = path_point.pop_front()
		var path = agent.search_algorithm.M2S_Search(target_point,estimated_demand,3,1,20,20)
		var path_coords = agent.search_algorithm.get_path_coords()
		if path != [-1]:
			searh_path = path_coords
			send_path(path_coords)
			return true
		else:
			return false
	return false

func is_vision_sufficient() -> bool:
	#添加可抵达城市（视野之外
	Vision_Sufficient = true
	Not_Found = agent.Not_Found
	
	var distance_map: Dictionary = {}
	for coord in agent.full_map.grid_map.keys():
		distance_map[coord] = INF
		
	var queue: Array[Vector2i] = [main_city]
	distance_map[main_city] = 0
	# 开始BFS遍历
	while not queue.is_empty():
		var current = queue.pop_front()  # 从队列头部取出
		var current_distance = distance_map[current]
		
		var cell: CellInfo = agent.full_map.get_cell(current)
		if cell.get_type() == Global.TERRAIN_CITY and cell.get_owner() != agent.player_id and current not in Not_Found:
			#TODO 玩家地图类
			Not_Found.append(current)
			agent.Not_Found.append(current)
			Vision_Sufficient = false
			break
		
		# 获取所有邻居
		var neighbors = agent.full_map.get_neighbors_state1(current,player_id)
		#TODO 根据玩家视野改进
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
	#TODO 记录已走节点
	var cell: CellInfo = agent.full_map.get_cell(start_point)
	var direction: Vector2i
	while cell.get_power() > 1:
		direction = Not_Found_in_sight_direction(start_point, sight_range)
		start_point += direction
		send_path([start_point])
		#TODO 等待更新
		cell = agent.full_map.get_cell(start_point)

func Not_Found_in_sight_direction(start_point: Vector2i, sight_range: int) -> Vector2i:
	var cells_in_sight: Array[Vector2i] = agent.full_map.cube_spiral(start_point, sight_range)
	#TODO map中添加环遍历方法(螺旋环 https://www.redblobgames.com/grids/hexagons/
	var direction_count: Dictionary = {}
	var max_direction: Vector2i
	for coord in cells_in_sight:
		var cell: CellInfo = agent.full_map.get_cell(coord)
		#TODO 范围判断
		#TODO 加入direction_count中
		#eg：
		direction_count[Vector2i(-1,0)] += 1
		if direction_count[Vector2i(-1,0)] > direction_count[max_direction]:
			max_direction = Vector2i(-1,0)
	return max_direction
		
func send_path(path_operations: Array[Vector2i]) -> void:
	agent.path_add.emit(0, path_operations)
	pass
