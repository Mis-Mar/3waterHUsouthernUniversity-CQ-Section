extends AlgorithmMap
class_name M2S_SearchAlgorithm

#类型静态，需要反复更新
#可重复调用，重复执行M2S_Search函数即可

var value_param: float
var distance_param: float
var influence_threshold: float
var range_threshold: int

var source_points: Array[Vector2i]=[]
var path_operations: Array =[]

var search_tree: Treelib

var player_id: int

var influence_map: Dictionary = {}  # 当前节点影响值 I
var final_influence_map: Dictionary = {}  # 最终影响值 FI


func _init(original:AlgorithmMap,_player_id:int) -> void:
	base_map = original
	self.player_id=_player_id
	grid_map.clear()
	# 拷贝格子数据
	for coord in original.grid_map.keys():
		grid_map[coord] = original.grid_map[coord].clone()
		self.value_map[coord] = self.get_cell(coord).power
		self.distance_map[coord] = INF
		self.influence_map[coord] = 0
		self.final_influence_map[coord] = 0
	# 拷贝 owner_to_player 映射（深拷贝，避免污染）
	owner_to_player = {}
	for key in original.owner_to_player.keys():
		owner_to_player[key] = original.owner_to_player[key]
	# 拷贝当前回合数
	turn_count = original.turn_count
	
func M2S_Search(target_point:Vector2i, demand:int, _value_param:float, _distance_param:float,_influence_threshold:float, _range_threshold:int) -> Array:
	#主函数：整合前向BFS和反向BFS，计算所有节点的最终影响值并获取源点表
	self.value_param=_value_param
	self.distance_param=_distance_param
	self.influence_threshold=_influence_threshold
	self.range_threshold=_range_threshold
	
	self.reset()
	
	#前向BFS：计算所有节点的最终影响值
	self.compute_final_influences(target_point)
	#反向BFS：从目标点出发获取源点表、路径
	if not self.reverse_bfs(target_point,demand):
		return [-1]
	else:
		#剪枝操作：删除多余节点
		self.prune_tree()
		#后序遍历形成路径操作序列
		self.postorder_traversal()
		return path_operations
	
func reset() -> void:
	for coord in self.influence_map:
		self.influence_map[coord] = 0
	for coord in self.final_influence_map:
		self.influence_map[coord] = 0
	for coord in self.distance_map:
		self.distance_map[coord] = INF
	source_points.clear()
	path_operations.clear()
	self.search_tree.clear()
	
func compute_final_influences(target_point:Vector2i) -> void:
	#主函数，计算所有节点的最终影响值
	
	#从目标点出发进行BFS，计算每个节点的距离
	self.bfs_distance(target_point)
	
	#计算当前节点影响值和附加影响值
	self.calculate_influence(target_point)
	
	final_influence_map[target_point] = 1 - INF
	
	pass

func calculate_influence(target_point:Vector2i) -> void:
	#主函数，计算当前节点影响值和附加影响值#
	#预处理节点价值
	value_preprocessing(target_point)
	#计算当前节点影响值和附加影响值
	for coord in base_map.grid_map.keys():
		if influence_map[coord] > 0 and coord != target_point:
			influence_map = (influence_map[coord] ** 2) * self.value_param
			self.propagate_influence(coord)
	pass
	
func value_preprocessing(target_point:Vector2i) -> void:
	#预处理节点价值
	for coord in base_map.grid_map.keys():
		if self.get_cell(coord).terrain_type != Global.TERRAIN_MOUNTAIN:
			if self.get_cell(coord).owner == self.player_id:
				influence_map[coord] = value_map[coord]-1
			else:
				influence_map[coord] = -value_map[coord]
		else:
			influence_map[coord] = -INF
	pass

func propagate_influence(start_point: Vector2i) -> void:
	# 创建队列 (使用数组模拟队列)
	var queue: Array = [[start_point,0]]
	var visited: Array = []
	# 开始BFS遍历
	while not queue.is_empty():
		var AR: Array = queue.pop_front()
		var current: Vector2i = AR[0]  # 从队列头部取出
		var dist: int = AR[1]
		if current not in visited:
			# 获取所有邻居
			visited.append(current)
			var additional_influence: float = influence_map[start_point] / sqrt( (1 + dist) * self.distance_param)
			if additional_influence >= self.influence_threshold:
				final_influence_map[current] += additional_influence
				var neighbors: Array[Vector2i] = self.get_neighbors_state0(current)
				for neighbor:Vector2i in neighbors:
					queue.append([neighbor,dist+1])

func reverse_bfs(start_point: Vector2i, demand: int) -> bool:
	self.search_tree.create_root(str(start_point),start_point)
	var open_list: PriorityQueue
	var close_list: Array[Vector2i] = []
	var accumulated_value: int = 0
	var has_solution: bool = false
	
	open_list.push(-final_influence_map[start_point],start_point)
	
	while not open_list.is_empty():
		var current: Vector2i = open_list.pop()
		if current not in close_list and distance_map[current] <= range_threshold :
			close_list.append(current)
						
			#累计价值
			if value_map[current] > 1:
				accumulated_value += value_map[current] - 1
				source_points.append(current)
			
			#如果累计价值超过需求值，则终止搜索
			if accumulated_value > demand:
				has_solution = true
				break
			
			var neighbors: Array[Vector2i] = self.get_neighbors_state1(current,self.player_id)
			for neighbor:Vector2i in neighbors:
				if neighbor not in close_list:
					if self.distance_map[neighbor] <= self.range_threshold:
						if not self.search_tree.get_node(str(neighbor)):
							self.search_tree.add_node(str(neighbor), str(current), neighbor)
							open_list.push(-final_influence_map[neighbor],neighbor)
	return has_solution
	
func prune_tree() -> void:
	var nodes_to_remove: Array[String] = []
	var node = self.search_tree.get_root()
	contains_source(nodes_to_remove,node.identifier)
	for node_id in nodes_to_remove:
		if self.search_tree.get_node(node_id):
			self.search_tree.remove_node(node_id)
		
func contains_source(_nodes_to_remove: Array[String], node_id: String) -> bool:
	var node_data: Vector2i = self.search_tree.get_node(node_id).data
	var source_in_child: bool = false
	if node_data in source_points:
		source_in_child = true
	for child in self.search_tree.children(node_id):
		if(contains_source(_nodes_to_remove,child.identifier)):
			source_in_child = true
	if not source_in_child:
		_nodes_to_remove.append(node_id)
	return source_in_child
	
func postorder_traversal() -> void:
	#后序遍历形成路径操作序列
	var node = self.search_tree.get_root()
	self.postorder_traverse(node.identifier)
	
func postorder_traverse(node_id: String) -> void:
	for child in self.search_tree.children(node_id):
		postorder_traverse(child.identifier)
	var parent = self.search_tree.get_parent(node_id)
	if parent:
		self.path_operations.append([node_id,parent.identifier])
