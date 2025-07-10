extends Node

@onready var menu_map: Control = $"../MenuMap"


func _unhandled_input(event: InputEvent) -> void:
	# 鼠标左键选中
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 获取左键选中的格子
			var tile_coords = menu_map.get_tile_coords_from_screen_pos(event.position)
			# menu_map. print_cell(tile_coords)
			if tile_coords==Vector2i(-3,2):
				print("点击开始")
				var err = get_tree().change_scene_to_file("res://Scenes/game_multi/prepare.tscn")
				if err != OK:
					print("切换场景失败，错误码: ", err)
