extends BaseState_ExpansionAgent
class_name State_ExpansionComplete

func enter() -> void:
	self.switch_to_maintenance_agent()

func switch_to_maintenance_agent() -> void:
	pass
