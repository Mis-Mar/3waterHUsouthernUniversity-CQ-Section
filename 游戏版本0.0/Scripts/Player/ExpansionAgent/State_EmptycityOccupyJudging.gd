extends BaseState_ExpansionAgent
class_name State_EmptycityOccupyJudging

var Not_Occupy: Array[Vector2i]
var occupy_path: Array[Vector2i]


func enter() -> void:
	Not_Occupy = agent.Not_Occupy
	occupy_path.clear()
	if could_occupy_empty_city():
		#TODO 行动
		start_occupation_process()
	else:
		state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.SEARCHING_EMPTYCITY)

func could_occupy_empty_city() -> bool:
	for target_point in Not_Occupy:
		var cell: CellInfo = agent.full_map.get_cell(target_point)
		var demand: int = cell.get_power()
		var path = agent.search_algorithm.M2S_Search(target_point,demand,3,1,10,50)
		if path != [-1]:
			occupy_path = path
			return true
		else:
			pass
	return false

func start_occupation_process() -> void:
	#TODO 行动
	state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.OCCUPYING_CITY_PROCESSING)
	pass	
