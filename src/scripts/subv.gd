extends SubViewport


var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.sub_v = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
