extends AlgorithmMap
class_name M2S_SearchAlgorithm

var value_param:float
var distance_param:float
var value_threshold:float
var range_threshold:int
var source_points:Array =[]
var search_tree:TreeLib

var player_id:int

var influence_map: Dictionary = {}  # 当前节点影响值 I
var final_influence_map: Dictionary = {}  # 最终影响值 FI


func _init(original:AlgorithmMap,_player_id:int) -> void:
	base_map = original
	self.player_id=_player_id
	grid_map.clear()
	# 拷贝格子数据
	for coord in original.grid_map.keys():
		grid_map[coord] = original.grid_map[coord].clone()
		# 示例，获取所有格子构造value_map初始化value为0
		value_map[coord] = self.get_cell(coord).power
		distance_map[coord] = INF
		influence_map[coord] = 0
		final_influence_map[coord] = 0
	# 拷贝 owner_to_player 映射（深拷贝，避免污染）
	owner_to_player = {}
	for key in original.owner_to_player.keys():
		owner_to_player[key] = original.owner_to_player[key]
	# 拷贝当前回合数
	turn_count = original.turn_count
	
func M2S_Search(target_point:Vector2i, _value_param:float, _distance_param:float,_value_threshold:float, _range_threshold:int) -> Array:
	#主函数：整合前向BFS和反向BFS，计算所有节点的最终影响值并获取源点表
	self.value_param=_value_param
	self.distance_param=_distance_param
	self.value_threshold=_value_threshold
	self.range_threshold=_range_threshold
	
	var path_operations:Array =[]
	
	self.compute_final_influences(target_point)
	self.reverse_bfs(target_point)
	self._prune_tree(self.search_tree,self.source_points)
	path_operations=self._postorder_traversal(self.search_tree)
	
	return path_operations
	
	
func compute_final_influences(target_point:Vector2i) -> void:
	#主函数，计算所有节点的最终影响值
	
	#从目标点出发进行BFS，计算每个节点的距离
	self.bfs_distance(target_point)
	
	#计算当前节点影响值和附加影响值
	self.calculate_influence(target_point)
	
	pass

func calculate_influence(target_point:Vector2i) -> void:
	#预处理节点价值
	value_preprocessing(target_point)
	#计算当前节点影响值和附加影响值
	for coord in base_map.grid_map.keys():
		if influence_map[coord] > 0 and coord != target_point:
			influence_map = (influence_map[coord]** 2)* self.value_param
			self.propagate_influence(coord)
	pass
	
func value_preprocessing(target_point:Vector2i) -> void:
	#预处理节点价值
	for coord in base_map.grid_map.keys():
		if self.get_cell(coord).terrain_type != Global.TERRAIN_MOUNTAIN:
			if self.get_cell(coord).owner == self.player_id:
				influence_map[coord]=value_map[coord]
			else:
				influence_map[coord]=-value_map[coord]
		else:
			influence_map[coord]=-INF
	pass

func propagate_influence(start_node: Vector2i) -> void:
	pass

func reverse_bfs(target_point:Vector2i) -> void:
	pass
	
func _prune_tree(_search_tree:TreeLib, _source_points) -> void:
	pass
	
func _postorder_traversal(_search_tree:TreeLib) -> Array:
	var path_operations:Array =[]
	return path_operations
