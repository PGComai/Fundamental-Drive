extends Control


const ITEMS = ["Road"]
const PLACEABLE_ROAD = preload("res://scenes/placeable_road.tscn")


signal create_item(item: Resource)


var global: Node

var item_idx: int = 0


@onready var h_box_container_selector = $HBoxContainerSelector
@onready var label_item_selector = $HBoxContainerSelector/LabelItemSelector


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.player_state_changed.connect(_on_global_player_state_changed)
	h_box_container_selector.visible = false


func _unhandled_input(event):
	if event.is_action_pressed("build toggle items") and global.player_state == 1:
		#global.item_select = not global.item_select
		global.player_state = 4
	elif event.is_action_pressed("build toggle items") and global.player_state == 4:
		global.player_state = 1
	elif global.player_state == 4:
		if event.is_action_pressed("left"):
			item_idx = wrapi(item_idx - 1, 0, ITEMS.size() - 1)
			label_item_selector.text = ITEMS[item_idx]
		if event.is_action_pressed("right"):
			item_idx = wrapi(item_idx + 1, 0, ITEMS.size() - 1)
			label_item_selector.text = ITEMS[item_idx]
		if event.is_action_pressed("jump"):
			emit_signal("create_item", PLACEABLE_ROAD)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_global_player_state_changed(state: String):
	h_box_container_selector.visible = state == "Browsing"
	if state == "Browsing":
		label_item_selector.text = ITEMS[item_idx]
