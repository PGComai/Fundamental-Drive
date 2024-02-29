extends Node3D


@onready var mesh_highlight_x = $WidgetMoveX/CollisionShape3D/MeshInstance3D/MeshHighlightX
@onready var mesh_highlight_y = $WidgetMoveY/CollisionShape3D/MeshInstance3D/MeshHighlightY
@onready var mesh_highlight_z = $WidgetMoveZ/CollisionShape3D/MeshInstance3D/MeshHighlightZ
@onready var mesh_highlight_origin = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/MeshHighlightOrigin

@onready var mesh_hover_x = $WidgetMoveX/CollisionShape3D/MeshInstance3D/MeshHoverX
@onready var mesh_hover_y = $WidgetMoveY/CollisionShape3D/MeshInstance3D/MeshHoverY
@onready var mesh_hover_z = $WidgetMoveZ/CollisionShape3D/MeshInstance3D/MeshHoverZ
@onready var mesh_hover_origin = $WidgetMoveOrigin/CollisionShape3D/MeshInstance3D/MeshHoverOrigin

@onready var hover_timer = $HoverTimer


var ref: Node3D
var move_mode: String = "none":
	set(value):
		move_mode = value
		_move_mode_set()
var hover: String = "none":
	set(value):
		hover = value
		_hover_set()


# Called when the node enters the scene tree for the first time.
func _ready():
	mesh_highlight_origin.visible = false
	mesh_highlight_x.visible = false
	mesh_highlight_y.visible = false
	mesh_highlight_z.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _hover_set():
	if hover == "none":
		mesh_hover_origin.visible = false
		mesh_hover_x.visible = false
		mesh_hover_y.visible = false
		mesh_hover_z.visible = false
	elif hover == "free":
		mesh_hover_origin.visible = true
		hover_timer.start()
	elif hover == "x":
		mesh_hover_x.visible = true
		hover_timer.start()
	elif hover == "y":
		mesh_hover_y.visible = true
		hover_timer.start()
	elif hover == "z":
		mesh_hover_z.visible = true
		hover_timer.start()


func _move_mode_set():
	if move_mode == "none":
		mesh_highlight_origin.visible = false
		mesh_highlight_x.visible = false
		mesh_highlight_y.visible = false
		mesh_highlight_z.visible = false
	elif move_mode == "free":
		mesh_highlight_origin.visible = true
	elif move_mode == "x":
		mesh_highlight_x.visible = true
	elif move_mode == "y":
		mesh_highlight_y.visible = true
	elif move_mode == "z":
		mesh_highlight_z.visible = true


func _on_hover_timer_timeout():
	hover = "none"
