# game_multi_prepare.gd
extends Node2D

@onready var create_button: Button = $UI/create_button
@onready var join_button: Button = $UI/join_button
@onready var ip_line_edit: LineEdit = $UI/ip_line_edit
@onready var connect_timeout_timer: Timer = $UI/connect_timeout_timer

var peer=ENetMultiplayerPeer.new()
var port:=11451

# 创建房间
func _on_create_button_pressed() -> void:
	# 创建服务器
	peer= ENetMultiplayerPeer.new()
	var error := peer.create_server(port,Global.MAX_CLIENTS)
	if error != OK:
		printerr("服务器创建失败: ", error)
		reset_multiplayer()
		return
	multiplayer.multiplayer_peer = peer
	print("服务器创建成功")
	# 切换到房间界面
	get_tree().change_scene_to_file("res://Scenes/game_multi/room.tscn")

# 加入房间
func _on_join_button_pressed() -> void:
	var ip :String= ip_line_edit.text.strip_edges()
	if ip == "":
		print("请输入 IP 地址")
		return
	peer= ENetMultiplayerPeer.new()
	var error := peer.create_client(ip, port)
	if error:
		print("连接失败，错误码: ", error)
		reset_multiplayer()
		return
	multiplayer.multiplayer_peer = peer
	print("正在连接到房主: ", ip)
	
	# 等一小段时间，监听服务器连接是否成功
	connect_timeout_timer.start()

# 这个判断不好用，我用计时器代替了
#func _on_connected_to_server()->void:
	#print("连接成功")
	#pass
#func _on_connection_failed()->void:
	#print("连接失败")
	#reset_multiplayer()
	#pass

# 判断加入房间是否成功的计时器
func _on_connect_timeout_timer_timeout() -> void:
	connect_timeout_timer.stop()
	# 连接有问题
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		printerr("连接超时，服务器不存在或未响应")
		# 重置连接以准备下次连接
		reset_multiplayer()
	# 连接成功
	else:
		print("连接成功")
		# 切换到房间界面
		get_tree().change_scene_to_file("res://Scenes/game_multi/room.tscn")
	pass # Replace with function body.

# 重置连接器，出错就要调用
func reset_multiplayer()->void:
	multiplayer.multiplayer_peer = null
	peer = ENetMultiplayerPeer.new()
