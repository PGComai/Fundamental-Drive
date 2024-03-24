extends Node3D


@onready var mesh_highlight_origin = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/MeshHighlightOrigin
@onready var mesh_highlight_origin_edit = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/MeshHighlightOriginEdit
@onready var object_name = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/ObjectName


var ref: Node3D
var move := false:
	set(value):
		move = value
		_move_mode_set()
var edit := false:
	set(value):
		edit = value
		_edit_set()


# Called when the node enters the scene tree for the first time.
func _ready():
	mesh_highlight_origin.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _move_mode_set():
	mesh_highlight_origin.visible = move


func _edit_set():
	mesh_highlight_origin_edit.visible = edit


func _set_object_name(name_text: String):
	object_name.mesh.text = name_text
