# FullMap.gd
class_name FullMap
extends BaseMap

# 数据结构
var general_count:int
var player_count:int
# 游戏逻辑辅助的数据
var general_actions: Array = []  # 操作队列，同步用
var acted_generals: Dictionary = {}  # 记录已经行动过的 general，key = general_id，同步用

# 因为玩家操作引起变化的格子
var acted_coords: Dictionary = {}  # key: Vector2i, value: true

# 性能优化，存储每个general的领地集合，每回合刷新
var general_to_coords: Dictionary = {}

var last_visible_tiles: Dictionary = {}  # player_id → 上一回合的可见格子 Set
var player_delta: Dictionary = {}  # player_id → delta 字典

# ——————————初始化部分

# 随机创建地图，测试用，参数为：地图大小，玩家数量，general数量
func random_init(radius: int, _player_count: int, _general_count: int) -> void:
	cell_map.clear()
	general_id_to_player_id.clear()
	general_count=_general_count
	player_count=_player_count
	var candidate_coords: Array[Vector2i] = []

	for dq in range(-radius, radius + 1):
		for dr in range(-radius, radius + 1):
			var coord = Vector2i(dq, dr)
			var dist = max(abs(coord.x), abs(coord.y), abs(coord.x + coord.y))
			if dist <= radius:
				var terrain := Global.TERRAIN_EMPTY
				var power := 0
				var roll := randi() % 100
				if roll < 10:
					terrain = Global.TERRAIN_MOUNTAIN
				elif roll < 20:
					terrain = Global.TERRAIN_WATER
				elif roll < 30:
					terrain = Global.TERRAIN_CITY
					power = 10 + randi() % 21
				if terrain == Global.TERRAIN_EMPTY:
					candidate_coords.append(coord)
				cell_map[coord] = CellInfo.new(terrain, 0, power)

	candidate_coords.shuffle()
	var max_generals: int = min(_general_count, candidate_coords.size())
	general_id_to_player_id[0] = 0
	for general_id in range(1, max_generals + 1):
		var coord = candidate_coords[general_id - 1]
		var cell: CellInfo = cell_map[coord]
		cell.set_type(Global.TERRAIN_CAPITAL)
		cell.set_general_id(general_id)
		cell.set_power(100)
		if general_id <= _player_count:
			general_id_to_player_id[general_id] = general_id
		else:
			general_id_to_player_id[general_id] = 0
	# 更新general的领土表
	update_general_index()

# 根据现有map构建fullmap，详情看map类

# -------------------------------------------更新同步
# 为玩家init导出数据，同步用
func export_init_data_for_player(player_id: int) -> Dictionary:
	var init_data: Dictionary = {}
	
	init_data["player_id"]=player_id
	init_data["turn_count"] = turn_count
	init_data["general_id_to_player_id"] = general_id_to_player_id.duplicate()

	# 导出地图范围 + 玩家可见区域的 cell_map 数据
	var vis_coords = get_visible_tiles_for_player(player_id)
	var cell_info_dict := {}
	for coord in vis_coords:
		if cell_map.has(coord):
			cell_info_dict[str(coord)] = cell_map[coord].to_dict()
	init_data["visible_cells"] = cell_info_dict

	# 构建invis_state_map
	var invis_state := {}
	for coord in cell_map.keys():
		var cell = cell_map[coord]
		var state: int = -1
		match cell.get_type():
			Global.TERRAIN_MOUNTAIN, Global.TERRAIN_CITY:
				state = Global.INVIS_MOUNTAIN
			Global.TERRAIN_EMPTY, Global.TERRAIN_CAPITAL:
				state = Global.INVIS_EMPTY
			Global.TERRAIN_WATER:
				state = Global.INVIS_WATER
		invis_state[str(coord)] = state
	init_data["invis_state_map"] = invis_state

	return init_data

func get_all_player_ids() -> Array[int]:
	var result: Array[int] = []
	for i in range(1, player_count + 1):
		
		result.append(i)
	return result

# 计算回合的玩家视野变化以及操作引起的变化量，然后存起来，便于调用
func compute_player_deltas() -> void:
	player_delta.clear()

	for player_id in get_all_player_ids():
		var current: Array = get_visible_tiles_for_player(player_id)
		var last: Array = last_visible_tiles.get(player_id, [])

		var current_set := {}
		for c in current:
			current_set[c] = true
		var last_set := {}
		for l in last:
			last_set[l] = true

		var newly_visible := {}
		for c in current_set.keys():
			if not last_set.has(c) and cell_map.has(c):
				newly_visible[str(c)] = cell_map[c].to_dict()

		var now_invisible: Array[String] = []
		for l in last_set.keys():
			if not current_set.has(l):
				now_invisible.append(str(l))

		var changed := {}
		for coord in acted_coords.keys():
			if current_set.has(coord) and cell_map.has(coord):
				changed[str(coord)] = cell_map[coord].to_dict()

		player_delta[player_id] = {
			"newly_visible": newly_visible,
			"now_invisible": now_invisible,
			"changed": changed
		}

		last_visible_tiles[player_id] = current

# 导出玩家视野变化以及操作引起的变化量，用于同步
func export_player_delta(player_id: int) -> Dictionary:
	return player_delta.get(player_id, {
		"newly_visible": [],
		"now_invisible": [],
		"changed": []
	})
# 导出general_id_to_player_id表，用于同步
func export_general_id_to_player_id() -> Dictionary:
	return general_id_to_player_id.duplicate()

# 同步部分结束——------————————————————————————————————————————


# 更新general领地索引，游戏中每回合更新
# 如果测试时手动改了数据但是没有刷新回合，要调用这个函数再使用get_visible_tiles_for_general/player，不然显示更新数据以前的对应坐标集
func update_general_index() -> void:
	general_to_coords.clear()
	for coord in cell_map.keys():
		var cell :CellInfo= cell_map[coord]
		var _general := cell.get_general_id()
		if _general == 0:
			continue
		if not general_to_coords.has(_general):
			general_to_coords[_general] = []
		(general_to_coords[_general] as Array[Vector2i]).append(coord)


# 输入generalid，输出一个坐标集 表示这个general的可见范围
func get_visible_tiles_for_general(general_id: int) -> Array[Vector2i]:
	var visible_set := {}

	if not general_to_coords.has(general_id):
		return []  # 没有格子直接返回空列表

	for coord in general_to_coords[general_id]:
		visible_set[coord] = true
		for dir in Global.HEX_DIRECTIONS:
			var neighbor = coord + dir
			if cell_map.has(neighbor):
				visible_set[neighbor] = true
	var result: Array[Vector2i] = []
	for key in visible_set.keys():
		result.append(key)
	return result


# 输入playerid，输出一个坐标集 表示这个player的可见范围
func get_visible_tiles_for_player(player_id: int) -> Array[Vector2i]:
	var visible_set := {}
	# 从对应的general取并集到result
	for general_id in general_id_to_player_id.keys():
		if general_id_to_player_id[general_id] == player_id:
			var tiles = get_visible_tiles_for_general(general_id)
			for tile in tiles:
				visible_set[tile] = true
	var result: Array[Vector2i] = []
	for key in visible_set.keys():
		result.append(key)
	return result






# ————————————————————————————————————————————————————————这下面是游戏逻辑相关的

func move_power(from_coords: Vector2i, direction_index: int, ratio: float) -> bool:
	if not cell_map.has(from_coords):
		return false
	if direction_index < 0 or direction_index >= Global.HEX_DIRECTIONS.size():
		return false
	
	var dir: Vector2i = Global.HEX_DIRECTIONS[direction_index]
	var to_coords: Vector2i = from_coords + dir
	return move_power_help(from_coords, to_coords, ratio)

func move_power_help(from_coords: Vector2i, to_coords: Vector2i, ratio: float) -> bool:
	if not cell_map.has(from_coords) or not cell_map.has(to_coords):
		return false
	
	var from_cell: CellInfo = cell_map[from_coords]
	var to_cell: CellInfo = cell_map[to_coords]

	if from_cell.get_general_id() == 0:
		return false
	if from_cell.get_power() <= 1:
		return false
	if to_cell.get_type() == Global.TERRAIN_MOUNTAIN:
		return false

	var total_power := from_cell.get_power()
	var move_amount := int(clamp(total_power * ratio, 1, total_power - 1))
	if move_amount <= 0:
		return false
	# 判断为可以移动，fromcell减去兵力
	from_cell.set_power(total_power - move_amount)
	#添加到操作引起的变动表，用于联网的同步优化
	acted_coords[from_coords] = true
	acted_coords[to_coords] = true
	# 同一个 general，直接合兵
	if to_cell.get_general_id() == from_cell.get_general_id():
		to_cell.set_power(to_cell.get_power() + move_amount)
	else:
		var last_power = to_cell.get_power() - move_amount
		if last_power > 0:
			to_cell.set_power(last_power)
		# 兵力相同，双方消耗兵力但是不能占领
		elif last_power == 0:
			to_cell.set_power(0)
			# to_cell.set_general_id(0)原有的general不变，为了避免capital或者city变为general0的情况
		else:
			if to_cell.get_type() == Global.TERRAIN_CAPITAL:
				occupy_general(from_cell.get_general_id(), to_cell.get_general_id())
				from_cell.set_power(from_cell.get_power() + move_amount)
				return true
			to_cell.set_power(move_amount - to_cell.get_power())
			to_cell.set_general_id(from_cell.get_general_id())
			general_id_to_player_id[to_cell.get_general_id()] = general_id_to_player_id[from_cell.get_general_id()]
	
	return true

func occupy_general(from_general_id: int, to_general_id: int) -> void:
	if from_general_id == to_general_id:
		return
	if not general_id_to_player_id.has(from_general_id):
		push_error("占领失败：from_general_id 不存在")
		return
	if not general_id_to_player_id.has(to_general_id):
		push_error("占领失败：to_general_id 不存在")
		return
	var player_id: int = general_id_to_player_id[from_general_id]
	general_id_to_player_id[to_general_id] = player_id


# general用这个函数进行操作，避免一回合操作多次
func add_general_action(from_coords: Vector2i, direction_index: int, ratio: float) -> bool:
	if not cell_map.has(from_coords):
		return false
	var from_cell: CellInfo = cell_map[from_coords]
	var general_id = from_cell.get_general_id()
	if general_id == 0 or acted_generals.has(general_id):
		return false
	general_actions.append({
		"from": from_coords,
		"dir": direction_index,
		"ratio": ratio
	})
	acted_generals[general_id] = true
	return true

func execute_turn() -> void:
	update_power_by_terrain()
	# 结算玩家操作
	for action in general_actions:
		move_power(action["from"], action["dir"], action["ratio"])
	general_actions.clear()
	acted_generals.clear()
	# 更新general可见表
	update_general_index()
	# 更新玩家可见表，并计算玩家视野delta
	compute_player_deltas()
