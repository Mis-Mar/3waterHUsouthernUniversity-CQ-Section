extends Node
class_name ExpansionAgent

@onready var state_machine = $ExpansionAgent_StateMachine

var search_algorithm: M2S_SearchAlgorithm
var algorithm_map: AlgorithmMap
var main_city: Vector2i

var Not_Found: Array[Vector2i] = []
var Not_Occupy: Array[Vector2i] = []

var player_id: int
var full_map: FullMap

func _init(_player_id: int,_main_city: Vector2i, _full_map: FullMap) -> void:
	self.player_id = _player_id
	self.main_city = _main_city
	self.full_map = _full_map
	algorithm_map = AlgorithmMap.new(self.full_map)
	search_algorithm = M2S_SearchAlgorithm.new(self.algorithm_map,self.player_id)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.SEARCHING_EMPTYCITY)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
