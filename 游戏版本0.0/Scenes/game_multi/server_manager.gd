# servermanager.gd
extends Node

@onready var map: Node = $"../Map"
@onready var camera_2d: Camera2D = $"../Camera2D"
@onready var timer_turn: Timer = $"../Timers/Timer_turn"

var fullmap:FullMap
# server的函数
var player_id=1
# 网络id到player_id的映射表（playerid是从1自增的）
var rpc_id_to_player_id: Dictionary = {}  

# 初始化
func start()->void:
	# 等待加载
	await get_tree().create_timer(0.2).timeout
	# 检查连接状态，并连接信号
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	else:
		print("Multiplayer 未连接")
		leave_room()
		return
	
	#初始化网络id到player_id的映射表
	rpc_id_to_player_id.clear()
	var peer_ids := multiplayer.get_peers()
	peer_ids.sort()  # 保证一致顺序
	var _player_id := 1
	for peer_id in peer_ids:
		rpc_id_to_player_id[peer_id] = player_id
		_player_id += 1
	
	# 初始化fullmap
	fullmap=map.curr_map_to_fullmap()
	

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
# 结束——————————



# ——————————rpc函数
# server发送初始化信息
# @rpc("authority", "call_local")


# server发送更新信息
# @rpc("authority", "call_local")

# server接受操作信号

# 结束——————————

# ——————————低级辅助函数
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
