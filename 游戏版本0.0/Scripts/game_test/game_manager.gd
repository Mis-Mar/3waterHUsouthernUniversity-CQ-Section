extends Node

@onready var map: Node = $"../Map"
@onready var main_layer: TileMapLayer = $"../Map/MainLayer"
@onready var color_layer: TileMapLayer = $"../Map/ColorLayer"
@onready var number_labels: Control = $"../Map/NumberLabels"

@onready var camera_2d: Camera2D = $"../Camera2D"

@onready var timer_turn: Timer = $"../Timers/Timer_turn"

var fullmap=FullMap.new()

func _ready() -> void:
	fullmap.random_init(10,3,8)
	main_layer.clear()
	color_layer.clear()
	timer_turn.start()  # 每秒自动调用 timeout
	map. display_map_for_player(fullmap,1)

var selected_tile_coords: Vector2i = Vector2i.ZERO  # 当前鼠标选中的格子

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var screen_pos = event.position
			var world_pos = main_layer.get_viewport_transform().affine_inverse() * screen_pos
			var local_pos = main_layer.to_local(world_pos)
			var tile_coords = main_layer.local_to_map(local_pos)
			selected_tile_coords = tile_coords
			map. print_cell(tile_coords)
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





# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_turn_timeout() -> void:
	fullmap.execute_turn()
	map. display_map_for_player(fullmap, 1)  # 重新显示新状态
	pass 
