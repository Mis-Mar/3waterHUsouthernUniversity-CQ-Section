# PLayerMap.cel
extends BaseMap
class_name PlayerMap

var player_id: int = 0

#存储区块不可见的情况：（空地/主城？） （山地/城市？）(水域)
#也存储了所有的地图key，可用于表示地图范围
var invis_state_map: Dictionary = {}  # Dictionary<Vector2i, int>

# General ID → Capital position
var general_to_capital: Dictionary = {}  # Dictionary[int, Vector2i]
# City 坐标 → City ID (本地自增计算)
var city_position_to_id: Dictionary = {}  # Dictionary[Vector2i, int]
# City ID → City 双向映射，防止同一个city被反复增加
var city_id_to_position: Dictionary = {}  # Dictionary[int, Vector2i]
# City ID → General ID（0 表示未占领）
var city_id_to_general: Dictionary = {}  # Dictionary[int, int]
var city_id_of_general: Dictionary = {}  # Dictionary嵌套Array构成二维数组，第一维generalid，第二维cityid
# 自增城市ID计数器（本地使用）
var _next_city_id: int = 1

# ——————————信号
signal tile_newly_visible(coord: Vector2i)
signal tile_hidden(coord: Vector2i)
signal tile_updated(coord: Vector2i)
# 回合更新信号，完成
signal turn_updated(curr_turn:int)
# 发现新的城市的信号，完成
signal find_city(cityid:int,citypos:Vector2i,generalid:int)
# 占领城市信号，待定，我想做一个占领格子的大信号，然后占领城市的信号由分析这个信号再发出
signal occupy_cell(cityid:int,citypos:Vector2i,generalid:int)
# 敌方兵力入侵信号，可做，没做完
signal enemy_attack(pos:Vector2i,power:int,enemyid:int,generalid:int)
# 敌方侦察信号，可做，没做完
signal enemy_find(pos:Vector2i,power:int,enemyid:int,type:int)
# 视野损失，已完成
signal lost_vision(pos:Vector2i,_cellinfo:CellInfo)



# ——————————初始化
# 通过fullmap player_id初始化，测试用
func init_from_fullmap(fullmap: FullMap, _player_id: int):
	self.player_id = _player_id
	#复制turn_count
	turn_count=fullmap.turn_count
	general_id_to_player_id.clear()
	invis_state_map.clear()
	
	# 拷贝 general_id_to_player_id 
	for key in fullmap.general_id_to_player_id.keys():
		general_id_to_player_id[key] = fullmap.general_id_to_player_id[key]

	# 构建invis_state_map
	for coord in fullmap.cell_map.keys():
		var cell = fullmap.cell_map[coord]
		#山地/城市 显示山地
		if cell.get_type() == Global.TERRAIN_MOUNTAIN or cell.get_type() == Global.TERRAIN_CITY:
			invis_state_map[coord] = Global.INVIS_MOUNTAIN
		#空地/首都 显示空地
		elif cell.get_type() == Global.TERRAIN_CAPITAL or cell.get_type() == Global.TERRAIN_EMPTY:
			invis_state_map[coord] = Global.INVIS_EMPTY
		#水       显示水
		elif cell.get_type() == Global.TERRAIN_WATER:
			invis_state_map[coord] = Global.INVIS_WATER
	
	# 初始化cellmap
	var vis_arr=fullmap.get_visible_tiles_for_player(_player_id)
	for coord in vis_arr:
		cell_map[coord]=fullmap.cell_map[coord].clone()

# 通过服务器fullmap导出的data来初始化
func init_from_dict(init_data: Dictionary) -> void:
	player_id=init_data.get("player_id", 0)
	turn_count = init_data.get("turn_count", 0)
	general_id_to_player_id = init_data.get("general_id_to_player_id", {}).duplicate()
	invis_state_map.clear()
	cell_map.clear()

	# 构建 invis_state_map
	for key in init_data.get("invis_state_map", {}).keys():
		var coord = parse_vector2i(key)
		invis_state_map[coord] = init_data["invis_state_map"][key]

	# 加载可见的 CellInfo，构建cell_map
	var visible_cells = init_data.get("visible_cells", {})
	for key in visible_cells.keys():
		var coord = parse_vector2i(key)
		var cell_info = CellInfo.from_dict(visible_cells[key])
		cell_map[coord] = cell_info
		# 更新id到position等，那几个表
		invis_state_map[coord]=cell_info.get_type()
		if cell_info.get_type()==Global.TERRAIN_CAPITAL:
			add_capital(cell_info.get_general_id(),coord)
		elif cell_info.get_type()==Global.TERRAIN_CITY:
			add_or_update_city(coord,cell_info.get_general_id())

# 结束——————————

# state1: 对于已知排除山地、敌方节点、友军节点，排除所有未知 对象：general
func get_neighbors_state1(center: Vector2i, general_id:int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in Global.HEX_DIRECTIONS:
		var neighbor_coords: Vector2i = center + dir
		if cell_map.has(neighbor_coords):
			var cell := get_cell(neighbor_coords)
			if cell.get_type() != Global.TERRAIN_MOUNTAIN and cell.get_general() == general_id:
				neighbors.append(neighbor_coords)
	return neighbors

# state2: 搜索用，对于已知排除山地、敌方节点、友军节点，包含未知（所有节点）山地、水域、平原 对象：general
func get_neighbors_state2(center: Vector2i, general_id:int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in Global.HEX_DIRECTIONS:
		var neighbor_coords: Vector2i = center + dir
		if cell_map.has(neighbor_coords):
			var cell := get_cell(neighbor_coords)
			if cell.get_type() != Global.TERRAIN_MOUNTAIN and cell.get_general() == general_id :
				neighbors.append(neighbor_coords)
		else:
			neighbors.append(neighbor_coords)
	return neighbors
	
# state3: 对于已知排除山地、敌方节点、队友节点，对于未知排除山地 对象：general
func get_neighbors_state3(center: Vector2i, general_id:int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in Global.HEX_DIRECTIONS:
		var neighbor_coords: Vector2i = center + dir
		if cell_map.has(neighbor_coords):
			var cell := get_cell(neighbor_coords)
			if cell.get_type() != Global.TERRAIN_MOUNTAIN and cell.get_general() == general_id:
				neighbors.append(neighbor_coords)
		elif self.invis_state_map[neighbor_coords] != Global.INVIS_MOUNTAIN:
			neighbors.append(neighbor_coords)
	return neighbors
	
# state4: 对于已知排除山地，对于未知排除山地 对象：general
func get_neighbors_state4(center: Vector2i, general_id:int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in Global.HEX_DIRECTIONS:
		var neighbor_coords: Vector2i = center + dir
		if cell_map.has(neighbor_coords):
			var cell := get_cell(neighbor_coords)
			if cell.get_type() != Global.TERRAIN_MOUNTAIN :
				neighbors.append(neighbor_coords)
		elif self.invis_state_map[neighbor_coords] != Global.INVIS_MOUNTAIN:
			neighbors.append(neighbor_coords)
	return neighbors

# state5: 对于已知排除山地和队友节点，对于未知排除山地 对象：general
func get_neighbors_state5(center: Vector2i, general_id:int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in Global.HEX_DIRECTIONS:
		var neighbor_coords: Vector2i = center + dir
		if cell_map.has(neighbor_coords):
			var cell := get_cell(neighbor_coords)
			if cell.get_type() != Global.TERRAIN_MOUNTAIN and (cell.get_general() == general_id or cell.get_general_id() not in general_id_to_player_id[player_id] ):
				neighbors.append(neighbor_coords)
			elif self.invis_state_map[neighbor_coords] != Global.INVIS_MOUNTAIN:
				neighbors.append(neighbor_coords)
	return neighbors
	
# state6: 对于已知排除山地和敌方节点，对于未知排除所有 对象：general
func get_neighbors_state6(center: Vector2i, general_id:int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in Global.HEX_DIRECTIONS:
		var neighbor_coords: Vector2i = center + dir
		if cell_map.has(neighbor_coords):
			var cell := get_cell(neighbor_coords)
			if cell.get_type() != Global.TERRAIN_MOUNTAIN and cell.get_general_id() in general_id_to_player_id[player_id]:
				neighbors.append(neighbor_coords)
	return neighbors

# ——————————同步函数
func update_player_map(delta_cell: Dictionary,delta_general_id_to_player_id: Dictionary)->void:
	update_power_by_terrain()
	import_general_id_to_player_id(delta_general_id_to_player_id)
	update_cell_from_delta(delta_cell)
	# 发出信号（测试）
	emit_signal("turn_updated",turn_count)
	pass

# 更新视野，更新玩家操作的格子变化
func update_cell_from_delta(delta: Dictionary) -> void:
	for key in delta["newly_visible"].keys():
		var coord = parse_vector2i(key)
		var cell_info = CellInfo.from_dict(delta["newly_visible"][key])
		cell_map[coord] = cell_info
		# 更新id到position等，那几个表
		invis_state_map[coord]=cell_info.get_type()
		if cell_info.get_type()==Global.TERRAIN_CAPITAL:
			add_capital(cell_info.get_general_id(),coord)
		elif cell_info.get_type()==Global.TERRAIN_CITY:
			add_or_update_city(coord,cell_info.get_general_id())
		# 发信号-新看见格子
		emit_signal("tile_newly_visible", coord)
		
		
	# 视野看不见的格子去掉，并发信号
	for key in delta["now_invisible"]:
		var coord = parse_vector2i(key)
		if cell_map.has(coord):
			# 发信号 丢失视野
			emit_signal("lost_vision", coord,cell_map[coord])
			cell_map.erase(coord)
			emit_signal("tile_hidden", coord)
	# 玩家操作改变的格子
	for key in delta["changed"].keys():
		var coord = parse_vector2i(key)
		if cell_map.has(coord):
			var cell_info = CellInfo.from_dict(delta["changed"][key])
			var pre_cell_info=cell_map[coord]
			#TODO 占领和被占领信号待完成
			# if pre_cell_info.get_general()!=cell_info.get_general():
				# if general_id_to_player_id[pre_cell_info.get_general()]==player_id:
					# 信号，被占领格子
					# emit_signal("tile_hidden", coord)
			
			
			cell_map[coord] = cell_info
			cell_map[coord].set_dirty_flag()
			# 更新id到position等，那几个表
			invis_state_map[coord]=cell_info.get_type()
			if cell_info.get_type()==Global.TERRAIN_CAPITAL:
				add_capital(cell_info.get_general_id(),coord)
			elif cell_info.get_type()==Global.TERRAIN_CITY:
				add_or_update_city(coord,cell_info.get_general_id())
			# 发信号
			emit_signal("tile_updated", coord)

# 更新（复制）general_id_to_player_id
func import_general_id_to_player_id(data: Dictionary) -> void:
	general_id_to_player_id.clear()
	for key in data.keys():
		general_id_to_player_id[key] = data[key]
# 同步结束————————————


# ——————————建立用于算法的city_id对应position和general_id的表
# 接口——
func get_city_coord(city_id:int)->Vector2i:
	return city_id_to_position[city_id]

func get_city_id(coord: Vector2i)->int:
	return city_position_to_id[coord]

func get_general_capital(general_id:int)->Vector2i:
	return general_to_capital[general_id]

func get_city_ids_of_general(general_id: int) -> Array[int]:
	var result: Array[int] = []
	for city_id in city_id_to_general.keys():
		if city_id_to_general[city_id] == general_id:
			result.append(city_id)
	return result

# 底层——添加capital到表
func add_capital(general_id: int, position: Vector2i) -> void:
	# 若已有记录，直接替换
	#print("capital++")
	general_to_capital[general_id] = position


# 底层——添加city到表
func add_or_update_city(position: Vector2i, general_id: int) -> void:
	# 若该 general 尚未有城市列表，初始化为 [],预防非法访问
	if not city_id_of_general.has(general_id):
		city_id_of_general[general_id] = []
	# 如果城市已经被记录，更新general
	if city_position_to_id.has(position):
		var city_id = city_position_to_id[position]
		city_id_to_general[city_id] = general_id
		city_id_of_general[general_id].append(city_id)
	# 城市未被记录，添加新纪录
	else:
		#print("city++")
		var city_id = _next_city_id
		_next_city_id += 1
		city_position_to_id[position] = city_id
		city_id_to_position[city_id] = position
		city_id_to_general[city_id] = general_id
		city_id_of_general[general_id].append(city_id)
		# 信号 新发现城市
		emit_signal("find_city",city_id,position,general_id)
