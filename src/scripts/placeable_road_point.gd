extends Node3D
class_name PlaceableRoadPoint


const PRP_WIDGET = preload("res://scenes/prp_widget.tscn")
const MODES = ["None", "Selected"]


signal widget_ready(item)


@export_enum("test", "Road Point") var object_type = 0


var widget: Node3D
var mode: int = 0:
	set(value):
		mode = clampi(value, 0, MODES.size() - 1)
		_mode_set()
var parent_placeable_object: PlaceableObject
var parent_road: RoadPath:
	set(value):
		parent_road = value
		_parent_road_set()
var road_curve_idx: int:
	set(value):
		road_curve_idx = value
		_idx_set()
var curve_size: float = 10.0

var global: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.player_state_changed.connect(_on_global_player_state_changed)
	var new_widget = PRP_WIDGET.instantiate()
	add_child(new_widget)
	widget = new_widget
	widget.ref = self
	widget.visible = global.player_state == 3
	emit_signal("widget_ready", self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if widget:
		widget.global_position = global_position


func _mode_set():
	if MODES[mode] == "None":
		if widget:
			widget.move = false
			widget.edit = false
	elif MODES[mode] == "Selected":
		if widget:
			widget.move = true
			widget.edit = false


func _on_global_player_state_changed(state: String):
	if widget:
		widget.visible = state == "Editing"


func _parent_road_set():
	road_curve_idx = parent_road.placeable_points.size()
	parent_road.placeable_points.append(self)
	parent_road._placeable_points_set()


func _idx_set():
	if widget:
		widget.idx.mesh.text = str(road_curve_idx + 1)
