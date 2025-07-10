# 最高层脚本，游戏测试的玩家视角（显示迷雾）
extends Node

@onready var map: Node = $"../Map"
@onready var camera_2d: Camera2D = $"../Camera2D"
@onready var timer_turn: Timer = $"../Timers/Timer_turn"

var fullmap=FullMap.new()

var player_id=2

var selected_tile_coords: Vector2i = Vector2i.ZERO  # 当前鼠标选中的格子

var current_highlighted_tile: Vector2i = Vector2i(-9999, -9999)  # 默认非法值

var playermap=PlayerMap.new()

# 在适当的地方加这个，比如 _ready 或 start 末尾等
func replace_main_layer_with_scene():
	var tile_scene = preload("res://Scenes/game_maps/game_map_3.tscn")
	var new_layer_instance = tile_scene.instantiate()

	# 删除旧的 main_layer，如果存在
	var old_main_layer = map.get_node_or_null("MainLayer")
	if old_main_layer:
		old_main_layer.queue_free()

	# 添加新的 layer
	map.add_child(new_layer_instance)
	new_layer_instance.name = "MainLayer"
	map.main_layer = new_layer_instance


# 启动函数
func start()->void:
	await get_tree().create_timer(0.1).timeout
	await replace_main_layer_with_scene()
	# fullmap.random_init(10,3,8)
	fullmap=map.curr_map_to_fullmap()
	#playermap.init_from_fullmap(fullmap,1)
	playermap.init_from_dict(fullmap.export_init_data_for_player(player_id))
	map.clear()
	timer_turn.start()  # 每秒自动调用 timeout 
	map. display_playermap_fog(playermap)
	map. display_playermap(playermap)
	# 这样可以绑定信号
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
			if !playermap.invis_state_map.has(tile_coords) or playermap.invis_state_map[tile_coords]<0:
				
				return
			# 如果两次选中同一个格子就测取消选中
			if tile_coords==selected_tile_coords:
				tile_coords= Vector2i(-9999, -9999)
				selected_tile_coords= Vector2i(-9999, -9999)
			# 新选中的格子和已经选中的格子是相邻而且可移动，就执行移动操作
			if playermap.cell_belong_player( selected_tile_coords,player_id) and playermap.get_adjacent_vector_id(selected_tile_coords,tile_coords)!=-1:
				
				fullmap.add_general_action(selected_tile_coords,playermap.get_adjacent_vector_id(selected_tile_coords,tile_coords),1.0)
			# 更新选中格子并高亮
			if playermap.cell_visible_for_player(tile_coords,player_id):
				selected_tile_coords = tile_coords
			highlight_selected_tile(selected_tile_coords)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_timer_turn_timeout() -> void:
	
	fullmap.execute_turn()
	
	playermap.update_player_map(fullmap.export_player_delta(player_id), fullmap.export_general_id_to_player_id())
	
	fullmap.acted_coords.clear()
	
	
	map.display_playermap(playermap)
	# map. display_map_for_player(fullmap, player_id)  # 重新显示新状态
	pass 
