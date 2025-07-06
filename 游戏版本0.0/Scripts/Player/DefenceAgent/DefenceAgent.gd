extends Node
class_name DefenceAgent

var agent_tpye: String = "Defence"
var search_algorithm: M2S_SearchAlgorithm
var algorithm_map: AlgorithmMap
var main_city: Vector2i

var general: General_Entity
var player_id: int
var player_map: PlayerMap

var path_operations: Array
var path_class: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _init(_main_city: Vector2i, _player_map: PlayerMap) -> void:
	self.player_id = general.player_id
	self.main_city = _main_city
	self.player_map = _player_map
	algorithm_map = AlgorithmMap.new(self.player_map, general.general_id)
	search_algorithm = M2S_SearchAlgorithm.new(self.algorithm_map)

func is_city_path_reachable(ratio_param: float) -> bool:
	return true

func is_crucial_point_reachable(ratio_param: float) -> bool:
	return true
	
func general_zone_fill() -> void:
	pass
