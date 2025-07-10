extends Node
class_name ExpansionAgent

@onready var state_machine :ExpansionAgent_StateMachine = $ExpansionAgent_StateMachine
var agent_tpye: String = "Expansion"
var search_algorithm: M2S_SearchAlgorithm
var algorithm_map: AlgorithmMap
var main_city: Vector2i

var Not_Found: Array[Vector2i] = []
var Not_Occupy: Array[Vector2i] = []

var general: General_Entity
var player_id: int
var player_map: PlayerMap

var path_operations_city: Array
var path_operations_city_class: Array
var path_operations_search: Array
var path_current_class: int #当前path_manager操作等级

var is_path_manager_working: bool = false

signal path_add(path_class: int, _path_operations: Array)

func _ready() -> void:
	path_add.connect(on_path_add)
	general.general_be_occupied_cell.connect(on_be_occupied_cell)

func _init(_main_city: Vector2i, _player_map: PlayerMap) -> void:
	self.player_id = general.player_id
	self.main_city = _main_city
	self.player_map = _player_map
	algorithm_map = AlgorithmMap.new(self.player_map, general.general_id)
	search_algorithm = M2S_SearchAlgorithm.new(self.algorithm_map)
	state_machine.agent = self

func _run() -> void:
	self.path_operations_city.clear()
	self.path.path_operations_city_class.clear()
	self.path_operations_search.clear()
	self.path_current_class = -1
	state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.SEARCHING_EMPTYCITY)

func _process(delta: float) -> void:
	pass

func path_manager() -> void:
	self.is_path_manager_working = true
	var insert_replace: bool = false
	while !path_operations_city.is_empty():
		path_current_class = path_operations_city_class.pop_front()
		var path_operation = path_operations_city.pop_front()
		for path in path_operation:
			general.agent_path_output.emit(agent_tpye,path)
	while !path_operations_search.is_empty():
		path_current_class = 0
		for path in path_operations_search.pop_front():
			if path_current_class != 0:
				insert_replace = true
				break
			general.agent_path_output.emit(agent_tpye,path)
	if insert_replace:
		path_manager()
	self.is_path_manager_working = false
	#TODO check
	
func on_path_add(_path_class: int, _path_operations: Array) -> void:
	#读入新操作，删除优先级为0的操作（空地占领
	if(_path_class == 0):
		path_operations_search.append(_path_operations)
	else:
		path_operations_city.append(_path_operations)
		path_operations_city_class.append(_path_class)
		if path_current_class == 0:
			path_operations_search.clear()
			path_current_class = path_operations_city_class.front()
	if not self.is_path_manager_working:
		path_manager()
	
func on_be_occupied_cell(pos:Vector2i,_cell_info:CellInfo,enemy_general_id:int) -> void:
	#敌方入侵控制全局中断操作，若是,回滚搜索状态
	Not_Found.clear()
	if self.state_machine.current_state != state_machine.states[state_machine.ExpansionAgent_State.EMPTYCITY_OCCUPY]:
		state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.SEARCHING_EMPTYCITY)
	
	#TODO 检查是否这样即可？divzone是否可优化？
