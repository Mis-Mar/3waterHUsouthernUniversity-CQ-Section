# 这里放全局变量 # 常量当成宏定义来用方便 # 变量用来表示全局状态之类的
# Global.gd已经设置默认全局加载
extends Node

# 六边形向量的方向对应索引
const DIR_DOWM_R := 0        # (1, 0)
const DIR_DOWM_L := 1        # (0, 1)
const DIR_DOWN := 2          # (1, 1)
const DIR_UP := 3            # (-1, -1)
const DIR_UP_R := 4          # (0, -1)
const DIR_UP_L := 5          # (-1, 0)

# 地块信息相关  TERRAIN
const TERRAIN_CAPITAL := 0   # 主城
const TERRAIN_WATER := 1     # 水域
const TERRAIN_MOUNTAIN := 2  # 山地
const TERRAIN_EMPTY := 3     # 空地
const TERRAIN_CITY := 4      # 城市

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
}

# 材质相关
