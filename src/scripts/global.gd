extends Node


const PLAYER_STATES = ["Driving", "Building", "Selecting", "Editing", "Browsing"]


signal player_state_changed(state: String)
signal show_reticle(status: bool)
signal object_selected(obj: PlaceableObject)
signal object_edited(obj: PlaceableObject)
signal edited_modified
signal road_point_selected(point: PlaceableRoadPoint)
signal road_point_modified
signal player_create_item(item: Resource)
signal camera_type_changed


var last_player_state: String
var player_state: int = 0:
	set(value):
		last_player_state = PLAYER_STATES[player_state]
		player_state = value
		emit_signal("player_state_changed", PLAYER_STATES[player_state])
		print("player state changed: %s" % PLAYER_STATES[player_state])
var player_has_object_selected := false
var player_is_editing_object := false
var player_needs_reticle := false:
	set(value):
		player_needs_reticle = value
		emit_signal("show_reticle", player_needs_reticle)
var currently_selected_object: PlaceableObject:
	set(value):
		currently_selected_object = value
		emit_signal("object_selected", currently_selected_object)
var currently_selected_road_point: PlaceableRoadPoint:
	set(value):
		currently_selected_road_point = value
		emit_signal("road_point_selected", currently_selected_road_point)
var currently_edited_object: PlaceableObject:
	set(value):
		currently_edited_object = value
		emit_signal("object_edited", currently_edited_object)
var edited_object_modified := false:
	set(value):
		if value:
			emit_signal("edited_modified")
var selected_road_point_modified := false:
	set(value):
		if value:
			emit_signal("road_point_modified")
var position_snap := false
var create_item: Resource:
	set(value):
		if value:
			emit_signal("player_create_item", value)
var camera_up := Vector3.UP
var camera_type: int = 0:
	set(value):
		camera_type = wrapi(value, 0, 3)
		print("camera type set: %s" % camera_type)
		emit_signal("camera_type_changed")
var camera_transform_node: Node3D

var sub_v: SubViewport


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _unhandled_input(event):
	if event.is_action_released("toggle snap"):
		position_snap = not position_snap


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
