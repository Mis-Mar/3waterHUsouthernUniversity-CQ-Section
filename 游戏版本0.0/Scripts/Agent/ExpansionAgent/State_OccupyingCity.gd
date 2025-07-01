extends BaseState_ExpansionAgent
class_name State_OccupyingCity

func enter():
	self.attempt_occupation()

func attempt_occupation() -> void:
	if can_occupy_city():
		state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.OCCUPYING_CITY_PROCESSING)
	else:
		state_machine.transition_to(ExpansionAgent_StateMachine.ExpansionAgent_State.SEARCHING_EMPTYCITY)

func can_occupy_city() -> bool:
	return true
