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

# 输入ownerid，输出一个坐标集 表示这个owner的可见范围
func get_visible_tiles_for_owner(owner_id: int) -> Array[Vector2i]:
	var visible_set := {}  # Dictionary 作为伪 Set
	for coords: Vector2i in grid_map.keys():
		var cell = grid_map[coords]
		if cell.owner == owner_id:
			visible_set[coords] = true
			for dir: Vector2i in HEX_DIRECTIONS:
				var neighbor: Vector2i = coords + dir
				if grid_map.has(neighbor):
					visible_set[neighbor] = true
	# 手动构建 Array[Vector2i]
	var result: Array[Vector2i] = []
	for key in visible_set.keys():
		result.append(key)
	return result

# 输入playerid，输出一个坐标集 表示这个player的可见范围
func get_visible_tiles_for_player(player_id: int) -> Array[Vector2i]:
	var visible_set := {}  # Dictionary 作为伪 Set，key 为 Vector2i
	for owner_id in owner_to_player.keys():
		if owner_to_player[owner_id] == player_id:
			var tiles = get_visible_tiles_for_owner(owner_id)
			for tile in tiles:
				visible_set[tile] = true  # 加入集合
	# 转换为 Array[Vector2i]
	var result: Array[Vector2i] = []
	for key in visible_set.keys():
		result.append(key)
	return result

# 输入一个格子坐标，返回与它相邻的存在于地图中的坐标集
func get_neighbors(center: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in HEX_DIRECTIONS:
		var neighbor_coords :Vector2i= center + dir
		if grid_map.has(neighbor_coords):
			neighbors.append(neighbor_coords)
	return neighbors


# 随机创建地图，测试用，参数为：地图大小，玩家数量，owner数量
func random_init(radius: int, player_count: int, owner_count: int) -> void:
	grid_map.clear()
	owner_to_player.clear()

	var candidate_coords: Array[Vector2i] = []

	# 生成地形
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
					power = 10 + randi() % 21  # 城市占领所需兵力 10~30

				if terrain == Global.TERRAIN_EMPTY:
					candidate_coords.append(coord)

				grid_map[coord] = CellInfo.new(terrain, 0, power)

	# 分配主城
	candidate_coords.shuffle()
	var max_owners: int = min(owner_count, candidate_coords.size())

	for owner_id in range(1, max_owners + 1):
		var coord = candidate_coords[owner_id - 1]
		var cell: CellInfo = grid_map[coord]
		cell.terrain_type = Global.TERRAIN_CAPITAL
		cell.owner = owner_id
		cell.power = 100

		# 玩家控制前 player_count 个 owner，其余为未控制
		if owner_id <= player_count:
			owner_to_player[owner_id] = owner_id  # 玩家ID == ownerID
		else:
			owner_to_player[owner_id] = 0  # 0 表示未控制（你设定的默认值）


#————————————————————————————————————————————————————————————————这下面是游戏逻辑相关的
# 从某个坐标朝一个方向移动部分兵力,进行派兵操作并返回是否移动成功
func move_power(from_coords: Vector2i, direction_index: int, ratio: float) -> bool:
	# 边界检查
	if not grid_map.has(from_coords):
		return false

	if direction_index < 0 or direction_index >= HEX_DIRECTIONS.size():
		return false

	var from_cell: CellInfo = grid_map[from_coords]
	var total_power := from_cell.power

	if total_power <= 1:
		return false # 没有可以移动的兵力

	var move_amount := int(clamp(total_power * ratio, 1, total_power - 1))
	if move_amount <= 0:
		return false # 移动量不足

	var dir: Vector2i = HEX_DIRECTIONS[direction_index]
	var to_coords: Vector2i = from_coords + dir

	if not grid_map.has(to_coords):
		return false # 目标格子不存在

	var to_cell: CellInfo = grid_map[to_coords]
	if to_cell.terrain_type == Global.TERRAIN_MOUNTAIN:
		return false # 山地，不可进入

	# 起始格子兵力减少
	from_cell.power -= move_amount


	if to_cell.owner == from_cell.owner:
		# 友军地块，叠加兵力
		to_cell.power += move_amount
	else:
		# 敌军/中立地块，发生战斗
		var last_power = to_cell.power- move_amount
		if last_power > 0:
			# 敌方守住，owner 不变
			to_cell.power=last_power
			pass
		elif last_power == 0:
			to_cell.owner = 0  # 双方同归于尽
		else:
			# 攻方胜利，改旗易帜
			if to_cell.terrain_type==Global.TERRAIN_CAPITAL: 
				# 攻方占领的是capital,不改owner，而是改player
				occupy_owner(from_cell.owner,to_cell.owner)
				from_cell.power+=move_amount
				return true
			to_cell.power = move_amount-to_cell.power
			to_cell.owner = from_cell.owner
			owner_to_player[to_cell.owner]=owner_to_player[from_cell.owner]
	return true

# 一个owner占领另一个owner，接受两个参数，是这两个owner的id
func occupy_owner(from_owner_id: int, to_owner_id: int) -> void:
	# 不允许自己占自己
	if from_owner_id == to_owner_id:
		return
	# 检查两个 owner 是否都存在
	if not owner_to_player.has(from_owner_id):
		push_error("占领失败：from_owner_id 不存在")
		return
	if not owner_to_player.has(to_owner_id):
		push_error("占领失败：to_owner_id 不存在")
		return
	# 获取玩家 ID
	var player_id :int= owner_to_player[from_owner_id]
	# 更新控制权
	owner_to_player[to_owner_id] = player_id
	
# 尝试记录一项操作
func queue_action(from_coords: Vector2i, direction_index: int, ratio: float) -> bool:
	if not grid_map.has(from_coords):
		return false

	var from_cell: CellInfo = grid_map[from_coords]
	var owner_id = from_cell.owner
	if owner_id == 0 or acted_owners.has(owner_id):
		return false  # 无主 or 已操作

	# 记录操作
	pending_actions.append({
		"from": from_coords,
		"dir": direction_index,
		"ratio": ratio
	})
	acted_owners[owner_id] = true
	return true
# 结算回合
func execute_turn() -> void:
	#回合数更新
	turn_count += 1
	#更新资源
	for coords in grid_map.keys():
		var cell: CellInfo = grid_map[coords]
		var _owner := cell.owner
		var player :int= owner_to_player.get(_owner, 0)

		# (1) 城市 / 主城增长
		if (cell.terrain_type == Global.TERRAIN_CITY or cell.terrain_type == Global.TERRAIN_CAPITAL) and _owner != 0 and player != 0:
			cell.power += 1

		# (2) 每 25 回合：空地增长
		if turn_count % 25 == 0 and cell.terrain_type == Global.TERRAIN_EMPTY and _owner != 0:
			cell.power += 1
		
		# (3) 水域每回合减 1
		if cell.terrain_type == Global.TERRAIN_WATER and cell.power > 0:
			cell.power -= 1
			if cell.power == 0:
				# 防止某个块power为0但还是有owner
				cell.owner = 0
	#执行所有owner操作
	for action in pending_actions:
		move_power(action["from"], action["dir"], action["ratio"])
	pending_actions.clear()
	acted_owners.clear()
