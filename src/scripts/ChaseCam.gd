extends Node3D


const SENS = 0.002
const SENS_JOY = 0.03
const OBJ_ROT_SENS = 0.1


var node_holder: Node
var waiting_for_xform_target := true
var xform_node: Node3D
var lerp_speed := 0.2
var look_at_pos: Vector3

var rot_h := 0.0
var rot_v := 0.0:
	set(value):
		rot_v = clampf(value, -15.0*PI/32.0, 15.0*PI/32.0)
var build_speed_multiplier := 1.0
var selected_object: PlaceableObject:
	set(value):
		selected_object = value
		_selected_object_selected()
var selected_object_move_mode := "free"
var object_rotation := false

var global: Node

@onready var build_ux = $BuildUX
@onready var spring_arm_3d = $SpringArm3D
@onready var cam = $SpringArm3D/Cam
@onready var ray_cast_3d = $SpringArm3D/Cam/RayCast3D
@onready var ray_cast_3d_handle = $SpringArm3D/Cam/RayCast3DHandle


# Called when the node enters the scene tree for the first time.
func _ready():
	build_ux.visible = false
	global = get_node("/root/Global")
	node_holder = get_node("/root/NodeHolder")
	node_holder.cam_x_form_node_set.connect(_on_cam_x_form_node_set)
	if node_holder.cam_x_form_node:
		waiting_for_xform_target = false
		xform_node = node_holder.cam_x_form_node


func _unhandled_input(event):
	if global.build_mode:
		if event is InputEventMouseMotion:
			rot_h -= event.relative.x * SENS
			rot_v -= event.relative.y * SENS
		
		if event.is_action_pressed("select") and ray_cast_3d.is_colliding() and not selected_object:
			var collider: Node = ray_cast_3d.get_collider()
			selected_object = collider.get_parent().ref
			selected_object_move_mode = collider.get_meta("move_mode")
			selected_object.widget.move_mode = selected_object_move_mode
		elif event.is_action_pressed("select") and selected_object:
			selected_object.widget.move_mode = "none"
			selected_object = null
		
		if event.is_action_pressed("rotate_object") and selected_object:
			object_rotation = true
		elif event.is_action_released("rotate_object"):
			object_rotation = false
		
		if event.is_action_pressed("select") and ray_cast_3d_handle.is_colliding() and not selected_object:
			pass
		
	if event.is_action_pressed("build"):
		global.build_mode = not global.build_mode
		if global.build_mode:
			rot_h = rotation.y
			rot_v = rotation.x
			rotation = Vector3.ZERO
		else:
			if selected_object:
				selected_object.widget.move_mode = "none"
				selected_object = null
		spring_arm_3d.rotation = Vector3.ZERO
		build_ux.visible = global.build_mode


func _process(delta):
	if global.build_mode:
		if Input.is_action_pressed("buildmovefast"):
			build_speed_multiplier = lerp(build_speed_multiplier, 10.0, 0.1)
		elif Input.is_action_pressed("buildmoveslow"):
			build_speed_multiplier = lerp(build_speed_multiplier, 0.1, 0.1)
		else:
			build_speed_multiplier = lerp(build_speed_multiplier, 1.0, 0.1)
		
		var look_axis = Input.get_vector("buildjoylookleft", "buildjoylookright", "buildjoylookup", "buildjoylookdown")
		
		var updown = Input.get_axis("builddown", "buildup")
		
		var input_dir = Input.get_vector("buildleft", "buildright", "buildfwd", "buildback")
		if not object_rotation:
			if look_axis:
				rot_h -= look_axis.x * SENS_JOY
				rot_v -= look_axis.y * SENS_JOY
			
			rotation.y = rot_h
			spring_arm_3d.rotation.x = rot_v
			var travel_dir = (cam.global_transform.basis * Vector3(input_dir.x, updown, input_dir.y)).normalized()
			
			if travel_dir and not selected_object:
				global_position += travel_dir * 0.2 * build_speed_multiplier
			elif travel_dir:
				var movement_offset = travel_dir * 0.2 * build_speed_multiplier
				if selected_object_move_mode == "free":
					selected_object.global_position += movement_offset
				elif selected_object_move_mode == "x":
					selected_object.global_position.x += movement_offset.x
				elif selected_object_move_mode == "y":
					selected_object.global_position.y += movement_offset.y
				elif selected_object_move_mode == "z":
					selected_object.global_position.z += movement_offset.z
				global_position = selected_object.global_position
		elif selected_object:
			selected_object.orthonormalize()
			# twist is input_dir.x
			# rotate y = look_axis.x
			# rotate x = look_axis.y
			# how do i get the closest local axis from the view transform?
			if abs(look_axis.x) > abs(look_axis.y):
				rotate_selected_object_y(look_axis.x)
			elif abs(look_axis.x) < abs(look_axis.y):
				rotate_selected_object_x(look_axis.y)
			elif abs(input_dir.x) > 0.0:
				rotate_selected_object_z(-input_dir.x)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if xform_node and not global.build_mode:
		rot_h = lerp(rot_h, 0.0, 0.1)
		rot_v = lerp(rot_v, 0.0, 0.1)
		lerp_speed = global_position.distance_squared_to(xform_node.global_position)
		lerp_speed = clamp(lerp_speed, 50.0, 100.0)
		lerp_speed = remap(lerp_speed, 50.0, 100.0, 0.1, 0.3)
		global_position = global_position.slerp(xform_node.global_position, lerp_speed)
		look_at(look_at_pos + (Vector3.UP * 1.0), Vector3.UP)


func rotate_selected_object_y(rot_amount: float):
	if selected_object.global_basis.x.angle_to(cam.global_basis.y) < PI/4.0:
		selected_object.rotate(selected_object.global_basis.x, rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.x.angle_to(cam.global_basis.y) > 3.0 * PI/4.0:
		selected_object.rotate(selected_object.global_basis.x, -rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.y.angle_to(cam.global_basis.y) < PI/4.0:
		selected_object.rotate(selected_object.global_basis.y, rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.y.angle_to(cam.global_basis.y) > 3.0 * PI/4.0:
		selected_object.rotate(selected_object.global_basis.y, -rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.z.angle_to(cam.global_basis.y) < PI/4.0:
		selected_object.rotate(selected_object.global_basis.z, rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.z.angle_to(cam.global_basis.y) > 3.0 * PI/4.0:
		selected_object.rotate(selected_object.global_basis.z, -rot_amount * OBJ_ROT_SENS)


func rotate_selected_object_x(rot_amount: float):
	if selected_object.global_basis.x.angle_to(cam.global_basis.x) < PI/4.0:
		selected_object.rotate(selected_object.global_basis.x, rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.x.angle_to(cam.global_basis.x) > 3.0 * PI/4.0:
		selected_object.rotate(selected_object.global_basis.x, -rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.y.angle_to(cam.global_basis.x) < PI/4.0:
		selected_object.rotate(selected_object.global_basis.y, rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.y.angle_to(cam.global_basis.x) > 3.0 * PI/4.0:
		selected_object.rotate(selected_object.global_basis.y, -rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.z.angle_to(cam.global_basis.x) < PI/4.0:
		selected_object.rotate(selected_object.global_basis.z, rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.z.angle_to(cam.global_basis.x) > 3.0 * PI/4.0:
		selected_object.rotate(selected_object.global_basis.z, -rot_amount * OBJ_ROT_SENS)


func rotate_selected_object_z(rot_amount: float):
	if selected_object.global_basis.x.angle_to(cam.global_basis.z) < PI/4.0:
		selected_object.rotate(selected_object.global_basis.x, rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.x.angle_to(cam.global_basis.z) > 3.0 * PI/4.0:
		selected_object.rotate(selected_object.global_basis.x, -rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.y.angle_to(cam.global_basis.z) < PI/4.0:
		selected_object.rotate(selected_object.global_basis.y, rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.y.angle_to(cam.global_basis.z) > 3.0 * PI/4.0:
		selected_object.rotate(selected_object.global_basis.y, -rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.z.angle_to(cam.global_basis.z) < PI/4.0:
		selected_object.rotate(selected_object.global_basis.z, rot_amount * OBJ_ROT_SENS)
	elif selected_object.global_basis.z.angle_to(cam.global_basis.z) > 3.0 * PI/4.0:
		selected_object.rotate(selected_object.global_basis.z, -rot_amount * OBJ_ROT_SENS)


func _selected_object_selected():
	if selected_object:
		global_position = selected_object.global_position
		spring_arm_3d.spring_length = 10.0
	else:
		global_position = cam.global_position
		spring_arm_3d.spring_length = 0.0


func _on_cam_x_form_node_set(toggle):
	if waiting_for_xform_target and toggle:
		xform_node = node_holder.cam_x_form_node
		waiting_for_xform_target = false
	if not toggle:
		xform_node = null
		waiting_for_xform_target = true


func _on_car_position_signal(pos):
	look_at_pos = pos
