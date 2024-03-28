extends Node3D


var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.camera_type_changed.connect(_on_global_camera_type_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_global_camera_type_changed():
	if global.camera_type == 0:
		pass
	elif global.camera_type == 1:
		pass
	elif global.camera_type == 2:
		global.camera_transform_node = self
