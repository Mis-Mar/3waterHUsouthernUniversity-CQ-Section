import math
import treelib
import numpy as np
import matplotlib.pyplot as plt
from collections import deque
from queue import PriorityQueue



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


class M2S_Search_Algorithm:

    def __init__(self, board, tunable_param, threshold):
        self.board = board
        self.tunable_param = tunable_param
        self.threshold = threshold

    def M2S_Search(self, target_points):
        """
        主函数：整合前向BFS和反向BFS，计算所有节点的最终影响值并获取源点表
        :param target_points: 目标点列表 [(x, y, 需求值), ...]
        :return: 源点列表 [(x, y, 当前节点价值), ...]
        """
        # 前向BFS：计算所有节点的最终影响值
        self.compute_final_influences(target_points)

        # 反向BFS：从目标点出发获取源点表、路径
        source_points = []
        search_tree = treelib.Tree()

        source_points, search_tree = self.reverse_bfs(target_points)

        # 剪枝操作：删除多余节点
        self._prune_tree(search_tree, source_points)

        # 后序遍历形成路径操作序列
        path_operations = self._postorder_traversal(search_tree)

        return source_points, path_operations

    def compute_final_influences(self, target_points):
        """主函数，计算所有节点的最终影响值"""
        for x, y, _ in target_points:
            self.bfs_distance(self.board.grid[x][y])
        self.calculate_influence()

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

    def reverse_bfs(self, target_points):
        """
        反向BFS搜索，返回满足需求值的源点列表
        """
        for x, y, demand in target_points:
            start_node = self.board.grid[x][y]
            demand_threshold = demand  # 需求值阈值

        search_tree = treelib.Tree()
        open_list = PriorityQueue()  # 大根堆，存储 (负的最终影响值, 节点)
        close_list = set()  # 已访问节点集合
        source_points = []  # 源点列表
        accumulated_value = 0  # 累计价值

        # 初始化：将起始节点加入open表
        search_tree.create_node(identifier=str((start_node.x, start_node.y)), data=start_node)
        open_list.put((-start_node.final_influence, str((start_node.x, start_node.y)), start_node))

        while not open_list.empty():
            _, _, current = open_list.get()  # 取出堆顶节点
            if (current.x, current.y) in close_list:
                continue
            close_list.add((current.x, current.y))

            # 累计价值
            if current.value > 0:  # 如果是价值点
                accumulated_value += current.value
                source_points.append((current.x, current.y, current.value))  # 记录源点

            # 如果累计价值超过需求值，则终止搜索
            if accumulated_value >= demand_threshold:
                break

            # 扩展邻居节点
            for neighbor in self.board.get_neighbors(current):
                if (neighbor.x, neighbor.y) not in close_list:
                    if not search_tree.contains(str((neighbor.x, neighbor.y))):  # 确保标识符是字符串类型
                        search_tree.create_node(identifier=str((neighbor.x, neighbor.y)), data=neighbor,parent=str((current.x, current.y)))
                    open_list.put((-neighbor.final_influence, str((neighbor.x, neighbor.y)), neighbor))

        return source_points, search_tree

    def _heuristic_cost(self, node, source_points):
        """计算当前节点到所有源点的曼哈顿距离之和"""
        return sum(abs(node.x - sx) + abs(node.y - sy) for sx, sy, _ in source_points)

    def _prune_tree(self, search_tree, source_points):
        """剪枝操作删除多余节点"""
        # 提取源点位置
        source_positions = {(sx, sy) for sx, sy, _ in source_points}

        def contains_source(node_id):
            """递归检查子树是否包含源点"""
            node_data = search_tree.get_node(node_id).data
            if (node_data.x, node_data.y) in source_positions:
                return True
            for child_id in search_tree.children(node_id):
                if contains_source(child_id.identifier):
                    return True
            return False

        # 初始化待删除节点列表
        nodes_to_remove = []

        # 遍历搜索树
        for node_id in search_tree.expand_tree(mode=treelib.Tree.DEPTH):
            if not contains_source(node_id):
                nodes_to_remove.append(node_id)

        # 删除多余节点
        for node_id in nodes_to_remove:
            # 确保节点仍然存在于树中再进行删除
            if search_tree.contains(node_id):  # 检查节点是否存在
                search_tree.remove_node(node_id)

    def _postorder_traversal(self, search_tree):
        """后序遍历形成路径操作序列"""
        path_operations = []

        def postorder_traverse(node):
            for child in search_tree.children(node):
                postorder_traverse(child.identifier)
            #    path_operations.append((child.identifier, node))
            # 添加当前节点与其父节点的边（如果存在父节点）
            parent = search_tree.parent(node)
            if parent:
                path_operations.append((node, parent.identifier))

        root = search_tree.root
        postorder_traverse(root)
        return path_operations

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

    def plot_board_with_paths(self, path_operations):
        """绘制棋盘并显示路径操作序列"""
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

        # 绘制路径箭头
        for idx, (child_id, parent_id) in enumerate(path_operations):
            child_node = self.board.grid[int(child_id[1])][int(child_id[4])]
            parent_node = self.board.grid[int(parent_id[1])][int(parent_id[4])]
            plt.annotate(str(idx + 1), xy=(parent_node.y, parent_node.x),
                         xytext=(child_node.y, child_node.x),
                         arrowprops=dict(arrowstyle='->', color='red', lw=2))
        plt.title("Final Influence Values on Board with Paths")
        plt.show()


# 示例输入
if __name__ == "__main__":
    size = 10
    obstacles = [(2, 3), (4, 5), (6, 7)]
    value_points = [(1, 1, 10), (8, 2, 20), (4, 2, 10), (2, 8, 20), (1, 5, 15), (7, 1, 10)]

    # 随机生成障碍和价值点
    for x in range(size):
        for y in range(size):
            if np.random.rand() < 0.3 and (x, y) not in obstacles and (x, y) not in value_points:
                value = np.random.randint(1, 6)
                value_points.append((x, y, value))

    #value_points = [(5, 2, 10), (6, 8, 15)]
    target_points = [(8, 7, 70)]

    board = Board(size)
    board.set_obstacles(obstacles)
    board.set_value_points(value_points)
    board.set_target_points(target_points)

    algorithm = M2S_Search_Algorithm(board, tunable_param=3, threshold=1)
    #source_points , path_operations = algorithm.M2S_Search(target_points)
    source_points , path_operations = algorithm.M2S_Search(target_points)
    print("源点表:", source_points)
    print("路径操作序列:", path_operations)

    visualizer = Visualizer(board)
    visualizer.plot_board(target_points, value_points)
    visualizer.plot_board_with_paths(path_operations)

