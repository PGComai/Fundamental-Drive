extends Node3D


@onready var mesh_highlight_origin = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/MeshHighlightOrigin
@onready var idx = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/Idx


var ref: Node3D
var move := false:
	set(value):
		move = value
		_move_mode_set()

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh_highlight_origin.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _move_mode_set():
	mesh_highlight_origin.visible = move

