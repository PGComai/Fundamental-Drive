extends Node


signal cam_x_form_node_set(toggle)
signal player_node_set(toggle)


var cam_x_form_node: Node3D:
	set(value):
		cam_x_form_node = value
		if value:
			emit_signal("cam_x_form_node_set", true)
		else:
			emit_signal("cam_x_form_node_set", false)
var player_node: Node3D:
	set(value):
		player_node = value
		if value:
			emit_signal("player_node_set", true)
		else:
			emit_signal("player_node_set", false)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
