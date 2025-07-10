extends BaseState_ExpansionAgent
class_name State_ExpansionComplete

func _init(_agent:ExpansionAgent) -> void:
	agent=_agent

func enter() -> void:
	super.enter()
	agent.general.switch_to_Defence_pattern.emit()
	#TODO 补充close相关方法?
