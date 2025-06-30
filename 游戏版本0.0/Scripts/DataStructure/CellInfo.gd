# 单个格子的数据结构
class_name CellInfo
extends Resource

var _private_terrain_type: int = 0     # 0=空地，-1=山，-2=水，-3=主城，-4=城市
var _private_owner: int = 0            # 0=未占领，1,2,... 表示不同玩家
var _private_power: int = 0            # 空地/主城：当前兵力；城市：占领所需兵力
# 使用了脏数据优化性能，以后只用函数来操作数据
var _private_is_dirty: bool = true    # 默认 false，标记是否需要重绘或更新显示

func _init(t := 0, o := 0, p := 0):
	_private_terrain_type = t
	_private_owner = o
	_private_power = p
	_private_is_dirty=true

# 获取 / 设置地形类型
func get_type() -> int:
	return _private_terrain_type

func set_type(value: int) -> void:
	if _private_terrain_type != value:
		_private_terrain_type = value
		_private_is_dirty = true

# 获取 / 设置 owner
func get_owner() -> int:
	return _private_owner

func set_owner(value: int) -> void:
	if _private_owner != value:
		_private_owner = value
		_private_is_dirty = true

# 获取 / 设置 power
func get_power() -> int:
	return _private_power

func set_power(value: int) -> void:
	if _private_power != value:
		_private_power = value
		_private_is_dirty = true

# 获取 / 设置 is_dirty 标志
func is_dirty() -> bool:
	return _private_is_dirty

func clear_dirty_flag() -> void:
	_private_is_dirty = false



	
	
