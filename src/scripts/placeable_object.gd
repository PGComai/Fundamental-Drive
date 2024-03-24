extends Node3D
class_name PlaceableObject


const PO_WIDGET = preload("res://scenes/po_widget.tscn")
const PLACEABLE_ROAD_POINT = preload("res://scenes/placeable_road_point.tscn")
const MODES = ["None", "Selected", "Edited"]
const NAMES = ["test", "Road"]


signal widget_ready(item)


@export_enum("test", "Road") var object_type = 0


var widget: Node3D
var mode: int = 0:
	set(value):
		mode = clampi(value, 0, MODES.size() - 1)
		_mode_set()
var road: RoadPath

var global: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.player_state_changed.connect(_on_global_player_state_changed)
	if object_type == 1:
		road = get_child(0)
	var new_widget = PO_WIDGET.instantiate()
	add_child(new_widget)
	widget = new_widget
	widget.ref = self
	widget.visible = global.player_state != 0
	widget._set_object_name(NAMES[object_type])
	emit_signal("widget_ready", self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if widget:
		widget.global_position = global_position


func add_road_point(pos: Vector3):
	if road:
		var new_road_point = PLACEABLE_ROAD_POINT.instantiate()
		add_child(new_road_point)
		new_road_point.global_position = pos
		new_road_point.parent_placeable_object = self
		new_road_point.parent_road = road
		return new_road_point
	return null


func _mode_set():
	if MODES[mode] == "None":
		if widget:
			widget.move = false
			widget.edit = false
	elif MODES[mode] == "Selected":
		if widget:
			widget.move = true
			widget.edit = false
	elif MODES[mode] == "Edited":
		if widget:
			widget.move = false
			widget.edit = true


func _on_global_player_state_changed(state: String):
	if widget:
		widget.visible = state != "Driving"


func _delete():
	queue_free()
