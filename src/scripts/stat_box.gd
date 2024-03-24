@tool
extends HBoxContainer
class_name StatBox


@export var stat_name: String = "Stat name":
	set(value):
		stat_name = value
		_set_stat_name()
@export var stat_value: String = "Stat value":
	set(value):
		stat_value = value
		_set_stat_value()


@onready var label = $Label
@onready var label_stat = $LabelStat


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _set_stat_name():
	if label:
		label.text = stat_name


func _set_stat_value():
	if label_stat:
		label_stat.text = stat_value
