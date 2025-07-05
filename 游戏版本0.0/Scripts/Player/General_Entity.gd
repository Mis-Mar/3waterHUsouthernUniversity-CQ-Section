extends Node
class_name General_Entity

var Expansion_agent: ExpansionAgent
var general_id: int
var main_city: Vector2i
var player_id: int
var player_map: PlayerMap

var path_operations: Array[Vector2i]

signal agent_path_output(agent_type: String, path_operate: Vector2i)

func _ready() -> void:
	agent_path_output.connect(on_path_add)
	_run()

func _init(_general_id: int, _main_city:Vector2i, _player_id: int, _player_map: PlayerMap) -> void:
	self.general_id = _general_id
	self.main_city = main_city
	self.player_id = _player_id
	self.player_map = _player_map
	Expansion_agent._init(player_id,main_city,player_map)
	pass
	
func _run() -> void:
	if player_id == 0:
		pass
	else:
		Expansion_agent._run()

func path_manager() -> void:
	while !path_operations.is_empty():
		var path_operate = path_operations.pop_front()
		#TODO send to player
		pass
		
func on_path_add(agent_type:String, path_operate: Vector2i) -> void:
	#TODO agent调用、区分
	path_operations.append(path_operate)
	path_manager()
