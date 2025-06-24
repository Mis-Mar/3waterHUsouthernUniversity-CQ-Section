import numpy as np
import time
import Player
import random



'''
本文件实现GeneralsGame类，包含游戏的主要逻辑和数据结构
'''



class GeneralsGame:
    def __init__(self,
                 players_id,  
                 map_size = 10, 
                 mountain_density = 0.1, 
                 city_density = 0.05,
                 city_fairness = 5):
        self.players = [] # 所有玩家的Player类型在里面了
        self.size = map_size # 地图大小
        self.mountain_density = mountain_density # 山脉密度
        self.city_density = city_density # 城市密度
        self.city_fairness = city_fairness # 城市大小公平
        self.map = None # 记录山脉城市地形等，3层嵌套列表
        self.player_position = [] # 储存玩家generals位置
        self.turn = 0 # 记录当前回合数
        self.generate_map() # 生成地图
        self.generate_players(players_id)
        self.generate_players_position() # 生成玩家位置


    def generate_players(self, players_id : list):
        '''
        生成玩家信息
        '''
        for id in players_id:
            self.players.append(Player(id)) # 创建玩家

    def generate_map(self):
        '''
        每个位置有三个变量组成，第一个表示所属阵营id（公立为0）， 第二个表示占领此格子需要的兵力, 第三个表示地块类型，有mountain、tile、 city、 general
        '''
        if not self.map: # 确保地图没有生成过
            map_origin = [[[0, 0, 'tile'] for _ in range(self.size)]for _ in range(self.size)] # 生成基础地图
            for i in range(self.size):
                for j in range(self.size):
                    if random.random() < self.mountain_density: # 按照概率生成山脉
                        map_origin[i][j] = [0, 0, 'mountain']  
                        continue # 不再生成city
                    if random.random() < self.city_density: # 按照概率和公平生成城市和具体兵力
                        map_origin[i][j] = [0, int(random.uniform(45 - self.city_fairness, 45 + self.city_fairness)), 'city']  
            self.map = map_origin # 记录生成的随机地图

    def generate_players_position(self):
        '''
        生成玩家的王城地点，更新地图数据
        '''
        if (not self.player_position) and self.map: # 确保地图已生成，且玩家位置没有生成过
            for player in self.players:
                invalid = True
                while invalid:
                    i, j = random.randrange(self.size), random.randrange(self.size)
                    if self.map[i][j][2] == 'tile' :
                        # 出生地在空地并且与其他王没有重叠
                        invalid = False
                self.map[i][j] = [player.id, 0, 'general'] # 更新系统地图数据
                self.player_position.append([i, j])
                player.position = [i, j]
                player.territory = [[i, j]] # 记录玩家领土

    def pass_player_sight(self):
        '''
        根据玩家占领的地块，给予玩家视野
        '''
        biases = [[1, 1], [1, 0], [1, -1], [0, 1], [0, 0], [0, -1], [-1, 1], [-1, 0], [-1, -1]] # 相邻具有的偏差
        for player in self.players: # 对所有玩家分享视野
            if player.live:
                player.sight = []
                for i in range(self.size):
                    for j in range(self.size): # 遍历所有地块
                        visible = False # 初始不可见
                        for bias in biases:
                            if [i + bias[0], j + bias[1]] in player.territory: # 与领土相邻则认为可见
                                visible = True
                        if visible: # 可视，就把信息如实告诉你, 并且记录视野信息，方便后期渲染
                            player.map[i][j] = self.map[i][j]
                            player.sight.append([i, j])
                        else: # 不可视要讨论
                            if (self.map[i][j][2] == 'mountain') or (self.map[i][j][2] == 'city'): # 山或者塔，统一渲染成塔
                                player.map[i][j] = [0, 0, 'mountain']  # 山
                            else:
                                player.map[i][j] = [0, 0, 'tile'] # 其余全部渲染成空地（对别人的王也是）

    def is_valid(self, player: Player,
                option: list): 
        '''
        判断移动是否有意义,传递移动的数据：即一个坐标+移动+移动是否半兵：例如option = [3, 4, 'up', False]
        '''
        direction_dict = {'up': [-1, 0], 'down': [1, 0], 'left': [0, -1], 'right': [0, 1]}
        cx, cy = option[0], option[1] # current
        nx, ny = cx + direction_dict[option[2]][0], cy + direction_dict[option[2]][1] # next
        if player.map[cx][cy][0] != player.id: # 不是自己的领地，你移动个屁
            return False
        if player.map[cx][cy][1] <= 1: # 连两个兵都没有，你移动个屁
            return False
        if  (nx < 0) or\
            (nx >= player.map_size) or\
            (ny < 0) or\
            (ny >= player.map_size) :
            return False # 都越界了，你移动个屁
        if player.map[nx][ny][2] == 'mountain':
            return False # 都移动到山上了，你移动个屁
        return True
    
    def move(self, player, option):
        direction_dict = {'up': [-1, 0], 'down': [1, 0], 'left': [0, -1], 'right': [0, 1]}
        cx, cy = option[0], option[1] # current
        nx, ny = cx + direction_dict[option[2]][0], cy + direction_dict[option[2]][1] # next
        cur_army = self.map[cx][cy][1] # 当前兵力
        move_out = (cur_army // 2) if option[3] else cur_army - 1 # 移动出的兵力
        move_left = ((cur_army + 1) // 2) if option[3] else 1 # 剩下兵力
        self.map[cx][cy][1] = move_left # 更新剩余兵力

        if self.map[nx][ny][0] == player.id: # 玩家移动到自己的领地
            self.map[nx][ny][1] += move_out
        else: # 其他阵营兵力
            if move_out > self.map[nx][ny][1]: # 大于敌人
                if self.map[nx][ny][2] == 'general': # 如果是敌方王城
                    self.map[nx][ny][2] = 'city'
                    killed_id = self.map[nx][ny][0] # 杀死敌方王
                    self.map[nx][ny][1] = move_out - self.map[nx][ny][1]
                    self.map[nx][ny][0] = player.id # 归入玩家阵营
                    self.kill_player(player.id, killed_id)
                else:
                    self.map[nx][ny][1] = move_out - self.map[nx][ny][1]
                    self.map[nx][ny][0] = player.id # 归入玩家阵营
                    player.territory.append([nx, ny]) # 更新玩家领土
                    self.players[self.map[nx][ny][0] - 1].territorry.delete([nx, ny]) # 删除被攻击方原有领土
            else:
                self.map[nx][ny][1] -= move_out # 打不动，兵力消耗掉了
    
    def kill_player(self, killer_id, killed_id):
        '''
        杀死玩家，传入杀手和被杀者
        '''
        self.players[killed_id - 1].live = False # 被杀者死亡
        self.players[killer_id - 1].action_queue = [] # 杀手清空任务队列
        self.players[killed_id - 1].territory = [] # 被杀者领土清空
        for i in range(self.size):
            for j in range(self.size):
                if self.map[i][j][0] == killed_id:
                    self.map[i][j][0] = killer_id
                    self.player[killed_id - 1].territory.remove([i, j]) # 更新被杀者领土
                    self.map[i][j][1] = (self.map[i][j][1] + 1) // 2 # 杀死玩家后，剩余兵力一半归入杀手阵营
        
    def step(self):
        '''
        执行每turn时对数据集所做的更新
        '''
        self.turn += 1 # 回合数+1
        for i in range(self.size):
            for j in range(self.size):
                if self.map[i][j][2] == 'general' or (self.map[i][j][2] == 'city' and self.map[i][j][0] != 0): # 如果是王城或者被占领的城市
                    self.map[i][j][1] += 1 
                if self.turn % 25 == 0:  # 每25回合生成新的兵力
                    if self.map[i][j][0] != 0: # 是有人占领的位置
                        self.map[i][j][1] += 1 # 增加兵力
        self.pass_player_sight() # 更新玩家视野
        for player in self.players:# 对所有玩家
            if player.live: # 如果玩家还活着
                while player.action_queue: # 执行队列非空
                    option = player.action_queue.pop(0) # 取出最前端元素
                    if self.is_valid(player, option): # 判断合法性
                        self.move(player, option) # 合法则执行
                        break 