extends Node2D  
@onready var grid_container: GridContainer = $GridContainer



const CELL_WIDTH := 120
const CELL_HEIGHT := 30
const FONT_SIZE := 25

var cell_alpha: float = 0.7  # 透明度

func _ready() -> void:
	pass

func populate_table(
	general_total_power: Dictionary,
	general_id_to_player_id: Dictionary
) -> void:
	grid_container.columns = 3
	clear_children()

	# 添加表头
	_add_cell("GeneralID", Color.SILVER)
	_add_cell("PlayerID", Color.SILVER)
	_add_cell("TotalPower", Color.SILVER)

	for general_id in general_total_power.keys():
		var player_id = general_id_to_player_id.get(general_id, -1)
		var total_power = general_total_power[general_id]

		var cell_color: Color = Color.WHITE
		if Global.general_id_to_color.has(general_id):
			cell_color = Global.general_id_to_color[general_id]

		_add_cell(str(general_id), cell_color)
		_add_cell(str(player_id), cell_color)
		_add_cell(str(total_power), cell_color)

func _add_cell(text: String, bg_color: Color) -> void:
	var panel = Panel.new()
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(bg_color.r, bg_color.g, bg_color.b, cell_alpha)
	stylebox.set_border_width(SIDE_LEFT, 1)
	stylebox.set_border_width(SIDE_TOP, 1)
	stylebox.set_border_width(SIDE_RIGHT, 1)
	stylebox.set_border_width(SIDE_BOTTOM, 1)
	stylebox.border_color = Color.DARK_GRAY

	panel.set("theme_override_styles/panel", stylebox)
	panel.custom_minimum_size = Vector2(CELL_WIDTH, CELL_HEIGHT)

	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color.BLACK)

	panel.add_child(label)
	grid_container.add_child(panel)

func clear_children() -> void:
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()
