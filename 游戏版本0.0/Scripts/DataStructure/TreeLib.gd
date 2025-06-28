class_name TreeLib
extends RefCounted

# 树节点类
class TreeNode:
	var identifier: String
	var data: Variant
	var children: Array[TreeNode] = []
	var parent: TreeNode = null
	
	func _init(id: String, node_data: Variant, parent_node: TreeNode = null):
		identifier = id
		data = node_data
		parent = parent_node
	
	# 添加子节点
	func add_child(child: TreeNode) -> void:
		children.append(child)
	
	# 深度优先遍历
	func traverse_depth_first() -> Array[TreeNode]:
		var result: Array[TreeNode] = [self]
		for child in children:
			result.append_array(child.traverse_depth_first())
		return result
	
	# 广度优先遍历
	func traverse_breadth_first() -> Array[TreeNode]:
		var result: Array[TreeNode] = []
		var queue: Array[TreeNode] = [self]
		
		while not queue.is_empty():
			var current = queue.pop_front()
			result.append(current)
			for child in current.children:
				queue.append(child)
		
		return result
	
	# 获取节点路径
	func get_path() -> Array[TreeNode]:
		var path: Array[TreeNode] = []
		var current: TreeNode = self
		while current != null:
			path.push_front(current)
			current = current.parent
		return path

# 主树类
var _nodes: Dictionary = {}  # 节点字典 {identifier: TreeNode}
var _root: TreeNode = null    # 根节点

# 创建节点
func create_node(identifier: String, data: Variant, parent_id: String = "") -> bool:
	# 检查标识符是否已存在
	if _nodes.has(identifier):
		push_error("节点标识符已存在: " + identifier)
		return false
	
	# 处理根节点情况
	if parent_id.is_empty():
		if _root != null:
			push_error("根节点已存在")
			return false
		
		var new_node = TreeNode.new(identifier, data)
		_nodes[identifier] = new_node
		_root = new_node
		return true
	
	# 检查父节点是否存在
	if not _nodes.has(parent_id):
		push_error("父节点不存在: " + parent_id)
		return false
	
	# 创建新节点
	var parent_node = _nodes[parent_id]
	var new_node = TreeNode.new(identifier, data, parent_node)
	_nodes[identifier] = new_node
	parent_node.add_child(new_node)
	return true

# 获取节点
func get_node(identifier: String) -> TreeNode:
	return _nodes.get(identifier, null)

# 删除节点及其子树
func remove_node(identifier: String) -> bool:
	if not _nodes.has(identifier):
		return false
	
	var node = _nodes[identifier]
	
	# 如果是根节点
	if node == _root:
		_root = null
	
	# 从父节点移除
	if node.parent != null:
		node.parent.children.erase(node)
	
	# 递归删除所有子节点
	var to_remove = node.traverse_depth_first()
	for n in to_remove:
		_nodes.erase(n.identifier)
	
	return true

# 获取根节点
func get_root() -> TreeNode:
	return _root

# 检查节点是否存在
func contains(identifier: String) -> bool:
	return _nodes.has(identifier)

# 获取树的大小（节点数量）
func size() -> int:
	return _nodes.size()

# 判断树是否为空
func is_empty() -> bool:
	return _nodes.is_empty()

# 清空树
func clear() -> void:
	_nodes.clear()
	_root = null

# 深度优先遍历
func depth_first_traversal() -> Array[TreeNode]:
	if _root == null:
		return []
	return _root.traverse_depth_first()

# 广度优先遍历
func breadth_first_traversal() -> Array[TreeNode]:
	if _root == null:
		return []
	return _root.traverse_breadth_first()

# 获取节点路径（从根到节点）
func path_to_node(identifier: String) -> Array[TreeNode]:
	if not _nodes.has(identifier):
		return []
	return _nodes[identifier].get_path()

# 显示树结构（用于调试）
func show_tree() -> void:
	if _root == null:
		print("树为空")
		return
	
	print("树结构:")
	_show_subtree(_root, 0)

# 递归显示子树
func _show_subtree(node: TreeNode, depth: int) -> void:
	var indent = "  ".repeat(depth)
	print(indent + "├─ " + node.identifier + " (数据: " + str(node.data) + ")")
	for child in node.children:
		_show_subtree(child, depth + 1)
