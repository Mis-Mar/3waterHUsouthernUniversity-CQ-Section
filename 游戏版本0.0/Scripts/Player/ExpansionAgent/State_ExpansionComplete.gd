extends BaseState_ExpansionAgent
class_name State_ExpansionComplete

func enter() -> void:
	agent.general.switch_to_Defence_pattern.emit()
	#TODO 补充close相关方法
