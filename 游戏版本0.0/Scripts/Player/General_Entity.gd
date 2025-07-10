extends Node
class_name General_Entity

var Expansion_agent: ExpansionAgent
var Defence_agent: DefenceAgent

var general_id: int
var main_city: Vector2i
var city_id_of_general: Array
var player_id: int
var player: Player_Entity
var player_map: PlayerMap

var current_agent: String

var path_operations_EA: Array
var path_operations_DA: Array
var zone_of_general: Array[Vector2i]
var point_of_general: Array[Vector2i]
var edge_of_general: int = 0
var full_power_of_general: int
var mean_power_of_general: float
var Variance : float
var connection_degree : float

var city_id_in_zone : Array[int]
var crucial_point_list : Array[Vector2i]
var crucial_point_of_general : Array[Vector2i]

var is_path_manager_working: bool = false

signal agent_path_output(agent_type: String, path_operate: Array)
signal switch_to_Defence_pattern()
signal switch_to_Expansion_pattern()

signal general_find_city(cityid:int,citypos:Vector2i)
signal general_occupy_cell(pos:Vector2i,_cell_info:CellInfo,enemy_general_id:int)
signal general_occupy_city(cityid:int,citypos:Vector2i,enemy_general_id:int)
signal general_be_occupied_cell(pos:Vector2i,_cell_info:CellInfo,enemy_general_id:int)
signal general_be_occupied_city(cityid:int,citypos:Vector2i,enemy_general_id:int)


func _ready() -> void:
	pass

func _init(_general_id: int,  _player_id: int, _player_map: PlayerMap) -> void:
	self.general_id = _general_id
	self.player_id = _player_id
	self.player_map = _player_map
	self.main_city = player_map.general_to_capital[self.general_id]
	self.city_id_of_general = player_map.city_id_of_general[self.general_id]
	
	# 先创建agents
	Expansion_agent = ExpansionAgent.new(main_city, player_map,self)
	Expansion_agent.general = self
	Defence_agent = DefenceAgent.new(main_city, player_map,self)
	Defence_agent.general = self
	
	# 然后连接信号
	self.connect("agent_path_output", Callable(self, "on_path_add"))
	switch_to_Defence_pattern.connect(switch_to_Defence_agent)
	switch_to_Expansion_pattern.connect(switch_to_Expansion_agent)
	
	player_map.find_city.connect(on_find_city)
	player_map.occupy_cell.connect(on_occupy_cell)
	player_map.occupy_city.connect(on_occupy_city)
	player_map.be_occupied_cell.connect(on_be_occupied_cell)
	player_map.be_occupied_city.connect(on_be_occupied_city)
	pass
	
func _run() -> void:
	if player_id == 0:
		pass
	else:
		print("71")
		self.current_agent = Expansion_agent.agent_tpye
		Expansion_agent._run()


func switch_to_Defence_agent() -> void:
	self.current_agent = Defence_agent.agent_tpye
	Defence_agent.defend_class_trend()
	
func switch_to_Expansion_agent() -> void:
	self.current_agent = Expansion_agent.agent_tpye
	Expansion_agent._run()

func calculate_full_power() -> void:
	var power: int = 0
	for point in point_of_general:
		power += player_map.get_cell(point).get_power()
	full_power_of_general = power

func calculate_mean_power() -> void:
	var mean_power: float = self.full_power_of_general
	mean_power_of_general = mean_power / self.point_of_general.size()

func calculate_Morans_I() -> float:
	#莫兰指数
	
	var result: float
	var spatial_weight = 0.0
	var numerator = 0.0
	var denominator = 0.0

	for coord in self.point_of_general:
		
		var z_i = player_map.get_cell(coord).get_power() - mean_power_of_general
		denominator += z_i * z_i

		for neighbor in player_map.get_neighbors_state0(coord):
			if neighbor in point_of_general:
				var nz = player_map.get_cell(neighbor).get_power() - mean_power_of_general
				numerator += z_i * nz
				spatial_weight += 1

	if denominator == 0 or spatial_weight == 0:
		return 0.0
	
	self.Variance = denominator / point_of_general.size()
	result = (point_of_general.size() * numerator) / (spatial_weight * denominator)
	return result

func calculate_Standard_Deviation() -> float:
	#标准差
	var Standard_Deviation: float = 0.0
	for coord in self.point_of_general:
		var z_i = player_map.get_cell(coord).get_power() - mean_power_of_general
		Standard_Deviation += z_i * z_i
	Standard_Deviation /= self.point_of_general.size()
	self.Variance = Standard_Deviation
	Standard_Deviation = sqrt(Standard_Deviation)
	return Standard_Deviation

func calculate_connection_degree() -> float:
	#估价函数f(x)=((-(x (x-3)) (2010-(x+41.8)^(2)))/(356))
	var point_of_general_count: int = point_of_general.size()
	var x: float = edge_of_general
	x /= point_of_general_count
	var result: float = ( x * (x - 3) * ( (x + 41.8) ** 2 - 2010) ) / 356
	return result

func path_manager() -> void:
	self.is_path_manager_working = true
	if self.current_agent == Expansion_agent.agent_tpye:
		while !path_operations_EA.is_empty():
			var path = path_operations_EA.pop_front()
			player.general_path_output.emit(general_id,path)
			await player_map.turn_updated
	elif self.current_agent == Defence_agent.agent_tpye:
		while !path_operations_DA.is_empty():
			var path = path_operations_DA.pop_front()
			player.general_path_output.emit(general_id,path)
			await player_map.turn_updated
	self.is_path_manager_working = false

func on_path_add(agent_type:String, path_operate: Array) -> void:
	print("agent type",agent_type)
	if agent_type == Expansion_agent.agent_tpye:
		print("on_path_add==")
		path_operations_EA.append(path_operate)
	elif agent_type == Defence_agent.agent_tpye:
		path_operations_DA.append(path_operate)
	if not is_path_manager_working:
		path_manager()

func on_find_city(cityid:int,citypos:Vector2i,generalid:int) -> void:
	if generalid == self.general_id:
		general_find_city.emit(cityid,citypos)

func on_occupy_cell(pos:Vector2i,_cell_info:CellInfo,enemy_general_id:int,_general_id:int) -> void:
	if _general_id == self.general_id:
		general_occupy_cell.emit(pos,_cell_info,enemy_general_id)

func on_occupy_city(cityid:int,citypos:Vector2i,enemy_general_id:int,_general_id:int) -> void:
	if _general_id == self.general_id:
		general_occupy_city.emit(cityid,citypos,enemy_general_id)

func on_be_occupied_cell(pos:Vector2i,_cell_info:CellInfo,_general_id:int,enemy_general_id:int) -> void:
	if _general_id == self.general_id:
		general_be_occupied_cell.emit(pos,_cell_info,enemy_general_id)
	
func on_be_occupied_city(cityid:int,citypos:Vector2i,_general_id:int,enemy_general_id:int) -> void:
	if _general_id == self.general_id:
		general_be_occupied_city.emit(cityid,citypos,enemy_general_id)
