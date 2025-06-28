# tree.gd
class_name Treelib
extends RefCounted

# 节点类
class TreeNode:
	var identifier: String
	var data: Variant
	var children: Array[TreeNode] = []
	var parent: TreeNode = null
	var depth: int = 0

	func _init(id: String, node_data: Variant = null):
		identifier = id
		data = node_data

	# 添加子节点
	func add_child(node: TreeNode) -> bool:
		if not node: return false
		children.append(node)
		node.parent = self
		node.depth = depth + 1
		return true

	# 递归获取所有后代节点
	func get_descendants() -> Array[TreeNode]:
		var descendants: Array[TreeNode] = []
		for child in children:
			descendants.append(child)
			descendants.append_array(child.get_descendants())
		return descendants

# 树结构主体
var root: TreeNode
var nodes: Dictionary = {}
var _last_depth: int = -1
var _output_buffer: String = ""

# 创建根节点
func create_root(root_id: String, data: Variant = null) -> TreeNode:
	root = TreeNode.new(root_id, data)
	nodes[root_id] = root
	return root
	
func get_root() -> TreeNode:
	return root

# 添加节点
func add_node(node_id: String, parent_id: String, data: Variant = null) -> TreeNode:
	if not parent_id in nodes:
		push_error("Parent node not found: " + parent_id)
		return null
	
	if node_id in nodes:
		push_error("Node ID already exists: " + node_id)
		return null
	
	var parent_node = nodes[parent_id]
	var new_node = TreeNode.new(node_id, data)
	parent_node.add_child(new_node)
	nodes[node_id] = new_node
	return new_node

# 获取节点
func get_node(node_id: String) -> TreeNode:
	return nodes.get(node_id)

func get_parent(node_id: String) -> TreeNode:
	var	 node = get_node(node_id)
	return node.parent

# 获取子节点
func children(node_id: String) -> Array[TreeNode]:
	var node = get_node(node_id)
	return node.children if node else []

# 获取所有子节点（递归）
func all_children(node_id: String) -> Array[TreeNode]:
	var node = get_node(node_id)
	return node.get_descendants() if node else []

# 移动节点
func move_node(source_id: String, dest_id: String) -> bool:
	var src_node = get_node(source_id)
	var dest_node = get_node(dest_id)
	
	if not src_node or not dest_node:
		return false
	
	# 从原父节点移除
	if src_node.parent:
		src_node.parent.children.erase(src_node)
	
	# 添加到新父节点
	dest_node.add_child(src_node)
	return true

# 删除节点
func remove_node(node_id: String) -> bool:
	var node = get_node(node_id)
	if not node: 
		return false
	
	# 删除所有子节点
	for child in node.children.duplicate():
		remove_node(child.identifier)
	
	# 从父节点移除
	if node.parent:
		node.parent.children.erase(node)
	
	# 从节点字典移除
	nodes.erase(node_id)
	return true

# 获取子树深度
func depth(node: TreeNode = null) -> int:
	if not node:
		node = root
		if not node: 
			return -1
	
	var max_depth = node.depth
	for child in node.children:
		max_depth = max(max_depth, depth(child))
	return max_depth

# 打印树结构
func show(line_type: String = "ascii", show_data: bool = false) -> String:
	_output_buffer = ""
	_last_depth = -1
	_print_node(root, "", true, line_type, show_data)
	return _output_buffer

# 内部递归打印方法
func _print_node(node: TreeNode, prefix: String, is_last: bool, line_type: String, show_data: bool):
	# 确定连接符号
	var connectors := {
		"ascii": ["|-- ", "`-- ", "|   ", "    "],
		"utf8": ["├── ", "└── ", "│   ", "    "]
	}
	
	var conn = connectors.get(line_type, connectors["ascii"])
	
	# 生成当前行
	var node_line = conn[1] if is_last else conn[0]
	var line = prefix + node_line + node.identifier
	
	# 添加数据展示
	if show_data and node.data != null:
		line += " [%s]" % str(node.data)
	
	_output_buffer += line + "\n"
	
	# 更新前缀
	var new_prefix = prefix + (conn[3] if is_last else conn[2])
	
	# 递归子节点
	for i in range(node.children.size()):
		var last_child = (i == node.children.size() - 1)
		_print_node(node.children[i], new_prefix, last_child, line_type, show_data)

# 清除整棵树
func clear():
	nodes.clear()
	root = null
