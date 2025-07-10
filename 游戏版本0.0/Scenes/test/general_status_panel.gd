extends Control

var general_id: int
var capital_pos: Vector2i
var general_entity: General_Entity

# UI元素引用
@onready var general_id_label: Label = $Panel/VBoxContainer/GeneralInfo/GeneralID
@onready var capital_pos_label: Label = $Panel/VBoxContainer/GeneralInfo/CapitalPos
@onready var current_agent_label: Label = $Panel/VBoxContainer/GeneralInfo/CurrentAgent

# Expansion Agent UI元素
@onready var jump_param_spinbox: SpinBox = $Panel/VBoxContainer/TabContainer/Expansion Agent/ExpansionSettings/M2S_Search_Params/JumpParam/JumpParamSpinBox
@onready var estimated_demand_spinbox: SpinBox = $Panel/VBoxContainer/TabContainer/Expansion Agent/ExpansionSettings/M2S_Search_Params/EstimatedDemand/EstimatedDemandSpinBox
@onready var range_threshold_spinbox: SpinBox = $Panel/VBoxContainer/TabContainer/Expansion Agent/ExpansionSettings/M2S_Search_Params/RangeThreshold/RangeThresholdSpinBox

# Defence Agent UI元素
@onready var auto_hunt_defend_checkbox: CheckBox = $Panel/VBoxContainer/TabContainer/Defence Agent/DefenceSettings/Defence_Params/AutoHuntDefend/AutoHuntDefendCheckBox
@onready var demand_param_spinbox: SpinBox = $Panel/VBoxContainer/TabContainer/Defence Agent/DefenceSettings/Defence_Params/DemandParam/DemandParamSpinBox
@onready var range_threshold_defence_spinbox: SpinBox = $Panel/VBoxContainer/TabContainer/Defence Agent/DefenceSettings/Defence_Params/RangeThresholdDefence/RangeThresholdDefenceSpinBox

# 默认参数值
var default_expansion_params = {
	"jump_param": 20,
	"estimated_demand": 30,
	"range_threshold": 50
}

var default_defence_params = {
	"auto_hunt_defend": false,
	"demand_param": 1.0,
	"range_threshold": 50
}

func _ready() -> void:
	# 设置背景点击关闭
	$Background.gui_input.connect(_on_background_input)

func setup_panel(_general_id: int, _capital_pos: Vector2i, _general_entity: General_Entity) -> void:
	general_id = _general_id
	capital_pos = _capital_pos
	general_entity = _general_entity
	
	# 更新基本信息
	general_id_label.text = "General ID: " + str(general_id)
	capital_pos_label.text = "Capital Position: " + str(capital_pos)
	current_agent_label.text = "Current Agent: " + general_entity.current_agent
	
	# 加载当前参数
	load_current_parameters()
	
	# 根据当前agent显示对应标签页
	var tab_container = $Panel/VBoxContainer/TabContainer
	if general_entity.current_agent == "Expansion":
		tab_container.current_tab = 0
	else:
		tab_container.current_tab = 1

func load_current_parameters() -> void:
	# 加载Expansion Agent参数
	if general_entity.Expansion_agent:
		var params = general_entity.Expansion_agent.get_parameters()
		jump_param_spinbox.value = params.get("jump_param", default_expansion_params.jump_param)
		estimated_demand_spinbox.value = params.get("estimated_demand", default_expansion_params.estimated_demand)
		range_threshold_spinbox.value = params.get("range_threshold", default_expansion_params.range_threshold)
	
	# 加载Defence Agent参数
	if general_entity.Defence_agent:
		var params = general_entity.Defence_agent.get_parameters()
		auto_hunt_defend_checkbox.button_pressed = params.get("auto_hunt_defend", default_defence_params.auto_hunt_defend)
		demand_param_spinbox.value = params.get("demand_param", default_defence_params.demand_param)
		range_threshold_defence_spinbox.value = params.get("range_threshold", default_defence_params.range_threshold)

func apply_parameters() -> void:
	# 应用Expansion Agent参数
	if general_entity.Expansion_agent:
		general_entity.Expansion_agent.set_parameters(
			jump_param_spinbox.value,
			estimated_demand_spinbox.value,
			range_threshold_spinbox.value
		)
	
	# 应用Defence Agent参数
	if general_entity.Defence_agent:
		general_entity.Defence_agent.set_parameters(
			auto_hunt_defend_checkbox.button_pressed,
			demand_param_spinbox.value,
			range_threshold_defence_spinbox.value
		)
	
	print("Parameters applied for General ", general_id)

func apply_expansion_parameters() -> void:
	# 这里需要修改ExpansionAgent的代码来支持参数设置
	# 暂时只打印参数值
	print("Expansion Agent Parameters:")
	print("  Jump Parameter: ", jump_param_spinbox.value)
	print("  Estimated Demand: ", estimated_demand_spinbox.value)
	print("  Range Threshold: ", range_threshold_spinbox.value)

func apply_defence_parameters() -> void:
	# 这里需要修改DefenceAgent的代码来支持参数设置
	# 暂时只打印参数值
	print("Defence Agent Parameters:")
	print("  Auto Hunt Defend: ", auto_hunt_defend_checkbox.button_pressed)
	print("  Demand Parameter: ", demand_param_spinbox.value)
	print("  Range Threshold: ", range_threshold_defence_spinbox.value)

func reset_to_default() -> void:
	# 重置Expansion Agent参数
	jump_param_spinbox.value = default_expansion_params.jump_param
	estimated_demand_spinbox.value = default_expansion_params.estimated_demand
	range_threshold_spinbox.value = default_expansion_params.range_threshold
	
	# 重置Defence Agent参数
	auto_hunt_defend_checkbox.button_pressed = default_defence_params.auto_hunt_defend
	demand_param_spinbox.value = default_defence_params.demand_param
	range_threshold_defence_spinbox.value = default_defence_params.range_threshold
	
	print("Parameters reset to default for General ", general_id)

func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		queue_free()

func _on_close_button_pressed() -> void:
	queue_free()

func _on_apply_button_pressed() -> void:
	apply_parameters()

func _on_reset_button_pressed() -> void:
	reset_to_default() 