extends Node


signal build_mode_toggle(state: bool)


var build_mode := false:
	set(value):
		build_mode = value
		emit_signal("build_mode_toggle", value)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass