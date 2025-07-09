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

var path_operations: Array
var path_class: int

signal path_add(path_class: int, _path_operations: Array)

func _ready() -> void:
	path_add.connect(on_path_add)

func _init(_main_city: Vector2i, _player_map: PlayerMap) -> void:
	self.player_id = general.player_id
	self.main_city = _main_city
	self.player_map = _player_map
	algorithm_map = AlgorithmMap.new(self.player_map, general.general_id)
	search_algorithm = M2S_SearchAlgorithm.new(self.algorithm_map)
	state_machine.agent = self

func _run() -> void:
	state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.SEARCHING_EMPTYCITY)

#FIXME 敌方入侵中断返回SE state操作

func _process(delta: float) -> void:
	pass

func path_manager() -> void:
	while !path_operations.is_empty():
		var AY: Array = path_operations.front()
		path_class = AY[0]
		while !path_operations.is_empty():
			AY = path_operations.front()
			if path_class == AY[0]:
				general.agent_path_output.emit(agent_tpye,AY[1])
			else:
				break
		#HACK 待完成 分类类比，单个输出
		pass

func on_path_add(_path_class: int, _path_operations: Array) -> void:
	#读入新操作，删除优先级为0的操作（空地占领
	#HACK check this part?
	if(_path_class != 0):
		for AR in path_operations:
			if(AR[0] == 0):
				path_operations.erase(AR)
	for _path_operate in _path_operations:
		var AY: Array = [_path_class,_path_operate]
		self.path_operations.append_array(AY)
	path_manager()
