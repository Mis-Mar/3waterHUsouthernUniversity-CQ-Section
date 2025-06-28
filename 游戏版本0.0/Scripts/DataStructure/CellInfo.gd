# 单个格子的数据结构
class_name CellInfo
extends Resource

var terrain_type: int = 0     # 0=空地，-1=山，-2=水，-3=主城，-4=城市
var owner: int = 0            # 0=未占领，1,2,... 表示不同玩家
var power: int = 0            # 空地/主城：当前兵力；城市：占领所需兵力


func _init(t := 0, o := 0, p := 0):
	terrain_type = t
	owner = o
	power = p
	
	
