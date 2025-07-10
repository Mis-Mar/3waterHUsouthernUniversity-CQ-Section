extends Node
class_name Player_Entity

var player_id: int
var general_id_list: Array[int]

var general : Dictionary #general_id to general_entity
var frontline_zone : Array[Vector2i]

#存储所有的generalid of player
var player_map: PlayerMap
var path_operations: Dictionary

var is_path_manager_working:bool = false

signal general_path_output(general_id: int, path_operate: Array)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#general_occupy.emit()
	pass # Replace with function body.

func _init(_player_id: int, _player_map: PlayerMap) -> void:
	self.player_id = _player_id
	self.player_map = _player_map

func appoint_general(general_id: int) -> void:
	general[general_id] = General_Entity.new(general_id,player_id,player_map)
	general[general_id].player = self
	#其余动态分派工作

func path_manager() -> void:
	self.is_path_manager_working = true
	while not path_operations.is_empty():
		for general_id in player_map.get_generals_of_player(player_id):
			#FIXME 传递操作信号：path_operations[general_id].pop_front()
			pass
		await player_map.turn_updated
	self.is_path_manager_working = false

func on_general_path_added(general_id: int, path_operate: Array) -> void:
	path_operations[general_id].append(path_operate)
	if not self.is_path_manager_working:
		path_manager()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
