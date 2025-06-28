class_name PriorityQueue
extends RefCounted

# 内部存储结构 [priority, value]
var _heap: Array = []

# 添加元素
func push(priority: float, value) -> void:
	_heap.append([priority, value])
	_sift_up(_heap.size() - 1)

# 弹出最小优先级元素
func pop():
	if is_empty():
		return null
	
	var result = _heap[0][1]
	var last = _heap.pop_back()
	
	if _heap.size() > 0:
		_heap[0] = last
		_sift_down(0)
	
	return result

# 查看最小元素不弹出
func peek():
	return null if is_empty() else _heap[0][1]

# 检查队列是否为空
func is_empty() -> bool:
	return _heap.is_empty()

# 获取队列大小
func size() -> int:
	return _heap.size()

# 清空队列
func clear() -> void:
	_heap.clear()

# 元素上浮（插入时维护堆结构）
func _sift_up(index: int) -> void:
	var child_index = index
	while child_index > 0:
		var parent_index = (child_index - 1) / 2
		
		if _heap[child_index][0] < _heap[parent_index][0]:
			_swap(child_index, parent_index)
			child_index = parent_index
		else:
			break

# 元素下沉（删除时维护堆结构）
func _sift_down(index: int) -> void:
	var parent_index = index
	var heap_size = _heap.size()
	
	while true:
		var left_child = 2 * parent_index + 1
		var right_child = 2 * parent_index + 2
		var smallest = parent_index
		
		if left_child < heap_size and _heap[left_child][0] < _heap[smallest][0]:
			smallest = left_child
		
		if right_child < heap_size and _heap[right_child][0] < _heap[smallest][0]:
			smallest = right_child
		
		if smallest != parent_index:
			_swap(parent_index, smallest)
			parent_index = smallest
		else:
			break

# 交换堆中两个元素
func _swap(i: int, j: int) -> void:
	var temp = _heap[i]
	_heap[i] = _heap[j]
	_heap[j] = temp
