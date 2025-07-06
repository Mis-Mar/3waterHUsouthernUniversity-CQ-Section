extends AlgorithmMap
class_name M2S_SearchAlgorithm

#类型静态，需要反复更新
#可重复调用，重复执行M2S_Search函数即可

var value_param: float
var distance_param: float
var influence_threshold: float
var range_threshold: int

var source_points: Array[Vector2i] = []
var path_operations: Array = []

#我添加了new（）初始化
var search_tree: Treelib=Treelib.new()

var influence_map: Dictionary = {}
var final_influence_map: Dictionary = {}

func _init(original: AlgorithmMap) -> void:
	self.player_id = original.player_id
	#引用原地图
	cell_map=original.cell_map
	base_map=original.base_map
	# 拷贝almap的特有数据
	for coord in original.cell_map.keys():
		self.value_map[coord] = cell_map[coord].get_power()
		self.distance_map[coord] = INF
		self.influence_map[coord] = 0
		self.final_influence_map[coord] = 0
	# 引用 general_id_to_player_id 映射
	general_id_to_player_id=original.general_id_to_player_id
	# 拷贝当前回合数
	turn_count = original.turn_count

func M2S_Search(target_point: Vector2i, demand: int, _value_param: float, _distance_param: float, _influence_threshold: float, _range_threshold: int) -> Array:
	#主函数：整合前向BFS和反向BFS，计算所有节点的最终影响值并获取源点表
	self.value_param = _value_param
	self.distance_param = _distance_param
	self.influence_threshold = _influence_threshold
	self.range_threshold = _range_threshold

	self.reset()
	#前向BFS：计算所有节点的最终影响值
	self.compute_final_influences(target_point)
	#反向BFS：从目标点出发获取源点表、路径
	if not self.reverse_bfs(target_point, demand):
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
		self.final_influence_map[coord] = 0
	for coord in self.distance_map:
		self.distance_map[coord] = INF
	source_points.clear()
	path_operations.clear()
	self.search_tree.clear()

func compute_final_influences(target_point: Vector2i) -> void:
	#主函数，计算所有节点的最终影响值

	#从目标点出发进行BFS，计算每个节点的距离
	self.bfs_distance(target_point)
	
	#计算当前节点影响值和附加影响值
	self.calculate_influence(target_point)
	
	final_influence_map[target_point] = 1 - INF

func calculate_influence(target_point: Vector2i) -> void:
	#主函数，计算当前节点影响值和附加影响值#
	#预处理节点价值
	value_preprocessing(target_point)
	#计算当前节点影响值和附加影响值
	for coord in base_map.cell_map.keys():
		if influence_map[coord] > 0 and coord != target_point:
			influence_map[coord] = pow(influence_map[coord], 2) * self.value_param
			self.propagate_influence(coord)
		elif influence_map[coord] < 0 :
			influence_map[coord] = -pow(influence_map[coord], 2) * self.value_param
			final_influence_map[coord] += influence_map[coord]

func value_preprocessing(target_point: Vector2i) -> void:
	#预处理节点价值
	#TODO 完成预处理功能
	for coord in base_map.cell_map.keys():
		var cell: CellInfo = self.get_cell(coord)
		if cell.get_type() != Global.TERRAIN_MOUNTAIN:
			if base_map.general_id_to_player_id[cell.get_general_id()]  == self.player_id:
				influence_map[coord] = cell.get_power() - 1
			else:
				influence_map[coord] = - (cell.get_power() + 1)
		else:
			influence_map[coord] = -INF

func propagate_influence(start_point: Vector2i) -> void:
	# 创建队列 (使用数组模拟队列)
	var queue: Array = [[start_point, 0]]
	var visited: Array = []
	# 开始BFS遍历
	while not queue.is_empty():
		var AR: Array = queue.pop_front()
		var current: Vector2i = AR[0]  # 从队列头部取出
		var dist: int = AR[1]
		if current not in visited:
			# 获取所有邻居
			visited.append(current)
			var additional_influence: float = influence_map[start_point] / sqrt((1 + dist) * self.distance_param)
			if additional_influence >= self.influence_threshold:
				final_influence_map[current] += additional_influence
				var neighbors: Array[Vector2i] = self.get_neighbors_state0(current)
				for neighbor: Vector2i in neighbors:
					queue.append([neighbor, dist + 1])

func reverse_bfs(start_point: Vector2i, demand: int) -> bool:
	self.search_tree.create_root(str(start_point), start_point)
	#我添加了new（）初始化
	var open_list: PriorityQueue=PriorityQueue.new()
	var close_list: Array[Vector2i] = []
	var accumulated_value: int = 0
	var has_solution: bool = false

	open_list.push(-final_influence_map[start_point], start_point)
	
	while not open_list.is_empty():
		var current: Vector2i = open_list.pop()
		print(current)
		#TODO range_threshold参数使用方法
		if current not in close_list and distance_map[current] <= range_threshold:
			close_list.append(current)
			#累计价值
			var cell: CellInfo = self.get_cell(current)
			
			print("current:")
			print(current)
			print(cell.get_power())
			print(influence_map[current])
			print(final_influence_map[current])
			accumulated_value += cell.get_power() - 1
			
			print(accumulated_value)
			
			if(cell.get_power()>1):
				source_points.append(current)
				#如果累计价值超过需求值，则终止搜索
				if accumulated_value > demand:
					has_solution = true
					break
			print("neighbors:")
			var neighbors: Array[Vector2i] = self.get_neighbors_state0(current)
			for neighbor: Vector2i in neighbors:
				print(neighbor)
				if neighbor not in close_list:
					if self.distance_map[neighbor] <= self.range_threshold:
						if not self.search_tree.get_node(str(neighbor)):
							self.search_tree.add_node(str(neighbor), str(current), neighbor)
							open_list.push(-final_influence_map[neighbor], neighbor)
	
	return has_solution

func prune_tree() -> void:
	#剪枝操作：删除多余节点
	var nodes_to_remove: Array[String] = []
	var node = self.search_tree.get_root()
	contains_source(nodes_to_remove, node.identifier)
	for node_id in nodes_to_remove:
		if self.search_tree.get_node(node_id):
			self.search_tree.remove_node(node_id)

func contains_source(_nodes_to_remove: Array[String], node_id: String) -> bool:
	var node_data: Vector2i = self.search_tree.get_node(node_id).data
	var source_in_child: bool = false
	if node_data in source_points:
		source_in_child = true
	for child in self.search_tree.children(node_id):
		if contains_source(_nodes_to_remove, child.identifier):
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
		self.path_operations.append([node_id, parent.identifier])
		
# 输出接口
func get_path_coords() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for op: Array in path_operations:
		var node_id: String = op[0]
		var vec: Vector2i = search_tree.get_node(node_id).data
		if vec not in coords:
			coords.append(vec)
	return coords
