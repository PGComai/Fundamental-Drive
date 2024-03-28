extends Control


const ITEMS = ["Road", "Spring Plate"]
const PLACEABLE_ROAD = preload("res://scenes/placeable_road.tscn")
const PLACEABLE_SPRING_PLATE = preload("res://scenes/placeable_spring_plate.tscn")


signal create_item(item: Resource)


var global: Node

var item_idx: int = 0
var item_list: Array[Resource] = [PLACEABLE_ROAD, PLACEABLE_SPRING_PLATE]


@onready var h_box_container_selector = $HBoxContainerSelector
@onready var label_item_selector = $HBoxContainerSelector/LabelItemSelector
@onready var reticle = $Reticle
@onready var info_box_road = $VBoxContainerInfoBoxes/InfoBoxRoad
@onready var info_box_road_point = $VBoxContainerInfoBoxes/InfoBoxRoadPoint



# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.player_state_changed.connect(_on_global_player_state_changed)
	global.show_reticle.connect(_on_global_show_reticle)
	global.object_selected.connect(_on_global_object_selected)
	global.object_edited.connect(_on_global_object_edited)
	global.edited_modified.connect(_on_global_edited_modified)
	global.road_point_selected.connect(_on_global_road_point_selected)
	global.road_point_modified.connect(_on_global_road_point_modified)
	h_box_container_selector.visible = false
	info_box_road.visible = false
	info_box_road_point.visible = false


func _unhandled_input(event):
	if event.is_action_pressed("build toggle items") and global.player_state == 1:
		#global.item_select = not global.item_select
		global.player_state = 4
	elif event.is_action_pressed("build toggle items") and global.player_state == 4:
		global.player_state = 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global.player_state == 4:
		if Input.is_action_just_pressed("left"):
			item_idx = wrapi(item_idx - 1, 0, ITEMS.size())
			print(item_idx)
			label_item_selector.text = ITEMS[item_idx]
		if Input.is_action_just_pressed("right"):
			item_idx = wrapi(item_idx + 1, 0, ITEMS.size())
			print(item_idx)
			label_item_selector.text = ITEMS[item_idx]
		if Input.is_action_just_pressed("select"):
			global.create_item = item_list[item_idx]


func _on_global_player_state_changed(state: String):
	h_box_container_selector.visible = state == "Browsing"
	if state == "Browsing":
		label_item_selector.text = ITEMS[item_idx]


func _on_global_show_reticle(status: bool):
	reticle.visible = status


func _on_global_object_selected(obj: PlaceableObject):
	if obj:
		info_box_road.visible = obj.object_type == 1
		if obj.object_type == 1:
			var stats = obj.get_stats()
			info_box_road.stat_box_road_points.stat_value = str(stats["NumPoints"])
			info_box_road.stat_box_road_dim_x.stat_value = str(stats["SizeX"])
			info_box_road.stat_box_road_dim_y.stat_value = str(stats["SizeY"])
			info_box_road.stat_box_road_dim_z.stat_value = str(stats["SizeZ"])
	elif not global.currently_edited_object:
		info_box_road.visible = false


func _on_global_object_edited(obj: PlaceableObject):
	if obj:
		info_box_road.visible = obj.object_type == 1
		if obj.object_type == 1:
			var stats = obj.get_stats()
			info_box_road.stat_box_road_points.stat_value = str(stats["NumPoints"])
			info_box_road.stat_box_road_dim_x.stat_value = str(stats["SizeX"])
			info_box_road.stat_box_road_dim_y.stat_value = str(stats["SizeY"])
			info_box_road.stat_box_road_dim_z.stat_value = str(stats["SizeZ"])
	elif not global.currently_selected_object:
		info_box_road.visible = false


func _on_global_edited_modified():
	if global.currently_edited_object:
		var obj = global.currently_edited_object
		if obj.object_type == 1:
			var stats = obj.get_stats()
			info_box_road.stat_box_road_points.stat_value = str(stats["NumPoints"])
			info_box_road.stat_box_road_dim_x.stat_value = str(stats["SizeX"])
			info_box_road.stat_box_road_dim_y.stat_value = str(stats["SizeY"])
			info_box_road.stat_box_road_dim_z.stat_value = str(stats["SizeZ"])


func _on_global_road_point_selected(point: PlaceableRoadPoint):
	if point:
		info_box_road_point.visible = true
		var stats = point.get_stats()
		info_box_road_point.stat_box_idx.stat_value = str(stats["Idx"])
		info_box_road_point.stat_box_vector_pos._set_vector(stats["Pos"])
		info_box_road_point.stat_box_vector_fwd._set_vector(stats["Fwd"])
		info_box_road_point.stat_box_vector_up._set_vector(stats["Up"])
		info_box_road_point.stat_box_curve_size.stat_value = str(stats["CurveSize"])
	else:
		info_box_road_point.visible = false


func _on_global_road_point_modified():
	if global.currently_selected_road_point:
		var stats = global.currently_selected_road_point.get_stats()
		info_box_road_point.stat_box_idx.stat_value = str(stats["Idx"])
		info_box_road_point.stat_box_vector_pos._set_vector(stats["Pos"])
		info_box_road_point.stat_box_vector_fwd._set_vector(stats["Fwd"])
		info_box_road_point.stat_box_vector_up._set_vector(stats["Up"])
		info_box_road_point.stat_box_curve_size.stat_value = str(stats["CurveSize"])
