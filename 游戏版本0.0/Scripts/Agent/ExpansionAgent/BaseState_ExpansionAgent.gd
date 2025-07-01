extends Node
class_name BaseState_ExpansionAgent

var state_machine: ExpansionAgent_StateMachine = null

var agent: ExpansionAgent
var main_city: Vector2i
var player_id: int

func get_agent() -> ExpansionAgent:
	return state_machine.agent
	
func _init() -> void:
	agent = get_agent()
	main_city = agent.main_city
	player_id = agent.player_id

func enter(): pass

func exit(): pass

func update(_delta: float) -> void: pass

func _physics_update(_delta: float) -> void: pass
