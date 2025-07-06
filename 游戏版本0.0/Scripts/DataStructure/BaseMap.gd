# BaseMap.gd
extends Node
class_name BaseMap

# 数据结构
var cell_map: Dictionary = {}  # Dictionary<Vector2i, GridCell>所有格子的字典，就当CellInfo类型的二维数组来用
var general_id_to_player_id: Dictionary = {}# 表格，一个general有一个player，一个player对应多个general 值为0表示未被控制
var turn_count: int = 0  # 回合总数
 
func get_cell(coords: Vector2i) -> CellInfo:
	if cell_map.has(coords):
		return cell_map[coords]
	return null

# 获取这个地图包含的全部坐标
func get_all_coords() -> Array[Vector2i]:
	return cell_map.keys()

# 检查某个坐标是否存在
func is_valid_coord(coord: Vector2i) -> bool:
	return cell_map.has(coord)
	
func get_distance_2coords(coord1: Vector2i, coord2: Vector2i) -> int:
	if is_valid_coord(coord1) and is_valid_coord(coord2):
		return max(abs(coord1.x - coord2.x), abs(coord1.y - coord2.y), abs((coord1.x-coord1.y) - (coord2.x-coord2.y)))
	else:
		printerr("坐标超界")
		return -1

func get_direction(start_coord: Vector2i, end_coord: Vector2i) -> Vector2i:
	var vector: Vector2i = end_coord - start_coord
	if vector.x>=1 and vector.x>vector.y and vector.y>=0:
		return Vector2i(1,0)
	elif vector.y>=1 and vector.y>=vector.x and vector.x>=1:
		return Vector2i(1,1)
	elif vector.y>=1 and vector.x<=0:
		return Vector2i(0,1)
	elif vector.x<=-1 and vector.x<vector.y and vector.y<=0:
		return Vector2i(-1,0)
	elif vector.y<=-1 and vector.y<=vector.x and vector.x<=-1:
		return Vector2i(-1,-1)
	elif vector.y<=-1 and vector.x>=0:
		return Vector2i(0,-1)
	else:
		return Vector2i(0,0)
	
func spiral_rings_traversal(center: Vector2i, radius: int) -> Array:
	var result: Array = [center]
	for j in range(1,radius):
		result.append(ring_traversal(center,j))
	return result
	
func ring_traversal(center: Vector2i, radius: int) -> Array:
	var result: Array = [center]
	var current: Vector2i = center + Vector2i(0, 1) * radius
	for i in Global.HEX_DIRECTIONS:
		for j in range(radius):
			result.append(current)
			current += i
	return result

func check_cell_player(coord: Vector2i, player_id: int) -> bool:
	if is_valid_coord(coord):
		return general_id_to_player_id[get_cell(coord).get_general_id()] == player_id
	else:
		printerr("坐标超界")
		return false

# 获取 general的数量（不含 0）
func get_general_count() -> int:
	var count := 0
	for key in general_id_to_player_id.keys():
		if key > 0:
			count += 1
	return count

# 获取 player 的数量（不含 0）
func get_player_count() -> int:
	var players := {}
	for general_id in general_id_to_player_id.keys():
		var player_id :int= general_id_to_player_id[general_id]
		if player_id > 0:
			players[player_id] = true
	return players.size()

# 设置一个格子的power
func set_cell_power(coord: Vector2i, new_power) -> void:
	if is_valid_coord(coord):
		get_cell(coord).set_power(new_power)
	else:
		printerr("坐标超界")
	return
	
# 设置一个格子的general
func set_cell_general_id(coord: Vector2i, new_general_id) -> void:
	if is_valid_coord(coord):
		get_cell(coord).set_general_id(new_general_id)
	else:
		printerr("坐标超界")
	return

# 判断一个格子是否属于一个玩家
func cell_belong_player(coords: Vector2i, player_id: int) -> bool:
	var cell = cell_map.get(coords)
	if cell == null:
		return false  # 坐标非法或格子不存在
	var general_id = cell.get_general_id()
	return general_id_to_player_id.get(general_id, -1) == player_id

# 判断一格子是否能被一个玩家看见
func cell_visible_for_player(coords: Vector2i, player_id: int) -> bool:
	if cell_belong_player(coords, player_id):
		return true  # 自己的地块可见
	# 检查邻接六个方向
	for dir in Global.HEX_DIRECTIONS:
		var neighbor = coords + dir
		if cell_belong_player(neighbor, player_id):
			return true  # 邻居是自己的也可见
	return false

# 判断两个格子是否相邻,返回邻接向量序号(不判断格子是否存在于map)
func get_adjacent_vector_id(pos_a: Vector2i, pos_b: Vector2i) -> int:
	for i in Global.HEX_DIRECTIONS.size():
		if pos_a + Global.HEX_DIRECTIONS[i] == pos_b:
			return i  # 返回邻接方向的索引
	return -1  # 不相邻

# state0: 排除山地
func get_neighbors_state0(center: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dir in Global.HEX_DIRECTIONS:
		var neighbor_coords: Vector2i = center + dir
		if cell_map.has(neighbor_coords):
			if get_cell(neighbor_coords).get_type() != Global.TERRAIN_MOUNTAIN:
				neighbors.append(neighbor_coords)
	return neighbors

# 字符串转化为Vector2i,同步的标准转化用
func parse_vector2i(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() == 2:
		return Vector2i(int(parts[0]), int(parts[1]))
	push_error("Invalid Vector2i string: " + key)
	return Vector2i.ZERO

# 结算地块对power的影响
func update_power_by_terrain() -> void:
	turn_count += 1
	# 结算增减
	for coords in cell_map.keys():
		var cell: CellInfo = cell_map[coords]
		var _general := cell.get_general_id()
		if _general == 0:
			continue
		var player: int = general_id_to_player_id.get(_general, 0)
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
					cell.set_general_id(0)

func build_Astar_path(start_point:Vector2i, end_point:Vector2i) -> Array:
	#构建起点-终点最短A*路径，输出 起点……终点 list
	if is_valid_coord(start_point) and is_valid_coord(end_point):
		var open_list: PriorityQueue=PriorityQueue.new()
		var close_list: Array[Vector2i] = []
		var distance: Dictionary = {}
		
		distance[start_point] = 0
		open_list.push(distance[start_point] + get_distance_2coords(start_point, end_point), start_point)
		
		while not open_list.is_empty():
			var current: Vector2i = open_list.pop()
			if current not in close_list:
				close_list.push_back(current)
				var neighbors: Array[Vector2i] = self.get_neighbors_state0(current)
				for neighbor: Vector2i in neighbors:
					if neighbor not in close_list:
						distance[neighbor] = distance[current] + 1
						open_list.push(distance[neighbor]+get_distance_2coords(neighbor, end_point), neighbor)
		return close_list
	else:
		printerr("坐标超界")
		return [-1]


func get_generals_of_player(player_id: int) -> Array[int]:
	var result: Array[int] = []
	for general_id in general_id_to_player_id.keys():
		if general_id_to_player_id[general_id] == player_id:
			result.append(general_id)
	return result
