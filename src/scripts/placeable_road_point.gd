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
var curve_size: float = 10.0:
	set(value):
		curve_size = clampf(value, 0.1, 200.0)
		_set_curve_size()
var tilt: float = 0.0
var position_already_set := false
var up_dir := Vector3.UP
var stats := {"Idx": 0,
				"Pos": Vector3.ZERO,
				"Fwd": Vector3.FORWARD,
				"Up": Vector3.UP,
				"CurveSize": 10.0}
var subpixel_position := Vector3.ZERO:
	set(value):
		subpixel_position = value
		_set_position()
var target_position := Vector3.ZERO
var chasing_target_position := false

var global: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.player_state_changed.connect(_on_global_player_state_changed)
	var new_widget = PRP_WIDGET.instantiate()
	add_child(new_widget)
	widget = new_widget
	widget.represent_values(curve_size)
	widget.ref = self
	emit_signal("widget_ready", self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global.position_snap and chasing_target_position:
		global_position = global_position.lerp(target_position, 0.1)
		if global_position.is_equal_approx(target_position):
			chasing_target_position = false
			global_position = target_position


func _set_position():
	if global.position_snap:
		target_position = subpixel_position.snapped(Vector3(1.0, 1.0, 1.0))
		chasing_target_position = true
	else:
		global_position = subpixel_position
		target_position = global_position


func _mode_set():
	if MODES[mode] == "None":
		if widget:
			widget.move = false
	elif MODES[mode] == "Selected":
		if widget:
			widget.move = true


func _on_global_player_state_changed(state: String):
	if widget:
		widget.visible = (state == "Editing"
						and parent_placeable_object.mode == 2)


func _parent_road_set():
	road_curve_idx = parent_road.placeable_points.size()
	parent_road.placeable_points.append(self)
	parent_road._placeable_points_set()
	widget.visible = (global.player_state == 3
					and parent_placeable_object.mode == 2)


func _idx_set():
	if widget:
		widget.idx.mesh.text = str(road_curve_idx + 1)


func _update():
	if parent_road:
		if parent_road.curve.point_count > 0:
			var local_point = parent_road.to_local(global_position)
			var closest_offset = parent_road.curve.get_closest_offset(local_point)
			up_dir = parent_road.curve.sample_baked_up_vector(closest_offset, true)
			widget.up_dir.look_at(widget.global_position + up_dir, global_basis.z)
			global.edited_object_modified = true
			global.selected_road_point_modified = true


func get_stats():
	if parent_road:
		stats["Idx"] = road_curve_idx + 1
		stats["Pos"] = position
		stats["Fwd"] = -global_basis.z
		stats["Up"] = up_dir
		stats["CurveSize"] = snappedf(curve_size, 0.1)
	return stats


func _set_curve_size():
	print(curve_size)
	widget.represent_values(curve_size)


func _delete():
	if parent_road:
		parent_road._delete_point(self)
