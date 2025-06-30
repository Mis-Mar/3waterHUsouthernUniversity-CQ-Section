# 最高层脚本，游戏测试的玩家视角（显示迷雾）
extends Node

@onready var map: Node = $"../Map"
@onready var main_layer: TileMapLayer = $"../Map/MainLayer"
@onready var color_layer: TileMapLayer = $"../Map/ColorLayer"
@onready var number_labels: Control = $"../Map/NumberLabels"

@onready var camera_2d: Camera2D = $"../Camera2D"

@onready var timer_turn: Timer = $"../Timers/Timer_turn"

var fullmap=FullMap.new()

var player_id=1

func start()->void:
	await get_tree().create_timer(0.5).timeout
	fullmap.random_init(200,3,8)
	main_layer.clear()
	color_layer.clear()
	timer_turn.start()  # 每秒自动调用 timeout
	map. display_full_map_fog(fullmap)
	map. display_map_for_player(fullmap,1)

func _ready() -> void:
	start()

var selected_tile_coords: Vector2i = Vector2i.ZERO  # 当前鼠标选中的格子

var current_highlighted_tile: Vector2i = Vector2i(-9999, -9999)  # 默认非法值

func highlight_selected_tile(coords: Vector2i) -> void:
	if current_highlighted_tile != coords:
		map.unhighlight_cell(current_highlighted_tile)
		map.highlight_cell(coords)
		current_highlighted_tile = coords

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var screen_pos = event.position
			var world_pos = main_layer.get_viewport_transform().affine_inverse() * screen_pos
			var local_pos = main_layer.to_local(world_pos)
			var tile_coords = main_layer.local_to_map(local_pos)

			# 更新选中格子并高亮
			selected_tile_coords = tile_coords
			highlight_selected_tile(tile_coords)

	elif event is InputEventKey and event.pressed:
		var cell = fullmap.get_cell(selected_tile_coords)
		if cell != null:
			var owner = cell.get_owner()
			if owner != 0 and fullmap.owner_to_player.has(owner) and fullmap.owner_to_player[owner] == player_id:
				var dir_index := -1
				match event.keycode:
					KEY_Q: dir_index = Global.DIR_UP_L     # (-1, 0) 左上
					KEY_W: dir_index = Global.DIR_UP       # (-1, -1) 上
					KEY_E: dir_index = Global.DIR_UP_R     # (0, -1) 右上
					KEY_A: dir_index = Global.DIR_DOWM_L   # (0, 1) 左下
					KEY_S: dir_index = Global.DIR_DOWN     # (1, 1) 下
					KEY_D: dir_index = Global.DIR_DOWM_R   # (1, 0) 右下

				if dir_index != -1:
					var success = fullmap.queue_action(selected_tile_coords, dir_index, 1.0)
					if success:
						# 若移动成功，更新选中格子的位置和高亮
						var dir = Global.HEX_DIRECTIONS[dir_index]
						selected_tile_coords += dir
						highlight_selected_tile(selected_tile_coords)
		else:
			printerr("操作访问到空cell")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_timer_turn_timeout() -> void:
	await fullmap.execute_turn()
	map. display_map_for_player(fullmap, player_id)  # 重新显示新状态
	pass 
