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
		if selected_object:
			selected_object.mode = 1
		_selected_object_selected()
var edited_object: PlaceableObject:
	set(value):
		edited_object = value
		if edited_object:
			edited_object.mode = 2
var selected_road_point: PlaceableRoadPoint:
	set(value):
		selected_road_point = value
		if selected_road_point:
			selected_road_point.mode = 1
var object_rotation := false
var magnet_node: Node3D
var magnet_enabled := false
var target_spring_length := 0.0
var just_placed_item := false


var global: Node

@onready var spring_arm_3d = $SpringArm3D
@onready var cam = $SpringArm3D/Cam
@onready var ray_cast_3d = $SpringArm3D/Cam/RayCast3D
@onready var ray_cast_3d_handle = $SpringArm3D/Cam/RayCast3DHandle
@onready var pos_fwd = $PosFwd
@onready var pos_left = $PosLeft
@onready var area_3d = $SpringArm3D/Cam/Area3D
@onready var car = $"../Car"


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	node_holder = get_node("/root/NodeHolder")
	node_holder.cam_x_form_node_set.connect(_on_cam_x_form_node_set)
	if node_holder.cam_x_form_node:
		waiting_for_xform_target = false
		xform_node = node_holder.cam_x_form_node


func _input(event):
	pass


func _process(delta):
	if (global.player_state == 1
		or global.player_state == 2
		or global.player_state == 3):
			if Input.is_action_pressed("rotate_object") and selected_object:
				object_rotation = true
			elif Input.is_action_just_released("rotate_object"):
				object_rotation = false
			
			if Input.is_action_pressed("buildmovefast"):
				build_speed_multiplier = lerp(build_speed_multiplier, 10.0, 0.1)
			elif Input.is_action_pressed("buildmoveslow"):
				build_speed_multiplier = lerp(build_speed_multiplier, 0.1, 0.1)
			else:
				build_speed_multiplier = lerp(build_speed_multiplier, 1.0, 0.1)
			
			var look_axis = Input.get_vector("buildjoylookleft", "buildjoylookright", "buildjoylookup", "buildjoylookdown")
			var updown = Input.get_axis("builddown", "buildup")
			var input_dir = Input.get_vector("buildleft", "buildright", "buildfwd", "buildback")
			
			var dir_to_center = -global_position.normalized()
			
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
					if selected_object:
						selected_object.global_position += movement_offset
			
			elif selected_object:
				selected_object.orthonormalize()
				if abs(look_axis.x) > abs(look_axis.y):
					rotate_selected_object_y(look_axis.x)
				elif abs(look_axis.x) < abs(look_axis.y):
					rotate_selected_object_x(look_axis.y)
				elif abs(input_dir.x) > 0.0:
					rotate_selected_object_z(-input_dir.x)
	
	if global.player_state == 2:
		global_position = global_position.lerp(selected_object.global_position, 0.4)
		if Input.is_action_just_pressed("build toggle items"):
			# SELECT -> EDIT HANDOFF
			print("editing object")
			edited_object = selected_object
			global.player_state = 3
			selected_object = null
	elif global.player_state == 3:
		if edited_object.object_type == 1:
			# currently editing road
			if Input.is_action_just_pressed("build toggle items"):
				edited_object.add_road_point(global_position - (cam.global_basis.z * 5.0))
		if Input.is_action_just_pressed("go back"):
			# EDIT -> SELECT HANDOFF
			print("exiting editing")
			selected_object = edited_object
			global.player_state = 2
			edited_object = null
		
	spring_arm_3d.spring_length = lerp(spring_arm_3d.spring_length, target_spring_length, 0.1)
	just_placed_item = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	area_3d.global_position = car.chassis.global_position
	
	if xform_node and global.player_state == 0:
		rot_h = lerp(rot_h, 0.0, 0.1)
		rot_v = lerp(rot_v, 0.0, 0.1)
		if not magnet_node:
			lerp_speed = global_position.distance_squared_to(xform_node.global_position)
			lerp_speed = clamp(lerp_speed, 50.0, 100.0)
			lerp_speed = remap(lerp_speed, 50.0, 100.0, 0.1, 0.3)
			global_position = global_position.slerp(xform_node.global_position, lerp_speed)
		else:
			global_position = global_position.slerp(magnet_node.global_position, 0.03)
		var up = Vector3.UP
		#var up = global_position.normalized()
		look_at(look_at_pos, up)
	
	elif (global.player_state == 1
		or global.player_state == 2):
		if (Input.is_action_just_pressed("select")
		and ray_cast_3d.is_colliding()
		and not selected_object):
			var collider: Node = ray_cast_3d.get_collider()
			selected_object = collider.get_parent().ref
			global.player_state = 2
		elif (Input.is_action_just_pressed("select")
		and selected_object
		and not just_placed_item):
			selected_object.mode = 0
			selected_object = null
			global.player_state = 1
		
		if (Input.is_action_just_pressed("select")
		and ray_cast_3d_handle.is_colliding()
		and not selected_object):
			pass


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
		selected_object.mode = 1
		print("selected")
		spring_arm_3d.spring_length = cam.global_position.distance_to(selected_object.global_position)
		print(spring_arm_3d.spring_length)
		target_spring_length = 10.0
	else:
		print("deselected")
		global_position = cam.global_position
		target_spring_length = 0.0


func _on_cam_x_form_node_set(toggle):
	if waiting_for_xform_target and toggle:
		xform_node = node_holder.cam_x_form_node
		waiting_for_xform_target = false
	if not toggle:
		xform_node = null
		waiting_for_xform_target = true


func _on_car_position_signal(pos):
	look_at_pos = pos


func _on_area_3d_area_entered(area):
	if area.is_in_group("magnet"):
		magnet_node = area.get_parent().cam_magnet


func _on_area_3d_area_exited(area):
	if area.is_in_group("magnet"):
		magnet_node = null


func _on_ux_build_time(toggle):
	if toggle:
		rot_h = rotation.y
		rot_v = rotation.x
		rotation = Vector3.ZERO
	else:
		if selected_object:
			selected_object.widget.move = false
			selected_object = null
	spring_arm_3d.rotation = Vector3.ZERO


func _on_ux_gui_input(event):
	if (global.player_state == 1
		or global.player_state == 2
		or global.player_state == 3):
		if event is InputEventMouseMotion:
			rot_h -= event.relative.x * SENS
			rot_v -= event.relative.y * SENS


func _on_build_ux_create_item(item):
	var new_item = item.instantiate()
	new_item.widget_ready.connect(_on_new_item_widget_ready)
	get_parent().add_child(new_item)
	new_item.global_position = global_position - (cam.global_basis.z * 5.0)
	global.player_state = 2


func _on_new_item_widget_ready(item):
	print("ready")
	just_placed_item = true
	selected_object = item
