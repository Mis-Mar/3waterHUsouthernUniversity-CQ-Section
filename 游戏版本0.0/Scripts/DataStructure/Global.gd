# 这里放全局变量 # 常量当成宏定义来用方便 # 变量用来表示全局状态之类的
# Global.gd已经设置默认全局加载
extends Node

# 六边形向量的方向对应索引
const DIR_DOWM_R := 0        # (1,  0)
const DIR_DOWM_L := 4        # (0,  1)
const DIR_DOWN := 5          # (1,  1)
const DIR_UP := 2            # (-1,-1)
const DIR_UP_R := 1          # (0, -1)
const DIR_UP_L := 3          # (-1, 0)
const HEX_DIRECTIONS := [# 六边形邻接向量
	Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, -1),
	Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 1)
]


# 地块信息相关  TERRAIN
const TERRAIN_CAPITAL := 1   # 主城
const TERRAIN_WATER := 2     # 水域
const TERRAIN_MOUNTAIN := 3  # 山地
const TERRAIN_EMPTY := 4     # 空地
const TERRAIN_CITY := 5      # 空地
#
const INVIS_EMPTY   :=-1       #空地/主城 显示空地
const INVIS_MOUNTAIN:=-2     #山地/城市 显示山地
const INVIS_WATER   :=-3        #水       显示水


# 地形材质
const TERRAIN_TILE_INFO := {
	TERRAIN_CAPITAL: {
		"source_id": 0,
		"atlas_coords": Vector2i(0, 0),
		"alternative_tile": 0,
	},
	TERRAIN_WATER: {
		"source_id": 38,
		"atlas_coords": Vector2i(0, 0),
		"alternative_tile": 0,
	},
	TERRAIN_MOUNTAIN: {
		"source_id": 27,
		"atlas_coords": Vector2i(0, 0),
		"alternative_tile": 0,
	},
	TERRAIN_EMPTY: {
		"source_id": 22,
		"atlas_coords": Vector2i(0, 0),
		"alternative_tile": 0,
	},
	TERRAIN_CITY: {
		"source_id": 15,
		"atlas_coords": Vector2i(0, 0),
		"alternative_tile": 0,
	},
	INVIS_EMPTY: {
		"source_id": 22,
		"atlas_coords": Vector2i(0, 0),
		"alternative_tile": 0,
	},
	INVIS_MOUNTAIN: {
		"source_id": 27,
		"atlas_coords": Vector2i(0, 0),
		"alternative_tile": 0,
	},
	INVIS_WATER: {
		"source_id": 38,
		"atlas_coords": Vector2i(0, 0),
		"alternative_tile": 0,
	},
}

# rpc连接
const MAX_CLIENTS:=7# 最大连接数（不算自己）
# 游玩的地图选择
var game_map_id:=0
