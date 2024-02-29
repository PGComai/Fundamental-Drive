extends Node3D
class_name PlaceableObject


const PO_WIDGET = preload("res://scenes/po_widget.tscn")


@export_enum("test", "Road", "Road Point") var object_type = 0


var widget: Node3D
var selected := false

var global: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.build_mode_toggle.connect(_on_global_build_mode_toggle)
	var new_widget = PO_WIDGET.instantiate()
	add_child(new_widget)
	widget = new_widget
	widget.ref = self
	widget.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if widget:
		widget.global_position = global_position


func _on_global_build_mode_toggle(state: bool):
	if widget:
		widget.visible = state
