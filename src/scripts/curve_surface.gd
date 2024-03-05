@tool
extends Path3D
class_name RoadPath


const WHEEL_TRACKER = preload("res://scenes/wheel_tracker.tscn")
const CHASSIS_TRACKER = preload("res://scenes/chassis_tracker.tscn")
const CAM_TRACKER = preload("res://scenes/cam_tracker.tscn")
const ROAD_MATERIAL = preload("res://textures/road_material.tres")
const PLACEABLE_ROAD_POINT = preload("res://scenes/placeable_road_point.tscn")
const WHEEL_TRACKER_RADIUS = 2.0
const CHASSIS_TRACKER_RADIUS = 4.0


@export var surface_width := 8.0
@export var wheel_trackers: Array[AnimatableBody3D]
@export var area: Area3D
@export var cam_magnet: Node3D
@export var generate_mesh := false:
	set(value):
		if value:
			_generate_mesh()


var tracked_wheels: Array[RigidBody3D] = []
var tracked_chassis: RigidBody3D
var chassis_tracker: AnimatableBody3D
var cam_tracker: AnimatableBody3D
var tracked_cam: Node3D
var car: Node3D
var track_length: float
var wheel_min_offset: float
var wheel_max_offset: float
var chassis_min_offset: float
var chassis_max_offset: float



# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		if area:
			area.body_entered.connect(_body_entered)
			area.body_exited.connect(_body_exited)
		for i in 4:
			var new_tracker = WHEEL_TRACKER.instantiate()
			add_child(new_tracker)
			wheel_trackers.append(new_tracker)
		var new_chassis_tracker = CHASSIS_TRACKER.instantiate()
		add_child(new_chassis_tracker)
		chassis_tracker = new_chassis_tracker
		var new_cam_tracker = CAM_TRACKER.instantiate()
		add_child(new_cam_tracker)
		cam_tracker = new_cam_tracker
		_generate_mesh()
		track_length = curve.get_baked_length()
		wheel_min_offset = WHEEL_TRACKER_RADIUS
		wheel_max_offset = track_length - WHEEL_TRACKER_RADIUS
		chassis_min_offset = CHASSIS_TRACKER_RADIUS
		chassis_max_offset = track_length - CHASSIS_TRACKER_RADIUS


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if not Engine.is_editor_hint():
		for i in tracked_wheels.size():
			var wheel: RigidBody3D = tracked_wheels[i]
			var tracker: AnimatableBody3D = wheel_trackers[i]
			var wheel_pos = to_local(wheel.global_position)
			var closest_point = curve.get_closest_point(wheel_pos)
			var closest_offset = curve.get_closest_offset(wheel_pos)
			var closest_transform = curve.sample_baked_with_rotation(closest_offset, true, true)
			var dist_to_wheel = min(closest_point.distance_to(wheel_pos), (surface_width / 2.0) - 1.0)
			var dir_to_wheel = closest_point.direction_to(wheel_pos)
			var side_to_wheel = sign(closest_transform.basis.x.dot(dir_to_wheel))
			tracker.transform = closest_transform
			tracker.position += closest_transform.basis.x * side_to_wheel * dist_to_wheel
		if tracked_chassis:
			var chassis_pos = to_local(tracked_chassis.global_position)
			var closest_point = curve.get_closest_point(chassis_pos)
			var closest_offset = curve.get_closest_offset(chassis_pos)
			closest_offset = clamp(closest_offset, chassis_min_offset, chassis_max_offset)
			var closest_transform = curve.sample_baked_with_rotation(closest_offset, true, true)
			var dist_to_chassis = min(closest_point.distance_to(chassis_pos), (surface_width / 2.0) - 4.0)
			var dir_to_chassis = closest_point.direction_to(chassis_pos)
			var side_to_chassis = sign(closest_transform.basis.x.dot(dir_to_chassis))
			chassis_tracker.transform = closest_transform
			chassis_tracker.position += closest_transform.basis.x * side_to_chassis * dist_to_chassis
			
			var cam_pos = to_local(car.cam_x_form.global_position)
			var closest_point_cam = curve.get_closest_point(cam_pos)
			var closest_offset_cam = curve.get_closest_offset(cam_pos)
			var closest_transform_cam = curve.sample_baked_with_rotation(closest_offset_cam, true, true)
			var dist_to_cam = min(closest_point_cam.distance_to(cam_pos), (surface_width / 2.0) - 4.0)
			var dir_to_cam = closest_point_cam.direction_to(cam_pos)
			var side_to_cam = sign(closest_transform_cam.basis.x.dot(dir_to_cam))
			cam_tracker.transform = closest_transform_cam
			cam_tracker.position += closest_transform_cam.basis.x * side_to_cam * dist_to_cam


func _generate_mesh():
	if curve.point_count > 0:
		var arrmesh := ArrayMesh.new()
		var arr = []
		arr.resize(ArrayMesh.ARRAY_MAX)
		var vertex_array := PackedVector3Array([])
		var normal_array := PackedVector3Array([])
		var uv_array := PackedVector2Array([])
		var curve_points := curve.tessellate_even_length()
		for point in curve_points:
			var point_offset = curve.get_closest_offset(point)
			var point_transform = curve.sample_baked_with_rotation(point_offset, true, true)
			var track_right = point_transform.basis.x
			var point0r = point + (track_right * surface_width / 2.0)
			var point0l = point - (track_right * surface_width / 2.0)
			vertex_array.append(point0r)
			vertex_array.append(point0l)
			normal_array.append(point_transform.basis.y)
			normal_array.append(point_transform.basis.y)
			uv_array.append(Vector2(1.0, point_offset / curve.get_baked_length()))
			uv_array.append(Vector2(0.0, point_offset / curve.get_baked_length()))
		arr[ArrayMesh.ARRAY_VERTEX] = vertex_array
		arr[ArrayMesh.ARRAY_NORMAL] = normal_array
		arr[ArrayMesh.ARRAY_TEX_UV] = uv_array
		arrmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arr)
		for child in get_children():
			if child.is_class("MeshInstance3D"):
				child.queue_free()
		var newmesh = MeshInstance3D.new()
		add_child(newmesh)
		newmesh.mesh = arrmesh
		newmesh.set_surface_override_material(0, ROAD_MATERIAL)


func _body_entered(body: Node):
	if body.is_in_group("wheel"):
		if not tracked_wheels.has(body):
			tracked_wheels.append(body)
		print("tracking %s wheels" % str(tracked_wheels.size()))
	if body.is_in_group("chassis"):
		tracked_chassis = body
		car = body.get_parent()


func _body_exited(body: Node):
	if body.is_in_group("wheel"):
		if tracked_wheels.has(body):
			tracked_wheels.erase(body)
	if body.is_in_group("chassis"):
		tracked_chassis = null


func _on_area_3d_area_entered(area):
	pass
	#if area.is_in_group("magnet") and cam_magnet:
		#tracked_cam = area.get_parent().get_parent().get_parent()
		#tracked_cam.magnet_node = cam_magnet
		#tracked_cam.magnet_enabled = true


func _on_area_3d_area_exited(area):
	pass
	#if area.is_in_group("magnet") and cam_magnet:
		#tracked_cam.magnet_node = null
		#tracked_cam.magnet_enabled = false
		#tracked_cam = null
