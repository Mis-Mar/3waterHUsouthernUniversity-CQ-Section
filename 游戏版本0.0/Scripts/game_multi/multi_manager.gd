extends Node


@onready var map: Node = $"../Map"
@onready var camera_2d: Camera2D = $"../Camera2D"
@onready var timer_turn: Timer = $"../Timers/Timer_turn"

var fullmap:=FullMap.new()
var playermap:=PlayerMap.new()
# server的函数
var player_id=1
# 网络id到player_id的映射表（playerid是从1自增的）
var rpc_id_to_player_id: Dictionary = {}  
# 玩家id到网络id的映射表（player_id → peer_id）
var player_id_to_rpc_id: Dictionary = {}
# 
var is_server:=false

# 移动相关
var selected_tile_coords: Vector2i = Vector2i.ZERO  # 当前鼠标选中的格子
var current_highlighted_tile: Vector2i = Vector2i(-9999, -9999)  # 默认非法值


func start()->void:
	# 等待加载
	await get_tree().create_timer(0.1).timeout
	# 检查连接状态，并连接信号
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	else:
		print("Multiplayer 未连接")
		leave_room()
		return
	
	# 服务端初始化fullmap并发送
	if multiplayer.is_server():
		is_server=true
		# 初始化双向表
		_init_peer_player_maps()
		# 初始化fullmap
		fullmap=map.curr_map_to_fullmap()
		
		for _player_id in player_id_to_rpc_id:
			rpc_init_playermap.rpc_id(player_id_to_rpc_id[_player_id],fullmap.export_init_data_for_player(_player_id))
	
	# 双方等待初始化完成
	await get_tree().create_timer(0.5).timeout
	# 初始化完成，服务端开启计时器，游戏开始
	if multiplayer.is_server():
		timer_turn.start()
	
	# 初始化显示
	map. display_playermap_fog(playermap)
	map. display_playermap(playermap)
		
	# 显示playermap
	


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start()
	pass # Replace with function body.


# ——————————信号事件
# 帧函数
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 获取左键选中的格子
			var tile_coords = map.get_tile_coords_from_screen_pos(event.position)
			# 如果选中的格子不可见的
			if playermap.invis_state_map[tile_coords]<0:
				
				return
			# 如果两次选中同一个格子就测取消选中
			if tile_coords==selected_tile_coords:
				tile_coords= Vector2i(-9999, -9999)
				selected_tile_coords= Vector2i(-9999, -9999)
			# 新选中的格子和已经选中的格子是相邻而且可移动，就执行移动操作
			if playermap.cell_belong_player( selected_tile_coords,player_id) and playermap.get_adjacent_vector_id(selected_tile_coords,tile_coords)!=-1:
				rpc_load_action.rpc_id(1,selected_tile_coords,playermap.get_adjacent_vector_id(selected_tile_coords,tile_coords),1.0)
				#fullmap.add_general_action(selected_tile_coords,playermap.get_adjacent_vector_id(selected_tile_coords,tile_coords),1.0)
			# 更新选中格子并高亮
			if playermap.cell_visible_for_player(tile_coords,player_id):
				selected_tile_coords = tile_coords
			highlight_selected_tile(selected_tile_coords)

	elif event is InputEventKey and event.pressed:
		var cell = playermap.get_cell(selected_tile_coords)
		if cell != null:
			var general = cell.get_general_id()
			var dir_index := -1
			match event.keycode:
				KEY_Q: dir_index = Global.DIR_UP_L     # (-1, 0) 左上
				KEY_W: dir_index = Global.DIR_UP       # (-1, -1) 上
				KEY_E: dir_index = Global.DIR_UP_R     # (0, -1) 右上
				KEY_A: dir_index = Global.DIR_DOWM_L   # (0, 1) 左下
				KEY_S: dir_index = Global.DIR_DOWN     # (1, 1) 下
				KEY_D: dir_index = Global.DIR_DOWM_R   # (1, 0) 右下

			if dir_index != -1:
				var target_tile_coords=selected_tile_coords+Global.HEX_DIRECTIONS[dir_index]
				if general != 0 and playermap.general_id_to_player_id.has(general) and playermap.general_id_to_player_id[general] == player_id :
					rpc_load_action.rpc_id(1,selected_tile_coords,dir_index,1.0)
					# playermap.add_general_action(selected_tile_coords,dir_index,1.0)
				if playermap.cell_visible_for_player(target_tile_coords,player_id):
					# 若目标可见，更新选中格子的位置和高亮
					selected_tile_coords=target_tile_coords
					highlight_selected_tile(selected_tile_coords)
		else:
			printerr("操作访问到空cell")


# 玩家加入，拒绝，重连功能先不考虑
func _on_peer_connected(id: int) -> void:
	print("玩家已加入，ID: ", id)
	multiplayer.multiplayer_peer.disconnect_peer(id)

# 玩家断开，暂定
func _on_peer_disconnected(id: int) -> void:
	print("玩家离开，ID: ", id)
	if rpc_id_to_player_id.has(id):
		var pid = rpc_id_to_player_id[id]
		# 清理两张表
		rpc_id_to_player_id.erase(id)
		player_id_to_rpc_id.erase(pid)

# 回合计时器，只有服务端会调用
func _on_timer_turn_timeout() -> void:
	fullmap.execute_turn()
	# 更新playermap
	for _player_id in player_id_to_rpc_id:
		rpc_update_playermap.rpc_id(player_id_to_rpc_id[_player_id],fullmap.export_player_delta(_player_id),fullmap.export_general_id_to_player_id())
	fullmap.acted_coords.clear()
	pass # Replace with function body.

# 结束——————————



# ——————————rpc函数,双方都要有

# server/client接受到更新信号
@rpc("any_peer", "call_local")
func rpc_load_action(from_coords: Vector2i, direction_index: int, ratio: float)->void:
	fullmap.add_general_action(from_coords,direction_index,ratio)

# server/client接受到更新信号
@rpc("any_peer", "call_local")
func rpc_update_playermap(delta_cell: Dictionary,delta_general_id_to_player_id: Dictionary)->void:
	playermap.update_player_map(delta_cell, delta_general_id_to_player_id)
	map.display_playermap(playermap)
# server接受操作信号

# server/client接受初始化函数
@rpc("any_peer", "call_local")
func rpc_init_playermap(init_data: Dictionary)->void:
	player_id=init_data.get("player_id",0)
	playermap.init_from_dict(init_data)


# 结束——————————

# ——————————低级辅助函数

# 
func highlight_selected_tile(coords: Vector2i) -> void:
	if current_highlighted_tile != coords:
		map.unhighlight_cell(current_highlighted_tile)
		map.highlight_cell(coords)
		current_highlighted_tile = coords

# 初始化playerid和rpcid的双向表
func _init_peer_player_maps() -> void:
	rpc_id_to_player_id.clear()
	player_id_to_rpc_id.clear()

	var peer_ids := multiplayer.get_peers()
	peer_ids.sort()  # 保证顺序一致
	# 添加自己
	rpc_id_to_player_id[1]=1
	player_id_to_rpc_id[1]=1
	# 添加其他成员
	var pid := 2
	for peer_id in peer_ids:
		rpc_id_to_player_id[peer_id] = pid
		player_id_to_rpc_id[pid] = peer_id
		pid += 1
	print(rpc_id_to_player_id)

# 获取玩家数
func get_player_count()->int:
	return multiplayer.get_peers().size()+1

# 离开房间,切换回prepare场景
func leave_room()->void:
	reset_multiplayer()
	var err = get_tree().change_scene_to_file("res://Scenes/game_multi/prepare.tscn")
	if err != OK:
		print("切换场景失败，错误码: ", err)

# 重置连接器，出错就要调用
func reset_multiplayer()->void:
	multiplayer.multiplayer_peer = null
