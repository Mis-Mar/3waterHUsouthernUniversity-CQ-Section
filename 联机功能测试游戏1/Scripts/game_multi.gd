extends Node2D
@onready var players: Node = $players
# 导入player，要用
const PLAYER = preload("res://Scenes/player.tscn")

@onready var ip_panel: Panel = $UI/ip_panel
@onready var ip_input: LineEdit = $UI/ip_panel/ip_input
@onready var confirm_button: Button = $UI/ip_panel/confirm_button
@onready var back_button: Button = $UI/ip_panel/back_button
@onready var connect_timeout_timer: Timer = $UI/ip_panel/connect_timeout_timer

@onready var info_bar: RichTextLabel = $UI/info_bar
@onready var info_input: LineEdit = $UI/info_input
@onready var info_send_button: Button = $UI/info_send_button


# 初始化连接句柄
var peer=ENetMultiplayerPeer.new()

@rpc("call_remote")  # 所有端都调用本地的 log() 来显示日志
func sync_log(msg: String, is_error: bool = false) -> void:
	_log_internal(msg, is_error)
	
@rpc("call_remote")
func sync_log_remote(msg: String, is_error: bool) -> void:
	sync_log(msg, is_error)	

@rpc("any_peer")  # 客户端向服务端申请服务器上的方法来广播
func request_log_broadcast(msg: String, is_error: bool) -> void:
	sync_log(msg, is_error)  # 服务端本地显示
	sync_log_remote.rpc_id(0, msg, is_error)  # 广播给其他客户端

# 日志函数封装
func _log(msg: String, is_error: bool = false) -> void:
	# 网络同步
	if multiplayer.multiplayer_peer:
		if multiplayer.is_server():
			_log_internal(msg, is_error)
			# 服务端自己广播
			sync_log.rpc(msg, is_error)
		else:
			# 客户端向服务端请求广播（服务器ID通常为1）
			print("客户请求广播调用")
			request_log_broadcast.rpc_id(1, msg, is_error)  # ✅ 客户端 → 服务端
		
func _log_internal(msg: String, is_error: bool = false) -> void:
	var time = Time.get_time_string_from_system()
	var formatted = "[%s] %s" % [time, msg]
	if is_error:
		info_bar.append_text("[color=red]" + formatted + "[/color]\n")
	else:
		info_bar.append_text(formatted + "\n")
	info_bar.scroll_to_line(info_bar.get_line_count() - 1)


	

# 添加玩家的函数封装
func add_player(id: int)->void:
	var player=PLAYER.instantiate()
	player.name=str(id)
	players.add_child(player)

# 创建服务器
func _on_create_button_down() -> void:
	# 创建服务端
	var error = peer.create_server(7788)
	if error != OK:
		printerr("服务器创建失败，错误码",error)
		_log("服务器创建失败，错误码",error)
		return
	print("服务建立成功")
	_log("服务建立成功")
	# 将句柄作为连接的基础
	multiplayer.multiplayer_peer=peer
	# 建立连接的行为，接受一个函数，传给这个函数一个参数int，是连接者的id
	multiplayer.peer_connected.connect(_on_peer_connected)
	# 创建服务端玩家,multiplayer.get_unique_id()用于获取当前服务端的唯一标识，服务端默认为1，客户端随机
	add_player(multiplayer.get_unique_id())
	

# 服务器和客户建立连接的行为
func _on_peer_connected(id: int)->void:
	print("用户建立连接：id：", id)
	_log("用户建立连接")
	add_player(id)
	pass

# 客户准备建立连接
func _on_join_button_down() -> void:
	ip_panel.visible = true  # 显示 IP 输入界面

# 客户端退回
func _on_back_button_button_down() -> void:
	ip_panel.visible = false
	ip_input.text="127.0.0.1"
	pass # Replace with function body.

# 客户端正式建立连接
func _on_confirm_button_button_down() -> void:
	var ip_address = ip_input.text.strip_edges()
	if ip_address == "":
		printerr("IP地址怎么是空的")
		_log("IP地址怎么是空的")
		return

	var error = peer.create_client(ip_address, 7788)
	if error != OK:
		printerr("连接服务器失败，错误码", error)
		_log("连接服务器失败",true)
		return
	multiplayer.multiplayer_peer = peer
	
	#有问题 multiplayer.connected_to_server.connect(_on_connected_to_server)
	# multiplayer.connection_failed.connect(_on_connection_failed)
	connect_timeout_timer.start()  # 启动定时器
	ip_panel.visible = false  # 隐藏输入界面	

func _on_connect_timeout_timer_timeout() -> void:
	connect_timeout_timer.stop()  # 🛑 停止定时器，防止重复触发

	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		printerr("❌ 连接超时，服务器不存在或未响应")
		_log("❌ 连接超时，服务器不存在或未响应",true)

		# ❌ 清除 multiplayer 状态，便于下次连接
		multiplayer.multiplayer_peer = null
		peer = ENetMultiplayerPeer.new()  # 🔄 重建 ENet peer

		# 恢复 UI
		ip_panel.visible = true
	else:
		print("✅ 连接成功")
		_log("✅ 连接成功")
		# add_player(multiplayer.get_unique_id())


func _on_info_send_button_button_down() -> void:
	var content = info_input.text.strip_edges()
	if content == "":
		_log("你不能发送空日志", true)
		return
	info_input.clear()
	_log("[玩家%s] %s" % [multiplayer.get_unique_id(), content])
	pass # Replace with function body.
