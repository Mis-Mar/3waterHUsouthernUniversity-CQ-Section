# 最高层脚本，游戏测试的玩家视角（显示迷雾）
extends Node

@onready var map: Node = $"../Map"
@onready var camera_2d: Camera2D = $"../Camera2D"
@onready var timer_turn: Timer = $"../Timers/Timer_turn"

var fullmap=FullMap.new()

var player_id=1

var selected_tile_coords: Vector2i = Vector2i.ZERO  # 当前鼠标选中的格子

var current_highlighted_tile: Vector2i = Vector2i(-9999, -9999)  # 默认非法值

var playermap=PlayerMap.new()

# 启动函数
func start()->void:
	await get_tree().create_timer(0.5).timeout
	fullmap.random_init(10,3,8)
	#playermap.init_from_fullmap(fullmap,1)
	playermap.init_from_dict(fullmap.export_init_data_for_player(1))
	map.clear()
	timer_turn.start()  # 每秒自动调用 timeout 
	map. display_playermap_fog(playermap)
	map. display_playermap(playermap)
	# map. display_map_for_player(fullmap,1)
func _ready() -> void:
	start()

func highlight_selected_tile(coords: Vector2i) -> void:
	if current_highlighted_tile != coords:
		map.unhighlight_cell(current_highlighted_tile)
		map.highlight_cell(coords)
		current_highlighted_tile = coords

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 获取左键选中的格子
			var tile_coords = map.get_tile_coords_from_screen_pos(event.position)
			# 如果选中的格子不可见的
			if !fullmap.cell_visible_for_player(tile_coords,player_id):
				return
			# 如果两次选中同一个格子就测取消选中
			if tile_coords==selected_tile_coords:
				tile_coords= Vector2i(-9999, -9999)
				selected_tile_coords= Vector2i(-9999, -9999)
			# 新选中的格子和已经选中的格子是相邻而且可移动，就执行移动操作
			if fullmap.cell_belong_player( selected_tile_coords,player_id) and fullmap.get_adjacent_vector_id(selected_tile_coords,tile_coords)!=-1:
				fullmap.move_power(selected_tile_coords,fullmap.get_adjacent_vector_id(selected_tile_coords,tile_coords),1.0)
			# 更新选中格子并高亮
			if fullmap.cell_visible_for_player(tile_coords,player_id):
				selected_tile_coords = tile_coords
			highlight_selected_tile(selected_tile_coords)

	elif event is InputEventKey and event.pressed:
		var cell = fullmap.get_cell(selected_tile_coords)
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
				if general != 0 and fullmap.general_id_to_player_id.has(general) and fullmap.general_id_to_player_id[general] == player_id :
					fullmap.move_power(selected_tile_coords,dir_index,1.0)
				if fullmap.cell_visible_for_player(target_tile_coords,player_id):
					# 若目标可见，更新选中格子的位置和高亮
					selected_tile_coords=target_tile_coords
					highlight_selected_tile(selected_tile_coords)
		else:
			printerr("操作访问到空cell")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_timer_turn_timeout() -> void:
	
	fullmap.execute_turn()
	
	playermap.update_player_map(fullmap.export_player_delta(1), fullmap.export_general_id_to_player_id())
	
	fullmap.acted_coords.clear()
	
	
	map.display_playermap(playermap)
	# map. display_map_for_player(fullmap, player_id)  # 重新显示新状态
	pass 
