extends Control

@onready var main_layer: TileMapLayer = $MainLayer



# 屏幕坐标转格子坐标
func get_tile_coords_from_screen_pos(screen_pos: Vector2) -> Vector2i:
	var world_pos = main_layer.get_viewport_transform().affine_inverse() * screen_pos
	var local_pos = main_layer.to_local(world_pos)
	return main_layer.local_to_map(local_pos)



#测试__________________________________________________________________________________________________________________________________________________________________
# 接受tile坐标，输出信息//测试用
func print_cell(tile_coords: Vector2i) -> void:
	var source_id := main_layer.get_cell_source_id(tile_coords)
	var atlas_coords := main_layer.get_cell_atlas_coords(tile_coords)
	var alt_id := main_layer.get_cell_alternative_tile(tile_coords)
	if source_id != -1:
		print("位置坐标: ", tile_coords)
		print("Tile Source ID: ", source_id)
		print("Atlas 坐标: ", atlas_coords)
		print("Alternative Tile ID: ", alt_id)
	else:
		print("点击的是空格子: ", tile_coords)
	print(" ")
