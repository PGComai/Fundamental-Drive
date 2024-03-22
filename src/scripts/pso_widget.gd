extends Node3D


@onready var mesh_highlight_origin = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/MeshHighlightOrigin
@onready var idx = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/Idx
@onready var up_dir = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/UpDir
@onready var dir = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/Dir
@onready var dir_cone = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/Dir/DirCone
@onready var dir_shadow = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/DirShadow
@onready var dir_shadow_cone = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/DirShadow/DirShadowCone



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


func represent_values(curve_size: float):
	dir.mesh.height = curve_size * 2.0
	dir_shadow.mesh.height = curve_size * 2.0
	dir_cone.position.y = curve_size
	dir_shadow_cone.position.y = curve_size
