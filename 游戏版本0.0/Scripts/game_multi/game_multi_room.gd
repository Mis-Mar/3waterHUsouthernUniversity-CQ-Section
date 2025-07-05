# game_multi_room.gd
extends Node2D

@onready var leave_button: Button = $UI/leave_button
@onready var label_player_info: Label = $UI/label_player_info

var role:String
var is_ready := false

func _ready():
	if multiplayer.multiplayer_peer == null:
		print("Multiplayer 未初始化，返回主界面")
		get_tree().change_scene_to_file("res://Scenes/game_multi_prepare.tscn")
		return

	# 连接信号
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		print("房间界面 设置成功")
	else:
		print("错误：Multiplayer 未连接")
		leave_room()
		return
	
	# 判断是房主还是成员
	if multiplayer.is_server():
		role="房主"
	else:
		role="成员"
		multiplayer.server_disconnected.connect(_on_server_disconnected)

	# 初始化显示
	update_room_status()

func _on_peer_connected(id: int) -> void:
	print("玩家已加入，ID: ", id)
	update_room_status()

func _on_peer_disconnected(id: int) -> void:
	print("玩家离开，ID: ", id)
	update_room_status()

func update_room_status() -> void:
	var player_ids = multiplayer.get_peers()
	player_ids.insert(0, multiplayer.get_unique_id())  # 加上自己
	var count = player_ids.size()

	label_player_info.text = "身份：%s\n当前房间人数：%d" % [role, count]

# 按下离开房间按钮
func _on_leave_button_pressed() -> void:
	leave_room()

# 与服务器断开连接
func _on_server_disconnected()->void:
	print("与服务器断开连接")
	leave_room()

# 离开房间,切换回prepare场景
func leave_room()->void:
	reset_multiplayer()
	var err = get_tree().change_scene_to_file("res://Scenes/game_muti_prepare.tscn")
	if err != OK:
		print("切换场景失败，错误码: ", err)

# 重置连接器，出错就要调用
func reset_multiplayer()->void:
	multiplayer.multiplayer_peer = null
	
