# 最高层脚本，上帝视角（无迷雾，拥有所有player权限）
extends Node

@onready var map: Node = $"../Map"
@onready var camera_2d: Camera2D = $"../Camera2D"
@onready var timer_turn: Timer = $"../Timers/Timer_turn"
@onready var auto_turn_button: Button = $"../UI/AutoTurnButton"


var fullmap=FullMap.new()
var playermap=PlayerMap.new()
var is_auto_turn := false  # 默认是手动回合

func test_a()->void:
	# 设置cell信息
	fullmap.set_cell_power(Vector2i(-2,3) ,10)
	fullmap.set_cell_general_id(Vector2i(-2,3),1)
	
	fullmap.set_cell_power(Vector2i(-3,2) ,10)
	fullmap.set_cell_general_id(Vector2i(-3,2),1)
	
	fullmap.set_cell_power(Vector2i(-4,1) ,10)
	fullmap.set_cell_general_id(Vector2i(-4,1),1)
	
	fullmap.set_cell_power(Vector2i(-5,0) ,10)
	fullmap.set_cell_general_id(Vector2i(-5,0),1)
	
	fullmap.update_general_index()
	fullmap.compute_player_deltas()

	playermap.update_cell_from_delta(fullmap.export_player_delta(1))
	
	map.display_full_map(fullmap)
	
	var almap=AlgorithmMap. new(playermap,0)
	#TODO 补写generalid指定
	var m2s=M2S_SearchAlgorithm. new(almap)
	var pt:Array = m2s.M2S_Search(Vector2i(-2,4),30,3,1,0,50)
	print(pt)
	var ans:Array[Vector2i]=m2s.get_path_coords() 
	print(ans)
	for coord in ans:
		map.highlight_cell(coord)
		
	#for coord in m2s.final_influence_map.keys():
	#	map.set_label(coord,str(m2s.final_influence_map[coord]))
	

# 开场的函数
func start()->void:
	await get_tree().create_timer(0.1).timeout
	fullmap=map.curr_map_to_fullmap()
	fullmap.update_general_index()
	print(fullmap.export_init_data_for_player(1))
	playermap.init_from_dict(fullmap.export_init_data_for_player(1))
	map.clear()
	timer_turn.start()  # 每秒自动调用 timeout
	map.display_full_map(fullmap)
	
	test_a()
	
	

func _ready() -> void:
	start()
	pass

var selected_tile_coords: Vector2i = Vector2i.ZERO  # 当前鼠标选中的格子

func _unhandled_input(event: InputEvent) -> void:
	# 鼠标左键选中
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 获取左键选中的格子
			var tile_coords = map.get_tile_coords_from_screen_pos(event.position)
			selected_tile_coords = tile_coords
			map. print_cell(tile_coords)
	# 移动选择
	elif event is InputEventKey and event.pressed:
		var dir_index := -1
		match event.keycode:
			KEY_Q: dir_index = Global.DIR_UP_L     # (-1, 0) 左上
			KEY_W: dir_index = Global.DIR_UP       # (-1, -1) 上
			KEY_E: dir_index = Global.DIR_UP_R     # (0, -1) 右上
			KEY_A: dir_index = Global.DIR_DOWM_L   # (0, 1) 左下
			KEY_S: dir_index = Global.DIR_DOWN     # (1, 1) 下
			KEY_D: dir_index = Global.DIR_DOWM_R   # (1, 0) 右下
		if dir_index != -1:
			# fullmap.move_power(selected_tile_coords, dir_index, 1.0)
			fullmap.queue_action(selected_tile_coords, dir_index, 1.0)
	# 空格手动跳回合
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE and not is_auto_turn:
			fullmap.execute_turn()
			map.display_full_map(fullmap)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_turn_timeout() -> void:
	if is_auto_turn:
		# 结算回合
		fullmap.execute_turn()
		# 地图刷新
		map. display_full_map(fullmap)  # 重新显示新状态
	pass 



func _on_auto_turn_button_pressed() -> void:
	is_auto_turn =! is_auto_turn
	if is_auto_turn:
		auto_turn_button.text = "自动"
		timer_turn.start()  # 启动自动回合
	else:
		auto_turn_button.text = "手动(空格)"
		timer_turn.stop()  # 停止自动回合
	pass # Replace with function body.
