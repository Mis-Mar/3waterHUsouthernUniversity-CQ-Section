# FullMap.gd
class_name FullMap
extends Node 

# 数据结构
var grid_map: Dictionary = {}  # Dictionary<Vector2i, GridCell>所有格子的字典，就当CellInfo类型的二维数组来用
var owner_to_player: Dictionary = {}# 表格，一个owner有一个player，一个player对应多个owner 值为0表示未被控制,-1表示已经消灭
var turn_count: int = 0  # 回合总数
const HEX_DIRECTIONS := [# 六边形邻接向量，见global.gd有全局变量
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1),
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0)
]

# 游戏逻辑辅助的数据
var pending_actions: Array = []  # 操作队列，同步用
var acted_owners: Dictionary = {}  # 记录已经行动过的 owner，key = owner_id，同步用
# 性能优化，存储每个owner的领地集合，每回合刷新
var owner_to_coords: Dictionary = {}


# ——————————————————————————————————————————————————纯算法相关的方法
# 返回对应坐标的CellInfo
func get_cell(coords: Vector2i) -> CellInfo:
	if grid_map.has(coords):
		return grid_map[coords]
	return null

# 获取这个地图包含的全部坐标
func get_all_coords() -> Array[Vector2i]:
	return grid_map.keys()

# 检查某个坐标是否存在
func is_valid_coord(coord: Vector2i) -> bool:
	return grid_map.has(coord)

func check_cell_player(coord: Vector2i, player_id: int) -> bool:
	if is_valid_coord(coord):
		return owner_to_player[get_cell(coord).get_owner()] == player_id
	else:
		printerr("坐标超界")
		return false

# 设置一个格子的power
func set_power(coord: Vector2i, new_power) -> void:
	if is_valid_coord(coord):
		get_cell(coord).set_power(new_power)
	else:
		printerr("坐标超界")
	return

# 判断一个格子是否属于一个玩家
func cell_belong_player(coords: Vector2i, player_id: int) -> bool:
	var cell = grid_map.get(coords)
	if cell == null:
		return false  # 坐标非法或格子不存在
	var owner_id = cell.get_owner()
	return owner_to_player.get(owner_id, -1) == player_id

# 判断一格子是否能被一个玩家看见
func cell_visible_for_player(coords: Vector2i, player_id: int) -> bool:
	if cell_belong_player(coords, player_id):
		return true  # 自己的地块可见
	# 检查邻接六个方向
	for dir in HEX_DIRECTIONS:
		var neighbor = coords + dir
		if cell_belong_player(neighbor, player_id):
			return true  # 邻居是自己的也可见
	return false

# 判断两个格子是否相邻,返回邻接向量序号
func get_adjacent_vector_id(pos_a: Vector2i, pos_b: Vector2i) -> int:
	for i in HEX_DIRECTIONS.size():
		if pos_a + HEX_DIRECTIONS[i] == pos_b:
			return i  # 返回邻接方向的索引
	return -1  # 不相邻


# 更新owner领地索引，游戏中每回合更新
# 如果测试时手动改了数据但是没有刷新回合，要调用这个函数再使用get_visible_tiles_for_owner/player，不然显示更新数据以前的对应坐标集
func update_owner_index() -> void:
	owner_to_coords.clear()
	for coord in grid_map.keys():
		var cell :CellInfo= grid_map[coord]
		var owner := cell.get_owner()
		if owner == 0:
			continue
		if not owner_to_coords.has(owner):
			owner_to_coords[owner] = []
		(owner_to_coords[owner] as Array[Vector2i]).append(coord)



# 输入ownerid，输出一个坐标集 表示这个owner的可见范围
func get_visible_tiles_for_owner(owner_id: int) -> Array[Vector2i]:
	var visible_set := {}

	if not owner_to_coords.has(owner_id):
		return []  # 没有格子直接返回空列表

	for coord in owner_to_coords[owner_id]:
		visible_set[coord] = true
		for dir in HEX_DIRECTIONS:
			var neighbor = coord + dir
			if grid_map.has(neighbor):
				visible_set[neighbor] = true
	var result: Array[Vector2i] = []
	for key in visible_set.keys():
		result.append(key)
	return result


# 输入playerid，输出一个坐标集 表示这个player的可见范围
func get_visible_tiles_for_player(player_id: int) -> Array[Vector2i]:
	var visible_set := {}
	for owner_id in owner_to_player.keys():
		if owner_to_player[owner_id] == player_id:
			var tiles = get_visible_tiles_for_owner(owner_id)
			for tile in tiles:
				visible_set[tile] = true
	var result: Array[Vector2i] = []
	for key in visible_set.keys():
		result.append(key)
	return result

# 输入一个格子坐标，返回与它相邻的存在于地图中的坐标集
# state0: 排除山地
func get_neighbors_state0(center: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in HEX_DIRECTIONS:
		var neighbor_coords: Vector2i = center + dir
		if grid_map.has(neighbor_coords):
			if get_cell(neighbor_coords).get_type() != Global.TERRAIN_MOUNTAIN:
				neighbors.append(neighbor_coords)
	return neighbors

# state1: 排除山地和非己方节点
func get_neighbors_state1(center: Vector2i, _player_id: int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in HEX_DIRECTIONS:
		var neighbor_coords: Vector2i = center + dir
		if grid_map.has(neighbor_coords):
			var cell := get_cell(neighbor_coords)
			if cell.get_type() != Global.TERRAIN_MOUNTAIN and cell.get_owner() == _player_id:
				neighbors.append(neighbor_coords)
	return neighbors

# 随机创建地图，测试用，参数为：地图大小，玩家数量，owner数量
func random_init(radius: int, player_count: int, owner_count: int) -> void:
	grid_map.clear()
	owner_to_player.clear()

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
				grid_map[coord] = CellInfo.new(terrain, 0, power)

	candidate_coords.shuffle()
	var max_owners: int = min(owner_count, candidate_coords.size())

	for owner_id in range(1, max_owners + 1):
		var coord = candidate_coords[owner_id - 1]
		var cell: CellInfo = grid_map[coord]
		cell.set_type(Global.TERRAIN_CAPITAL)
		cell.set_owner(owner_id)
		cell.set_power(100)
		if owner_id <= player_count:
			owner_to_player[owner_id] = owner_id
		else:
			owner_to_player[owner_id] = 0
	# 更新owner的领土表
	update_owner_index()




# ————————————————————————————————————————————————————————这下面是游戏逻辑相关的

func move_power(from_coords: Vector2i, direction_index: int, ratio: float) -> bool:
	if not grid_map.has(from_coords):
		return false
	if direction_index < 0 or direction_index >= HEX_DIRECTIONS.size():
		return false
	var dir: Vector2i = HEX_DIRECTIONS[direction_index]
	var to_coords: Vector2i = from_coords + dir
	if not grid_map.has(to_coords):
		return false
	
	var from_cell: CellInfo = grid_map[from_coords]
	var total_power := from_cell.get_power()
	if from_cell.get_owner() == 0:
		return false
	if total_power <= 1:
		return false
	var move_amount := int(clamp(total_power * ratio, 1, total_power - 1))
	if move_amount <= 0:
		return false

	var to_cell: CellInfo = grid_map[to_coords]
	if to_cell.get_type() == Global.TERRAIN_MOUNTAIN:
		return false

	from_cell.set_power(total_power - move_amount)

	if to_cell.get_owner() == from_cell.get_owner():
		to_cell.set_power(to_cell.get_power() + move_amount)
	else:
		var last_power = to_cell.get_power() - move_amount
		if last_power > 0:
			to_cell.set_power(last_power)
		elif last_power == 0:
			to_cell.set_owner(0)
		else:
			if to_cell.get_type() == Global.TERRAIN_CAPITAL:
				occupy_owner(from_cell.get_owner(), to_cell.get_owner())
				from_cell.set_power(from_cell.get_power() + move_amount)
				return true
			to_cell.set_power(move_amount - to_cell.get_power())
			to_cell.set_owner(from_cell.get_owner())
			owner_to_player[to_cell.get_owner()] = owner_to_player[from_cell.get_owner()]
	return true

func occupy_owner(from_owner_id: int, to_owner_id: int) -> void:
	if from_owner_id == to_owner_id:
		return
	if not owner_to_player.has(from_owner_id):
		push_error("占领失败：from_owner_id 不存在")
		return
	if not owner_to_player.has(to_owner_id):
		push_error("占领失败：to_owner_id 不存在")
		return
	var player_id: int = owner_to_player[from_owner_id]
	owner_to_player[to_owner_id] = player_id

func queue_action(from_coords: Vector2i, direction_index: int, ratio: float) -> bool:
	if not grid_map.has(from_coords):
		return false
	var from_cell: CellInfo = grid_map[from_coords]
	var owner_id = from_cell.get_owner()
	if owner_id == 0 or acted_owners.has(owner_id):
		return false
	pending_actions.append({
		"from": from_coords,
		"dir": direction_index,
		"ratio": ratio
	})
	acted_owners[owner_id] = true
	return true

func execute_turn() -> void:
	turn_count += 1
	for coords in grid_map.keys():
		var cell: CellInfo = grid_map[coords]
		var _owner := cell.get_owner()
		if _owner == 0:
			continue
		var player: int = owner_to_player.get(_owner, 0)
		if player == 0:
			continue

		var cell_type := cell.get_type()

		if cell_type == Global.TERRAIN_CITY or cell_type == Global.TERRAIN_CAPITAL:
			cell.set_power(cell.get_power() + 1)
		elif turn_count % 25 == 0 and cell_type == Global.TERRAIN_EMPTY:
			cell.set_power(cell.get_power() + 1)
		elif cell_type == Global.TERRAIN_WATER:
			var power := cell.get_power()
			if power > 0:
				power -= 1
				cell.set_power(power)
				if power == 0:
					cell.set_owner(0)
	
	for action in pending_actions:
		move_power(action["from"], action["dir"], action["ratio"])
	pending_actions.clear()
	acted_owners.clear()
	
	update_owner_index()
