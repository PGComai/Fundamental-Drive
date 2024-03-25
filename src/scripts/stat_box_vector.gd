@tool
extends HBoxContainer
class_name StatBoxVector


@export var stat_name: String = "Stat name":
	set(value):
		stat_name = value
		_set_stat_name()


@onready var label = $Label
@onready var h_box_container_vector = $HBoxContainerVector


# Called when the node enters the scene tree for the first time.
func _ready():
	label.text = stat_name


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _set_stat_name():
	if label:
		label.text = stat_name


func _set_vector(value: Vector3):
	h_box_container_vector.vec = value
