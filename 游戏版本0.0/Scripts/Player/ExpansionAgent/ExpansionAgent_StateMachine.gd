class_name ExpansionAgent_StateMachine
extends Node

enum ExpansionAgent_State {
	SEARCHING_EMPTYCITY,
	EMPTYCITY_OCCUPY,
	EXPANSION_COMPLETE
}

var initial_state: ExpansionAgent_State = ExpansionAgent_State.SEARCHING_EMPTYCITY
var current_state: BaseState_ExpansionAgent
var player_id: int
var agent: ExpansionAgent
var states: Dictionary

func _init(_agent:ExpansionAgent) -> void:
	agent=_agent
	# 初始化所有状态
	states = {} # 确保字典被初始化
	states[ExpansionAgent_State.SEARCHING_EMPTYCITY] = State_SearchingEmptycity.new(agent)
	states[ExpansionAgent_State.EMPTYCITY_OCCUPY] = State_EmptycityOccupy.new(agent)
	states[ExpansionAgent_State.EXPANSION_COMPLETE] = State_ExpansionComplete.new(agent)
	
	# 设置状态机引用
	for state in states.values():
		state.state_machine = self
	print("27")
	# 进入初始状态
	# self.transition_to(initial_state)
	
func transition_to(new_state_key: ExpansionAgent_State) -> void:
	if current_state:
		current_state.exit()
	
	#print(states)
	current_state = states[new_state_key]
	
	
	current_state.enter()
	
# 主更新循环
func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
