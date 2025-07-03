extends Node
class_name General_Entity

var Expansion_agent: ExpansionAgent
var general_id: int
var main_city: Vector2i
var player_id: int
var player_map: FullMap

signal agent_path_output(agent_type: String, path: Vector2i)

#TODO player_map


signal on_player_change(_player_id: int)

func _init(_general_id: int, _main_city:Vector2i, _player_id: int, _player_map: FullMap) -> void:
	self.general_id = _general_id
	self.main_city = main_city
	self.player_id = _player_id
	self.player_map = _player_map
	Expansion_agent._init(player_id,main_city,player_map)
	_run()
	pass
	
func _run() -> void:
	if player_id == 0:
		pass
	else:
		Expansion_agent.run()
		
func update_player(_player_id: int) -> void:
	self.player_id = _player_id

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
