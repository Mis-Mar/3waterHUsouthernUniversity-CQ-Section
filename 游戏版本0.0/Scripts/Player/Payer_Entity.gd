extends Node

var player_id: int
var general_list: Array[int]
#存储所有的generalid of player
var player_map: PlayerMap
var path_operations: Array[Vector2i]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#general_occupy.emit()
	pass # Replace with function body.

func _init(_player_id: int, _player_map: PlayerMap) -> void:
	self.player_id = _player_id
	self.player_map = _player_map

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
