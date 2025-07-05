extends BaseState_ExpansionAgent
class_name State_EmptycityOccupy

var Not_Occupy: Array[Vector2i]
var occupy_path: Array[Vector2i]
var path_class: int = 1

func enter() -> void:
	Not_Occupy = agent.Not_Occupy
	occupy_path.clear()
	if could_occupy_empty_city():
		path_class += 1
		#TODO 行动
		start_occupation_process()
	else:
		state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.SEARCHING_EMPTYCITY)
#TODO 城市占领队列按占领难度（路径长度）优先队列排序
func could_occupy_empty_city() -> bool:
	for target_point in Not_Occupy:
		var cell: CellInfo = agent.player_map.get_cell(target_point)
		var demand: int = cell.get_power()
		var path = agent.search_algorithm.M2S_Search(target_point,demand,3,1,10,50)
		if path != [-1]:
			occupy_path = agent.search_algorithm.get_all_coords()
			return true
		else:
			pass
	return false

func start_occupation_process() -> void:
	agent.path_add.emit(path_class, occupy_path)
	#TODO 等待信号占领城市
	state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.EMPTYCITY_OCCUPY)
	pass	
