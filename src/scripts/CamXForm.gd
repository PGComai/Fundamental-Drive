extends Node3D


var node_holder: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	node_holder = get_node("/root/NodeHolder")
	node_holder.cam_x_form_node = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
