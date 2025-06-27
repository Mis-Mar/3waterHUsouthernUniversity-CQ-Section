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
const TERRAIN_EMPTY := 0      # 空地
const TERRAIN_MOUNTAIN := -1  # 山地
const TERRAIN_WATER := -2     # 水域
const TERRAIN_CAPITAL := -3   # 主城
const TERRAIN_CITY := -4      # 城市


# 材质相关
