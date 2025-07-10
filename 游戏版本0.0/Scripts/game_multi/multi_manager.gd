extends Node


@onready var map: Node = $"../Map"
@onready var camera_2d: Camera2D = $"../Camera2D"
@onready var timer_turn: Timer = $"../Timers/Timer_turn"
@onready var move_manager: Node = $"../MoveManager"
@onready var turn_count_label: Label = $"../UI/turn_count_label"
@onready var loading_item: Node2D = $"../UI/loading_item"
@onready var background: Node2D = $"../Camera2D/background"


var fullmap:=FullMap.new()
var playermap:=PlayerMap.new()
# server的函数
var player_id=2
# 网络id到player_id的映射表（playerid是从1自增的）
var rpc_id_to_player_id: Dictionary = {}  
# 玩家id到网络id的映射表（player_id → peer_id）
var player_id_to_rpc_id: Dictionary = {}
# 
var is_server:=false
# 移动相关
#var selected_tile_coords: Vector2i = Vector2i.ZERO  # 当前鼠标选中的格子
#var current_highlighted_tile: Vector2i = Vector2i(-9999, -9999)  # 默认非法值


func start()->void:
	# 等待加载
	await get_tree().create_timer(1).timeout
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
		# 服务端要初始化fullmap，后续转化发送给客户端
		replace_main_layer_with_map(Global.game_map_id)
		# 初始化双向表
		_init_peer_player_maps()
		# 初始化fullmap
		fullmap=map.curr_map_to_fullmap()
		for _player_id in player_id_to_rpc_id:
			rpc_init_playermap.rpc_id(player_id_to_rpc_id[_player_id],fullmap.export_init_data_for_player(_player_id))
	
	# 连接信号
	player_id=playermap.player_id
	playermap.game_lose.connect(_on_game_lose)
	playermap.game_win.connect(_on_game_win)
	# 双方等待初始化完成
	await get_tree().create_timer(2).timeout
	
	# 激活移动脚本
	move_manager.load_action.connect(upload_action)
	move_manager.activate(playermap)
	# 初始化完成，服务端开启计时器，游戏开始
	if multiplayer.is_server():
		timer_turn.start()
	
	# 初始化显示
	map. display_playermap_fog(playermap)
	map. display_playermap(playermap)
	display_turn_count(playermap.turn_count)
	center_camera_on_capital(playermap, map.main_layer, camera_2d)
	turn_count_label.visible=true
	loading_item.visible=false
	map.visible=true
	background.visible=true
		
	# 显示playermap

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start()
	pass # Replace with function body.

# ——————————信号事件
# 帧函数
func _process(delta: float) -> void:
	pass


# 玩家加入，拒绝，重连功能先不考虑
func _on_peer_connected(id: int) -> void:
	print("玩家已加入，ID: ", id)
	multiplayer.multiplayer_peer.disconnect_peer(id)

# 玩家断开，暂定
func _on_peer_disconnected(id: int) -> void:
	print("玩家离开，ID: ", id)
	if is_server and rpc_id_to_player_id.has(id):
		var pid = rpc_id_to_player_id[id]
		# 清理两张表
		rpc_id_to_player_id.erase(id)
		player_id_to_rpc_id.erase(pid)
	# 客户端返回界面
	elif !is_server and id==1:
		leave_room()

# 回合计时器，只有服务端会调用
func _on_timer_turn_timeout() -> void:
	fullmap.execute_turn()
	# 更新playermap
	for _player_id in player_id_to_rpc_id:
		rpc_update_playermap.rpc_id(player_id_to_rpc_id[_player_id],fullmap.export_player_delta(_player_id),fullmap.export_general_id_to_player_id())
	fullmap.acted_coords.clear()
	pass # Replace with function body.
# 玩家胜利
func _on_game_lose() -> void:
	if !is_server:
		get_tree().change_scene_to_file("res://Scenes/game_multi/lose.tscn")
		pass
# 玩家失败
func _on_game_win() -> void:
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scenes/game_multi/win.tscn")
	pass
# 结束——————————



# ——————————rpc函数,双方都要有
func upload_action(from_coords: Vector2i, direction_index: int, ratio: float)->void:
	rpc_load_action.rpc_id(1,from_coords , direction_index , ratio )

# server/client接受到更新信号
@rpc("any_peer", "call_local")
func rpc_load_action(from_coords: Vector2i, direction_index: int, ratio: float)->void:
	fullmap.add_general_action(from_coords,direction_index,ratio)

# server/client接受到更新信号
@rpc("any_peer", "call_local")
func rpc_update_playermap(delta_cell: Dictionary,delta_general_id_to_player_id: Dictionary)->void:
	playermap.update_player_map(delta_cell, delta_general_id_to_player_id)
	map.display_playermap(playermap)
	display_turn_count(playermap.turn_count)
# server接受操作信号

# server/client接受初始化函数
@rpc("any_peer", "call_local")
func rpc_init_playermap(init_data: Dictionary)->void:
	player_id=init_data.get("player_id",0)
	playermap.init_from_dict(init_data)

# 结束——————————

# ——————————低级辅助函数
# 按要求替换函数
func replace_main_layer_with_map(map_id: int) -> void:
	var path := "res://Scenes/game_maps/game_map_%d.tscn" % map_id
	var tile_scene = load(path)
	if not tile_scene:
		push_error("地图载入失败：%s" % path)
		return

	var new_main_layer = tile_scene.instantiate()
	new_main_layer.name = "MainLayer"

	var old_main_layer = map.get_node_or_null("MainLayer")
	if old_main_layer:
		old_main_layer.queue_free()

	map.add_child(new_main_layer)
	map.move_child(new_main_layer, 0)  # 保证它在最前面
	map.main_layer = new_main_layer  # 如果 main_layer 是变量（不是 onready）

# 开局时的摄像头居中首都
func center_camera_on_capital(playermap: PlayerMap, main_layer: TileMapLayer, camera_2d: Camera2D) -> void:
	if not playermap.general_to_capital.has(playermap.player_id):
		push_warning("未找到玩家的首都坐标")
		return

	var capital_tile_coords: Vector2i = playermap.general_to_capital[playermap.player_id]
	var capital_world_pos: Vector2 = main_layer.map_to_local(capital_tile_coords)
	camera_2d.global_position = capital_world_pos
# 显示回合数
func display_turn_count(turn_count: int) -> void:
	var text := "Turn %d" % int(turn_count / 2)
	if turn_count % 2 != 0:
		text += "."
	turn_count_label.text = text

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
