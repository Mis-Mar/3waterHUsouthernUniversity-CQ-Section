extends Node

@onready var map: Control = $"../Map"


var enable=false

var playermap=PlayerMap.new()
var player_id=0
# 移动相关
var selected_tile_coords: Vector2i = Vector2i.ZERO  # 当前鼠标选中的格子
var current_highlighted_tile: Vector2i = Vector2i(-9999, -9999)  # 默认非法值
var action_queue: Array = []  # 每项结构为 {from: Vector2i, dir: int, ratio: float}
signal load_action(from_coords: Vector2i, direction_index: int, ratio: float)

func activate(_playermap:PlayerMap) -> void:
	enable=true
	playermap=_playermap
	player_id=_playermap.player_id
	print("移动初始化",player_id)
	playermap.turn_updated.connect(_on_turn_updated)
	pass


	

func _on_turn_updated(curr_turn_count:int)->void:
	map.clear_all_arrows()
	map.draw_arrow_batch_from_actions(action_queue)
	while action_queue.size() > 0:
		var action = action_queue[0]
		var from_coords = action["from"]
		var dir = action["dir"]
		var target_coords=from_coords+Global.HEX_DIRECTIONS[dir]
		var ratio = action["ratio"]
		var _cell_info = playermap.get_cell(from_coords)
		# 己方cell而且目标不是山地
		if _cell_info!=null and playermap.get_cell_player(_cell_info)== player_id and playermap.invis_state_map[target_coords]!=Global.TERRAIN_MOUNTAIN:
			emit_signal("load_action", from_coords, dir, ratio)
			action_queue.pop_front()
			break  # 只执行一个合法操作
		else:
			action_queue.pop_front()  # 非法起点，丢弃
		

# 输入与操作
func _input(event: InputEvent) -> void:
	if !enable:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 获取左键选中的格子
			var tile_coords = map.get_tile_coords_from_screen_pos(event.position)
			# 如果选中的格子超界
			if !playermap.invis_state_map.has(tile_coords): #or playermap.invis_state_map[tile_coords]<0
				return
			# 如果两次选中同一个格子就测取消选中
			if tile_coords==selected_tile_coords:
				tile_coords= Vector2i(-9999, -9999)
				selected_tile_coords= Vector2i(-9999, -9999)
			# 新选中的格子和已经选中的格子是相邻
			if playermap.get_adjacent_vector_id(selected_tile_coords,tile_coords)!=-1:
				action_queue.append({
					"from": selected_tile_coords,
					"dir": playermap.get_adjacent_vector_id(selected_tile_coords,tile_coords),
					"ratio": 1.0
				})
				
			# 更新选中格子并高亮
			selected_tile_coords = tile_coords
			highlight_selected_tile(selected_tile_coords)

	elif event is InputEventKey and event.pressed:
		var dir_index := -1
		match event.keycode:
			KEY_Q: dir_index = Global.DIR_UP_L     # (-1, 0) 左上
			KEY_W: dir_index = Global.DIR_UP       # (-1, -1) 上
			KEY_E: dir_index = Global.DIR_UP_R     # (0, -1) 右上
			KEY_A: dir_index = Global.DIR_DOWM_L   # (0, 1) 左下
			KEY_S: dir_index = Global.DIR_DOWN     # (1, 1) 下
			KEY_D: dir_index = Global.DIR_DOWM_R   # (1, 0) 右下
			# R取消当前行动队列
			KEY_R: action_queue.clear()
		if dir_index != -1:
			var target_tile_coords=selected_tile_coords+Global.HEX_DIRECTIONS[dir_index]
			if playermap.invis_state_map.has(target_tile_coords):
				action_queue.append({
					"from": selected_tile_coords,
					"dir": dir_index,
					"ratio": 1.0
				})
			if playermap.invis_state_map.has(target_tile_coords):
				selected_tile_coords=target_tile_coords
				highlight_selected_tile(selected_tile_coords)

func highlight_selected_tile(coords: Vector2i) -> void:
	if current_highlighted_tile != coords:
		map.unhighlight_cell(current_highlighted_tile)
		map.highlight_cell(coords)
		current_highlighted_tile = coords
