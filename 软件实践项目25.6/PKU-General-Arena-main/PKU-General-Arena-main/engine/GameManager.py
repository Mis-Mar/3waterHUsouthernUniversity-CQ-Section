import numpy as np
import time



class GeneralsGame:
    EMPTY = 0
    PLAYER1 = 1
    PLAYER2 = 2
    MOUNTAIN = -1
    
    def __init__(self, size=15, players=2):
        self.size = size
        self.board = np.zeros((size, size), dtype=int)
        self.armies = np.zeros((size, size), dtype=int)
        self.turn = 0
        self._init_board(players)
        self.move_count = {p+1: 0 for p in range(players)}
        self.last_turn_time = time.time()
        self.turn_interval = 0.7  # 秒
    
    def _init_board(self, players):
        """初始化游戏板"""
        # 设置玩家起始位置
        self.board[2][2] = self.PLAYER1
        self.board[self.size-3][self.size-3] = self.PLAYER2
        self.armies[2][2] = 0 # 这里是初始兵力1
        self.armies[self.size-3][self.size-3] = 0 # 这里是初始兵力2
        
        # 添加山脉
        for _ in range(self.size):
            x, y = np.random.randint(0, self.size, 2)
            self.board[x][y] = self.MOUNTAIN

    def move(self, player, from_pos, to_pos):
        """执行移动操作"""
        x1, y1 = from_pos
        x2, y2 = to_pos
    
        # 步数限制
        if not self.can_move(player):
            return False
        # 兵力为1不能移动
        if self.armies[x1][y1] <= 1:
            return False
        # 合法性检查
        if not self._is_valid_move(player, from_pos, to_pos):
            return False
    
        # 执行移动
        moving_army = self.armies[x1][y1] - 1
        self.armies[x1][y1] = 1
    
        # 处理目标格
        if self.board[x2][y2] == self.EMPTY:
            self.board[x2][y2] = player
            self.armies[x2][y2] = moving_army
        elif self.board[x2][y2] == player:
            # 己方地块，兵力相加（如果目标格兵力为0，直接赋值）
            if self.armies[x2][y2] > 0:
                self.armies[x2][y2] += moving_army
            else:
                self.armies[x2][y2] = moving_army
        else:  # 敌方地块
            self.armies[x2][y2] -= moving_army
            if self.armies[x2][y2] < 0:
                self.board[x2][y2] = player
                self.armies[x2][y2] = abs(self.armies[x2][y2])
    
        self.move_count[player] += 1
        return True

    
    def _is_valid_move(self, player, from_pos, to_pos):
        """验证移动是否合法"""
        x1, y1 = from_pos
        x2, y2 = to_pos
        
        # 检查是否属于玩家
        if self.board[x1][y1] != player:
            return False
        
        # 检查移动距离
        if abs(x1 - x2) > 1 or abs(y1 - y2) > 1:
            return False
        
        # 检查目标不是山脉
        if self.board[x2][y2] == self.MOUNTAIN:
            return False
            
        return True
    
    def get_state(self):
        """获取游戏状态（简化版）"""
        return {
            "board": self.board.tolist(),
            "armies": self.armies.tolist(),
            "turn": self.turn,
            "move_count": self.move_count.copy()
        }
    
    def can_move(self, player):
        return self.move_count[player] < 2

    def next_turn(self):
        # 每回合主城+1
        self.armies[2][2] += 1
        self.armies[self.size-3][self.size-3] += 1
        self.turn += 1
        self.move_count = {p: 0 for p in self.move_count}
        # 每25回合所有己方地块+1
        if self.turn % 25 == 0:
            for x in range(self.size):
                for y in range(self.size):
                    if self.board[x][y] == self.PLAYER1 or self.board[x][y] == self.PLAYER2:
                        self.armies[x][y] += 1