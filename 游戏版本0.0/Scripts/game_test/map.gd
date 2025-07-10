extends Node

# @onready var number_labels: Control = $NumberLabels
@onready var labels: Control = $Labels
@onready var color_layer: TileMapLayer = $ColorLayer
@onready var high_light_layer: TileMapLayer = $HighLightLayer


# 上一帧的可见格子集合，性能优化
var last_visible_tiles: Dictionary = {}  

# 改成普通变量，在 _ready 初始化一次
var main_layer: TileMapLayer

func _ready():
	main_layer = $MainLayer

# 单个可见格子输出地块层
func display_cell_terrain(tile_coords: Vector2i, cell: CellInfo) -> void:
	var terrain = cell.get_type()
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

# 单个可见格子输出owner层
func display_cell_owner(tile_coords: Vector2i, cell: CellInfo) -> void:
	var _owner = cell.get_general_id()
	if _owner > 0:
		color_layer.set_cell(tile_coords, 0, Vector2i(0, 0), _owner)
		labels.update_label_on_tile(tile_coords, str(cell.get_power()))
	elif cell.get_type() == Global.TERRAIN_CITY and _owner == 0:
		color_layer.set_cell(tile_coords, 0, Vector2i(0, 0), 10)
		labels.update_label_on_tile(tile_coords, str(cell.get_power()))
	elif cell.get_power() != 0:
		color_layer.set_cell(tile_coords, 0, Vector2i(0, 0), 10)
		labels.update_label_on_tile(tile_coords, str(cell.get_power()))
	else:
		color_layer.set_cell(tile_coords, -1, Vector2i(-1, -1), -1)

# 单个格子输出标签层
func display_cell_label(tile_coords: Vector2i, cell: CellInfo) -> void:
	if cell.get_power() != 0 or cell.get_type()==Global.TERRAIN_CITY:
		labels.update_label_on_tile(tile_coords, str(cell.get_power()))
	else:
		labels.clear_label_on_tile(tile_coords)
	pass

# 单个格子设置高光
func highlight_cell(coords: Vector2i) -> void:
	high_light_layer.set_cell(coords, 0, Vector2i(0, 0), 1)
	pass

# 单个格子取消高光
func unhighlight_cell(coords: Vector2i) -> void:
	high_light_layer.set_cell(coords, -1, Vector2i(-1, -1), -1)
	pass

# 单个可见格子#脏数据优化
func display_cell(tile_coords: Vector2i, cell: CellInfo) -> void:
	if cell.is_dirty():
		display_cell_terrain(tile_coords, cell)
		display_cell_owner(tile_coords, cell)
		display_cell_label(tile_coords, cell)
		cell.clear_dirty_flag()

# 单个迷雾格子
func display_fog_cell(tile_coords: Vector2i, cell: CellInfo) -> void:
	# 如果是城市，则主图层显示为山（模拟遮蔽）
	if cell.get_type() == Global.TERRAIN_CITY:
		main_layer.set_cell(tile_coords, 27, Vector2i(0, 0), 0)  # 山地tile代替显示
	else:
		display_cell_terrain(tile_coords,cell)
	# 迷雾颜色层统一显示颜色id为10（已经定义好的迷雾专用色）
	color_layer.set_cell(tile_coords, 0, Vector2i(0, 0), 10)
	# 移除标签（因为迷雾下不可显示数字）
	labels.clear_label_on_tile(tile_coords)
	cell.set_dirty_flag()

# 取消全部高光
func unhighlight_all_cells() -> void:
	high_light_layer.clear()
	pass

func set_label(tile_coords: Vector2i, text: String)->void:
	labels. update_label_on_tile(tile_coords, text)


# 单个箭头
func draw_arrow_label(tile_coords: Vector2i, direction_index: int) -> void:
	labels.draw_arrow_label(tile_coords, direction_index)

# ——————————————————————————————————————————外部接口
# 清除全部箭头
func clear_all_arrows() -> void:
	labels.clear_all_arrows()
# 绘制行动箭头组
func draw_arrow_batch_from_actions(actions: Array) -> void:
	for action in actions:
		if typeof(action) == TYPE_DICTIONARY and action.has("from") and action.has("dir"):
			draw_arrow_label(action["from"], action["dir"])
		else:
			push_warning("无效箭头数据: " + str(action))

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
		var general := 0
		var power := 0  # 你也可以自定义读取标签里的 power
		var cell := CellInfo.new(terrain_type, general, power)
		new_map.cell_map[coords] = cell
		if terrain_type == Global.TERRAIN_CAPITAL:
			capital_coords.append(coords)
	# 第二次遍历：分配每个主城的 general 和 player（1 对 1）
	new_map.general_id_to_player_id[0] = 0
	for i in range(capital_coords.size()):
		var coords = capital_coords[i]
		var id = i + 1  # 从 1 开始编号
		var cell = new_map.cell_map[coords]
		cell.set_general_id(id)
		cell.set_power(100)  # 初始兵力
		new_map.general_id_to_player_id[id] = id  # owner 和 player 对应
	new_map.general_count=capital_coords.size()
	new_map.player_count=capital_coords.size()
	new_map.update_general_index()
	return new_map

# 上帝视角显示地图
func display_full_map(full_map: FullMap) -> void:
	for tile_coords in full_map.cell_map.keys():
		var cell: CellInfo = full_map.get_cell(tile_coords)
		if cell:
			display_cell(tile_coords, cell)

# 以“迷雾”方式显示整张地图（全图隐藏信息）(地图初始化时使用)
func display_full_map_fog(full_map: FullMap) -> void:
	for tile_coords in full_map.cell_map.keys():
		var cell: CellInfo = full_map.get_cell(tile_coords)
		if cell:
			display_fog_cell(tile_coords, cell)

# 以“迷雾”方式显示整张地图（全图隐藏信息）(地图初始化时使用)
func display_playermap_fog(player_map: PlayerMap) -> void:
	for tile_coords in player_map.invis_state_map.keys():
		display_invis_tile(tile_coords, player_map.invis_state_map[tile_coords])

# 玩家视角显示地图(fullmap)
func display_map_for_player(full_map: FullMap, player_id: int) -> void:
	# 性能优化测试时间var t0 := Time.get_ticks_msec()  # 起始时间
	var current_visible_tiles: Array[Vector2i] = full_map.get_visible_tiles_for_player(player_id)
	# var t1 := Time.get_ticks_msec()  # 结束时间
	# print("获取可见表耗时: ", t1 - t0, " 毫秒")

	# 当前帧可见格子 → 转为字典模拟集合
	var current_visible_set := {}
	for coord in current_visible_tiles:
		current_visible_set[coord] = true

	# Step 1: 上一帧中但不在当前帧中的格子 → 设置迷雾
	for coord in last_visible_tiles.keys():
		if not current_visible_set.has(coord):
			var cell := full_map.get_cell(coord)
			if cell:
				display_fog_cell(coord, cell)

	# Step 2: 当前帧中所有可见格子 → 显示真实信息
	for coord in current_visible_set.keys():
		var cell := full_map.get_cell(coord)
		if cell:
			display_cell(coord, cell)

	# 更新上一帧可见格子集合
	last_visible_tiles = current_visible_set.duplicate()


func display_invis_tile(tile_coords: Vector2i, terrain)->void:
	# 显示底层
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
	pass
	# 显示general层，迷雾
	# 迷雾颜色层统一（已经定义好的迷雾专用色）
	color_layer.set_cell(tile_coords, 0, Vector2i(0, 0), 10)
	# 移除标签（因为迷雾下不可显示数字或者其他的什么东西）
	labels.clear_label_on_tile(tile_coords)



# 玩家视角显示地图(playermap)
func display_playermap(player_map: PlayerMap) -> void:
	var current_visible_tiles: Array[Vector2i] = []
	for key in player_map.cell_map.keys():
		current_visible_tiles.append(Vector2i(key))
	var current_visible_set: Dictionary = {}
	for coord in current_visible_tiles:
		current_visible_set[coord] = true

	# Step 1: 上一帧中但不在当前帧中的格子 → 设置迷雾
	for coord in last_visible_tiles.keys():
		if not current_visible_set.has(coord):
			var state :int= player_map.invis_state_map[coord]
			display_invis_tile(coord, state)

	# Step 2: 当前帧中所有可见格子 → 显示真实信息
	for coord in current_visible_tiles:
		var cell := player_map.get_cell(coord)
		if cell:
			display_cell(coord, cell)

	# Step 3: 更新上一帧的可见格子字典
	last_visible_tiles.clear()
	for coord in current_visible_tiles:
		last_visible_tiles[coord] = true



# 屏幕坐标转格子坐标
func get_tile_coords_from_screen_pos(screen_pos: Vector2) -> Vector2i:
	var world_pos = main_layer.get_viewport_transform().affine_inverse() * screen_pos
	var local_pos = main_layer.to_local(world_pos)
	return main_layer.local_to_map(local_pos)

func clear()->void:
	main_layer.clear()
	labels.clear_all_numbers()
	color_layer.clear()
	pass


#测试__________________________________________________________________________________________________________________________________________________________________
# 接受tile坐标，输出信息//测试用
func print_cell(tile_coords: Vector2i) -> void:
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
