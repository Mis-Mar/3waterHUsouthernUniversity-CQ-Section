extends Node2D

@onready var button: Button = $UI/Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	leave_room()
	pass # Replace with function body.

# 离开房间,切换回prepare场景
func leave_room()->void:
	reset_multiplayer()
	var err = get_tree().change_scene_to_file("res://Scenes/game_multi/prepare.tscn")
	if err != OK:
		print("切换场景失败，错误码: ", err)

# 重置连接器，出错就要调用
func reset_multiplayer()->void:
	multiplayer.multiplayer_peer = null
