import math
import numpy as np
import matplotlib.pyplot as plt
from collections import deque


class Node:
    def __init__(self, x, y, value=0, demand=0, obstacle=False):
        self.x = x
        self.y = y
        self.value = value  # 价值 V
        self.demand = demand  # 需求 C
        self.obstacle = obstacle  # 是否为障碍
        self.distance = float('inf')  # BFS 距离 D
        self.influence = 0  # 当前节点影响值 I
        self.final_influence = 0  # 最终影响值 FI


class Board:
    def __init__(self, size=10):
        self.size = size
        self.grid = [[Node(i, j) for j in range(size)] for i in range(size)]

    def set_obstacles(self, obstacles):
        """设置障碍"""
        for x, y in obstacles:
            self.grid[x][y].obstacle = True

    def set_value_points(self, value_points):
        """设置价值点"""
        for x, y, value in value_points:
            self.grid[x][y].value = value

    def set_target_points(self, target_points):
        """设置目标点"""
        for x, y, demand in target_points:
            self.grid[x][y].demand = demand

    def get_neighbors(self, node):
        """获取邻居节点"""
        directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        neighbors = []
        for dx, dy in directions:
            nx, ny = node.x + dx, node.y + dy
            if 0 <= nx < self.size and 0 <= ny < self.size and not self.grid[nx][ny].obstacle:
                neighbors.append(self.grid[nx][ny])
        return neighbors


class Algorithm:
    def __init__(self, board, tunable_param, threshold):
        self.board = board
        self.tunable_param = tunable_param
        self.threshold = threshold

    def bfs_distance(self, start_node):
        """从目标点出发进行BFS，计算每个节点的距离"""
        queue = deque([start_node])
        start_node.distance = 0
        while queue:
            current = queue.popleft()
            for neighbor in self.board.get_neighbors(current):
                if neighbor.distance == float('inf'):
                    neighbor.distance = current.distance + 1
                    queue.append(neighbor)

    def calculate_influence(self):
        """计算当前节点影响值和附加影响值"""
        for row in self.board.grid:
            for node in row:
                if node.value > 0:  # 如果是价值点
                    node.influence = (node.value ** 2 )* self.tunable_param
                    self._propagate_influence(node)

    def _propagate_influence(self, start_node):
        """从价值点出发传播影响值"""
        queue = deque([(start_node, 0)])  # (当前节点, 当前距离)
        visited = set()
        while queue:
            current, dist = queue.popleft()
            if (current.x, current.y) in visited:
                continue
            visited.add((current.x, current.y))
            influence = start_node.influence / math.sqrt((1 + dist) * self.tunable_param)
            if influence >= self.threshold:
                current.final_influence += influence
                for neighbor in self.board.get_neighbors(current):
                    queue.append((neighbor, dist + 1))

    def compute_final_influences(self, target_points):
        """主函数，计算所有节点的最终影响值"""
        for x, y, _ in target_points:
            self.bfs_distance(self.board.grid[x][y])
        self.calculate_influence()


class Visualizer:
    def __init__(self, board):
        self.board = board

    def plot_board(self, target_points, value_points):
        """绘制棋盘并显示数值、价值点和目标点"""
        grid_values = np.zeros((self.board.size, self.board.size))
        for row in self.board.grid:
            for node in row:
                grid_values[node.x][node.y] = node.final_influence

        plt.figure(figsize=(10, 10))
        plt.imshow(grid_values, cmap='viridis', interpolation='nearest')
        plt.colorbar(label='Final Influence')

        # 在每个格子中显示数值
        for i in range(self.board.size):
            for j in range(self.board.size):
                plt.text(j, i, f"{grid_values[i][j]:.2f}", ha='center', va='center', color='white', fontsize=8)

        # 标记目标点
        for x, y, _ in target_points:
            plt.scatter(y, x, color='red', label='Target Point' if x == target_points[0][0] else None)

        # 标记价值点
        for x, y, _ in value_points:
            plt.scatter(y, x, color='blue', label='Value Point' if x == value_points[0][0] else None)

        plt.title("Final Influence Values on Board")
        plt.legend()
        plt.show()



# 示例输入
if __name__ == "__main__":
    size = 10
    obstacles = [(2, 3), (4, 5), (6, 7)]
    value_points = [(1, 1, 10), (8, 2, 20), (4, 2, 10), (2, 8, 20), (1, 5, 15), (7, 1, 10)]
    #value_points = [(5, 2, 10), (6, 8, 15)]
    target_points = [(5, 5, 30)]

    board = Board(size)
    board.set_obstacles(obstacles)
    board.set_value_points(value_points)
    board.set_target_points(target_points)

    algorithm = Algorithm(board, tunable_param=3, threshold=1)
    algorithm.compute_final_influences(target_points)

    visualizer = Visualizer(board)
    visualizer.plot_board(target_points, value_points)
