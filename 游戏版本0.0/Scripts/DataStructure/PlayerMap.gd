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
# 自增城市ID计数器（本地使用）
var _next_city_id: int = 1

# 信号
signal tile_newly_visible(coord: Vector2i)
signal tile_hidden(coord: Vector2i)
signal tile_updated(coord: Vector2i)



# ——————————初始化
# 通过fullmap player_id初始化，测试用
func init_from_fullmap(fullmap: FullMap, _player_id: int):
	self.player_id = _player_id
	#复制turn_count
	turn_count=fullmap.turn_count
	general_to_player.clear()
	invis_state_map.clear()
	
	# 拷贝 general_to_player 
	for key in fullmap.general_to_player.keys():
		general_to_player[key] = fullmap.general_to_player[key]

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
	turn_count = init_data.get("turn_count", 0)
	general_to_player = init_data.get("general_to_player", {}).duplicate()
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
		if cell_info.get_type()==Global.TERRAIN_CAPITAL:
			add_capital(cell_info.get_general_id(),coord)
		elif cell_info.get_type()==Global.TERRAIN_CITY:
			add_or_update_city(coord,cell_info.get_general_id())

# 结束——————————



# ——————————同步函数
func update_player_map(delta_cell: Dictionary,delta_general_to_player: Dictionary)->void:
	update_power_by_terrain()
	update_cell_from_delta(delta_cell)
	import_general_to_player(delta_general_to_player)
	pass

# 更新视野，更新玩家操作的格子变化
func update_cell_from_delta(delta: Dictionary) -> void:
	for key in delta["newly_visible"].keys():
		var coord = parse_vector2i(key)
		var cell_info = CellInfo.from_dict(delta["newly_visible"][key])
		cell_map[coord] = cell_info
		# 更新id到position等，那几个表
		if cell_info.get_type()==Global.TERRAIN_CAPITAL:
			add_capital(cell_info.get_general_id(),coord)
		elif cell_info.get_type()==Global.TERRAIN_CITY:
			add_or_update_city(coord,cell_info.get_general_id())
		# 发信号
		emit_signal("tile_newly_visible", coord)

	for key in delta["now_invisible"]:
		var coord = parse_vector2i(key)
		if cell_map.has(coord):
			cell_map.erase(coord)
			emit_signal("tile_hidden", coord)

	for key in delta["changed"].keys():
		var coord = parse_vector2i(key)
		if cell_map.has(coord):
			var cell_info = CellInfo.from_dict(delta["changed"][key])
			cell_map[coord] = cell_info
			cell_map[coord].set_dirty_flag()
			# 更新id到position等，那几个表
			if cell_info.get_type()==Global.TERRAIN_CAPITAL:
				add_capital(cell_info.get_general_id(),coord)
			elif cell_info.get_type()==Global.TERRAIN_CITY:
				add_or_update_city(coord,cell_info.get_general_id())
			# 发信号
			emit_signal("tile_updated", coord)

# 更新（复制）general_to_player
func import_general_to_player(data: Dictionary) -> void:
	general_to_player.clear()
	for key in data.keys():
		general_to_player[key] = data[key]
# 同步结束————————————


# ——————————建立用于算法的city_id对应position和general_id的表
# 接口——
func get_city_coord(city_id:int)->Vector2i:
	return city_id_to_position[city_id]

func get_city_id(coord: Vector2i)->int:
	return city_position_to_id[coord]

func get_general_capital(general_id:int)->Vector2i:
	return general_to_capital[general_id]

# 底层——添加capital到表
func add_capital(general_id: int, position: Vector2i) -> void:
	# 若已有记录，直接替换
	#print("capital++")
	general_to_capital[general_id] = position
	# 这个capital被探索到了，记录下来，用于地图显示
	invis_state_map[position]=Global.TERRAIN_CAPITAL

# 底层——添加city到表
func add_or_update_city(position: Vector2i, general_id: int) -> void:
	# 如果城市已经被记录，更新general
	if city_position_to_id.has(position):
		var city_id = city_position_to_id[position]
		city_id_to_general[city_id] = general_id
	# 城市未被记录，添加新纪录
	else:
		#print("city++")
		var city_id = _next_city_id
		_next_city_id += 1
		city_position_to_id[position] = city_id
		city_id_to_position[city_id] = position
		city_id_to_general[city_id] = general_id
		# 记录探索到的city并显示
		invis_state_map[position]=Global.TERRAIN_CITY
