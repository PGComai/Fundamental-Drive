extends MeshInstance3D

@export_enum("FL", "FR", "BL", "BR") var mode

var node_holder: Node
var waiting_for_player := true
var player_node: Node3D
var lerp_speed := 0.1
var material: Material


# Called when the node enters the scene tree for the first time.
func _ready():
	node_holder = get_node("/root/NodeHolder")
	node_holder.player_node_set.connect(_on_player_node_set)
	if node_holder.cam_x_form_node:
		waiting_for_player = false
		player_node = node_holder.player_node
	material = get_surface_override_material(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if player_node:
		var px = player_node.chassis.global_position.x
		var pz = player_node.chassis.global_position.z
		var y = -100.0
		global_position = Vector3(px, y, pz)


func _on_player_node_set(toggle):
	if waiting_for_player and toggle:
		player_node = node_holder.player_node
		waiting_for_player = false
	if not toggle:
		player_node = null
		waiting_for_player = true


func _on_car_velocity(vel: Vector3):
	if vel.is_zero_approx() or vel.normalized().is_equal_approx(Vector3.DOWN):
		pass
	else:
		pass#rotate_object_local(Vector3.DOWN.cross(vel).normalized(), 0.01)


func _on_car_position_signal(pos):
	pass # Replace with function body.
