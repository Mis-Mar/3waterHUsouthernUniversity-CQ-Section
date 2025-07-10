extends BaseState_ExpansionAgent
class_name State_EmptycityOccupy

var Not_Occupy: Array[Vector2i]
var path_class: int = 1

var current_state: int = self.STATE_SLEEP

const STATE_SLEEP := 0
const STATE_ACT := 1

#TODO 再check状态机切换？
#TODO 强制停止：收到外部信号

func _ready() -> void:
	agent.general.general_occupy_city.connect(on_city_occupied)

func enter() -> void:
	super.enter()
	Not_Occupy = agent.Not_Occupy
	current_state = self.STATE_SLEEP
	to_occupy_city()

func to_occupy_city() -> void:
	self.current_state = self.STATE_ACT
	while not Not_Occupy.is_empty():
		if self.current_state != self.STATE_ACT:
			break 
		if not occupy_empty_city():
			if agent.Not_Found.is_empty():
				await agent.player_map.turn_updated
			else:
				break
	self.current_state = self.STATE_SLEEP
	end_to_searching()

func occupy_empty_city() -> bool:
	self.current_state = self.STATE_ACT
	var path_all: Dictionary = {}
	var min_path_city_id: int = -1
	for target_city in Not_Occupy:
		var target_city_id: int = agent.player_map.city_position_to_id[target_city]
		path_all[target_city_id] = could_occupy_empty_city(target_city)
		if path_all[target_city_id] != [-1]:
			if min_path_city_id == -1 or path_all[target_city_id].size() < path_all[min_path_city_id].size():
				min_path_city_id = target_city_id
	if self.current_state != self.STATE_ACT:
		return false
	if min_path_city_id != -1:
		path_class = min_path_city_id
		agent.path_add.emit(path_class, path_all[min_path_city_id])
		return true
	else:
		return false

func could_occupy_empty_city(target_point:Vector2i) -> Array:
	self.current_state = self.STATE_ACT
	var cell: CellInfo = agent.player_map.get_cell(target_point)
	var demand: int = cell.get_power()
	var path = agent.search_algorithm.M2S_Search(target_point,demand,3,1,10,50)
	#HACK 待完成 参数设置
	if path != [-1]:
		path = agent.search_algorithm.get_path_action()
		if self.current_state != self.STATE_ACT:
			return [-1]
		return path
	else:
		return [-1]

func end_to_searching() -> void:
	self.current_state = self.STATE_SLEEP
	state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.SEARCHING_EMPTYCITY)

func on_city_occupied(cityid:int,citypos:Vector2i,enemy_general_id:int) -> void:
	Not_Occupy.erase(citypos)
	if self.current_state == self.STATE_SLEEP:
		to_occupy_city()
	else:
		pass
