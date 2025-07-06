# game_multi_room.gd
extends Node2D

@onready var leave_button: Button = $UI/leave_button
@onready var label_player_info: Label = $UI/label_player_info
@onready var ready_button: Button = $UI/ready_button
@onready var label_ready_info: Label = $"UI/label-ready-info"
@onready var start_button: Button = $"UI/start-button"

var role:String
var is_ready := false
var is_server:= false
var ready_count:=0
# 房主记录玩家准备状态
var player_ready: Dictionary = {} # int bool 玩家id到玩家是否准备的映射表

func _ready():
	# 检查连接状态，并连接信号
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	else:
		print("Multiplayer 未连接")
		leave_room()
		return
	
	# 判断是房主还是成员
	if multiplayer.is_server():
		role="房主"
		is_server=true
		# 表中加入自己
		player_ready[1]=false
	else:
		role="成员"
		multiplayer.server_disconnected.connect(_on_server_disconnected)

	# 初始化显示
	update_room_status()
	display_ready_info()

# ——————————信号事件
# 玩家加入
func _on_peer_connected(id: int) -> void:
	print("玩家已加入，ID: ", id)
	# 等一下，防止玩家场景还没加载
	await get_tree().create_timer(0.5).timeout
	update_room_status()
	if is_server:
		player_ready[id]=false
		update_ready_count.rpc(compute_ready_count_only_server())
# 玩家断开
func _on_peer_disconnected(id: int) -> void:
	print("玩家离开，ID: ", id)
	update_room_status()
	if is_server:
		player_ready.erase(id)
		update_ready_count.rpc(compute_ready_count_only_server())

# 玩家自己与服务器断开连接
func _on_server_disconnected()->void:
	print("与服务器断开连接")
	leave_room()



# 按下离开房间按钮
func _on_leave_button_pressed() -> void:
	leave_room()

# 按下准备按钮
func _on_ready_button_pressed() -> void:
	is_ready=!is_ready
	send_ready.rpc_id(1,is_ready)
	pass # Replace with function body.
# 按下开始按钮
func _on_startbutton_pressed() -> void:
	send_start.rpc()
	pass # Replace with function body.
# 结束——————————

# ——————————rpc远程函数
# 测试用，调用rpc
func _on_some_input(): # Connected to some input.
	var test_info:String=""
	for i in range(10000):
		test_info+="00000"
	transfer_some_input.rpc_id(1,test_info) # Send the input only to the server.

# 测试用，服务器接收到ready
@rpc("any_peer", "call_local")
func transfer_some_input( info:String):
	# The server knows who sent the input.
	var sender_id = multiplayer.get_remote_sender_id()
	print("收到信号来自",sender_id,",长度:",info.length())
	# Process the input and affect game logic.

# client/server 向server发送准备信息的函数，server收到后开始更新表
@rpc("any_peer", "call_local")
func send_ready(_is_player_ready:bool)->void:
	var sender_id = multiplayer.get_remote_sender_id()
	player_ready[sender_id]=_is_player_ready
	update_ready_count.rpc(compute_ready_count_only_server())
	pass

# server向 client/server 发送更新ready_info的信号
@rpc("authority", "call_local")
func update_ready_count(_ready_count:int)->void:
	ready_count=_ready_count
	display_ready_info()
	show_or_hide_start_button()
	pass

# server向 client/server 发送开始游戏的信号
@rpc("authority", "call_local")
func send_start()->void:
	print("start")
	var err = get_tree().change_scene_to_file("res://Scenes/game_multi/game_multi_play.tscn")
	if err != OK:
		print("切换场景失败，错误码: ", err)

# 结束——————————

# ——————————底层的简化封装
func update_room_status() -> void:
	var player_ids = multiplayer.get_peers()
	player_ids.insert(0, multiplayer.get_unique_id())  # 加上自己
	var count = player_ids.size()
	label_player_info.text = "身份：%s\n当前房间人数：%d" % [role, count]

func update_ready_button()->void:
	if is_ready:
		ready_button.text="取消准备"
	else:
		ready_button.text="准备"

func display_ready_info()->void:
	update_ready_button()
	label_ready_info.text="%d / %d"%[ready_count,get_player_count()]
	pass

func show_or_hide_start_button()->void:
	if is_server:
		if check_can_start():
			start_button.visible=true
			return
	start_button.visible=false

func check_can_start()->bool:
	var _player_count:int=get_player_count()
	var _ready_count :int=compute_ready_count_only_server()
	return _player_count>1 and _player_count==_ready_count

func compute_ready_count_only_server()->int:
	var result=0
	for key in player_ready:
		var _is_ready = player_ready[key]
		if _is_ready:
			result+=1
	return result

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
