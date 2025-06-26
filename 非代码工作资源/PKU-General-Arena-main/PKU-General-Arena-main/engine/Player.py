'''
本文件实现player的局部视角，会预留调用的接口

'''

class Player:
    def __init__(self, player_id):
        self.position = None
        self.id = player_id # 范围在1-n
        self.sight = None
        self.map = None
        self.territory = None # 一堆2元列表的列表
        self.general_position = None
        self.action_queue = None # 任务队列
        self.map_size = None
        self.live = True # 是否存活






   
    