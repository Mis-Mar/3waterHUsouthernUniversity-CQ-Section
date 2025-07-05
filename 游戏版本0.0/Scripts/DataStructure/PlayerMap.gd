# PLayerMap.cel
extends BaseMap
class_name PlayerMap

var player_id: int = 0

#存储区块不可见的情况：（空地/主城？） （山地/城市？）(水域)
#也存储了所有的地图key，可用于表示地图范围
var invis_state_map: Dictionary = {}  # Dictionary<Vector2i, int>



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

	# 加载可见的 CellInfo
	var visible_cells = init_data.get("visible_cells", {})
	for key in visible_cells.keys():
		var coord = parse_vector2i(key)
		var cell_info = CellInfo.from_dict(visible_cells[key])
		cell_map[coord] = cell_info

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
		var info = CellInfo.from_dict(delta["newly_visible"][key])
		cell_map[coord] = info
		emit_signal("tile_newly_visible", coord)

	for key in delta["now_invisible"]:
		var coord = parse_vector2i(key)
		if cell_map.has(coord):
			cell_map.erase(coord)
			emit_signal("tile_hidden", coord)

	for key in delta["changed"].keys():
		var coord = parse_vector2i(key)
		if cell_map.has(coord):
			var info = CellInfo.from_dict(delta["changed"][key])
			cell_map[coord] = info
			cell_map[coord].set_dirty_flag()
			emit_signal("tile_updated", coord)

# 更新（复制）general_to_player
func import_general_to_player(data: Dictionary) -> void:
	general_to_player.clear()
	for key in data.keys():
		general_to_player[key] = data[key]
