extends Node
@onready var main_layer: TileMapLayer = $MainLayer
@onready var number_labels: Control = $NumberLabels
@onready var color_layer: TileMapLayer = $ColorLayer
@onready var high_light_layer: TileMapLayer = $HighLightLayer
@onready var timer_turn: Timer = $"../Timers/Timer_turn"


# 单个格子输出地块层
func display_cell_terrain(tile_coords: Vector2i, cell: CellInfo) -> void:
	var terrain = cell.terrain_type
	if Global.TERRAIN_TILE_INFO.has(terrain):
		var info = Global.TERRAIN_TILE_INFO[terrain]
		main_layer.set_cell(
			tile_coords,
			info["source_id"],
			info["atlas_coords"],
			info["alternative_tile"]
		)
	else:
		main_layer.set_cell(tile_coords, -1, Vector2i(-1, -1), -1)  # 未知地块

# 单个格子输出owner层
func display_cell_owner(tile_coords: Vector2i, cell: CellInfo) -> void:
	var _owner = cell.owner
	if _owner > 0:
		color_layer.set_cell(tile_coords, 0, Vector2i(0, 0), _owner)
		number_labels. update_label_on_tile(tile_coords, cell.power)
	elif cell.terrain_type==Global.TERRAIN_CITY and _owner==0:
		color_layer.set_cell(tile_coords, 0, Vector2i(0, 0), 10)
		number_labels.update_label_on_tile(tile_coords,cell.power)
	else:
		color_layer.set_cell(tile_coords, -1, Vector2i(-1, -1), -1)

# 单个可见格子
func display_cell(tile_coords: Vector2i, cell: CellInfo) -> void:
	display_cell_terrain(tile_coords, cell)
	display_cell_owner(tile_coords, cell)

# 地图全部格子以可见输出（测试用）
func display_full_map(full_map: FullMap) -> void:
	number_labels. clear_all_labels()
	main_layer.clear()
	color_layer.clear()
	for tile_coords in full_map.grid_map.keys():
		var cell: CellInfo = full_map.get_cell(tile_coords)
		if cell:
			display_cell_terrain(tile_coords, cell)
			display_cell_owner(tile_coords, cell)

# 单个迷雾格子
func display_fog_cell(tile_coords: Vector2i, cell: CellInfo) -> void:
	# 如果是城市，则主图层显示为山（模拟遮蔽）
	if cell.terrain_type == Global.TERRAIN_CITY:
		main_layer.set_cell(tile_coords, 27, Vector2i(0, 0), 0)  # 山地tile代替显示
	# 迷雾颜色层统一显示颜色id为10（已经定义好的迷雾专用色）
	color_layer.set_cell(tile_coords, 0, Vector2i(0, 0), 10)
	# 移除标签（因为迷雾下不可显示数字）
	number_labels. clear_label_on_tile(tile_coords)


func display_map_for_player(full_map: FullMap, player_id: int) -> void:
	number_labels. clear_all_labels()
	main_layer.clear()
	color_layer.clear()
	var visible_tiles: Array[Vector2i] = full_map.get_visible_tiles_for_player(player_id)

	# 手动构造一个可见格子的“伪集合”
	var visible_set := {}
	for v in visible_tiles:
		visible_set[v] = true

	for tile_coords: Vector2i in full_map.grid_map.keys():
		var cell: CellInfo = full_map.get_cell(tile_coords)
		if visible_set.has(tile_coords):
			display_cell(tile_coords, cell)
		else:
			display_fog_cell(tile_coords, cell)


# 通过现有的地图，转化为fullmap
func curr_map_to_fullmap() -> FullMap:
	var new_map := FullMap.new()
	var capital_coords: Array[Vector2i] = []
	# 第一次遍历：先建立地图数据，记录所有主城格子
	for coords in main_layer.get_used_cells():
		var source_id := main_layer.get_cell_source_id(coords)
		var atlas_coords := main_layer.get_cell_atlas_coords(coords)
		var alt_tile := main_layer.get_cell_alternative_tile(coords)
		var terrain_type := Global.TERRAIN_EMPTY  # 默认空地
		for terrain in Global.TERRAIN_TILE_INFO.keys():
			var info = Global.TERRAIN_TILE_INFO[terrain]
			if info["source_id"] == source_id and info["atlas_coords"] == atlas_coords and info["alternative_tile"] == alt_tile:
				terrain_type = terrain
				break
		# 暂时 owner = 0，稍后主城再分配
		var owner := 0
		var power := 0  # 你也可以自定义读取标签里的 power
		var cell := CellInfo.new(terrain_type, owner, power)
		new_map.grid_map[coords] = cell
		if terrain_type == Global.TERRAIN_CAPITAL:
			capital_coords.append(coords)
	# 第二次遍历：分配每个主城的 owner 和 player（1 对 1）
	for i in range(capital_coords.size()):
		var coords = capital_coords[i]
		var id = i + 1  # 从 1 开始编号
		var cell = new_map.grid_map[coords]
		cell.owner = id
		cell.power = 100  # 初始兵力
		new_map.owner_to_player[id] = id  # owner 和 player 对应
	return new_map



#测试__________________________________________________________________________________________________________________________________________________________________
# 接受tile坐标，输出信息//测试用
func print_cell(tile_coords: Vector2i)->void:
	var source_id := main_layer.get_cell_source_id(tile_coords)
	var atlas_coords := main_layer.get_cell_atlas_coords(tile_coords)
	var alt_id := main_layer.get_cell_alternative_tile(tile_coords)
	if source_id != -1:
		print("位置坐标: ", tile_coords)
		print("Tile Source ID: ", source_id)
		print("Atlas 坐标: ", atlas_coords)
		print("Alternative Tile ID: ", alt_id)
	else:
		print("点击的是空格子: ", tile_coords)
	print(" ")
#测试__________________________________________________________________________________________________________________________________________________________________
