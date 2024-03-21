@tool
extends Path3D
class_name RoadPath


const WHEEL_TRACKER = preload("res://scenes/wheel_tracker.tscn")
const CHASSIS_TRACKER = preload("res://scenes/chassis_tracker.tscn")
const CAM_TRACKER = preload("res://scenes/cam_tracker.tscn")
const ROAD_MATERIAL = preload("res://textures/road_material.tres")
const DRAFT_ROAD_MATERIAL = preload("res://textures/draft_road_material.tres")
const ROAD_UNDERSIDE_MATERIAL = preload("res://textures/road_underside_material.tres")
const ROAD_SIDE_MATERIAL = preload("res://textures/road_side_material.tres")
const AREA = preload("res://scenes/area.tscn")
const WHEEL_TRACKER_RADIUS = 2.0
const CHASSIS_TRACKER_RADIUS = 4.0
const DRAFT_TIME = 0.5


@export var surface_width := 8.0
@export var wheel_trackers: Array[AnimatableBody3D]
@export var area: Area3D
@export var cam_magnet: Node3D
@export var radius := false
@export var radius_value := 50.0
@export var radius_up_offset := 50.0
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
var draft_timer := 0.0
var generate_draft := false
var trackers_initialized := false


var placeable_points: Array[PlaceableRoadPoint] = []


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("curve_changed", _on_curve_changed)
	if not Engine.is_editor_hint() and curve.point_count > 1:
		_generate_mesh()
		_initialize_trackers()


func _process(delta):
	if generate_draft:
		draft_timer -= delta
		if draft_timer <= 0.0:
			generate_draft = false
			_generate_mesh_draft()


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
			var track_right = closest_transform.basis.x
			var track_up = closest_transform.basis.y
			var track_fwd = -closest_transform.basis.z
			if radius:
				var circle_center = closest_point + Vector3(track_up * radius_up_offset)
				var circle_circumference = radius_up_offset * 2.0 * PI
				var track_coverage = surface_width / circle_circumference
				track_coverage *= 2.0
				var dir_to_pos = circle_center.direction_to(wheel.global_position)
				dir_to_pos = Plane(track_fwd, circle_center).project(dir_to_pos).normalized()
				var angle_to_wheel = -track_up.signed_angle_to(wheel_pos, track_fwd)
				var dir_basis_x = dir_to_pos.cross(track_fwd)
				var wheel_basis = Basis(dir_basis_x, -dir_to_pos, -track_fwd)
				tracker.basis = wheel_basis.orthonormalized()
				tracker.position = circle_center + Vector3(dir_to_pos * radius_value)
			else:
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
			var track_right = closest_transform.basis.x
			var track_up = closest_transform.basis.y
			var track_fwd = -closest_transform.basis.z
			var dist_to_chassis = min(closest_point.distance_to(chassis_pos), (surface_width / 2.0) - 4.0)
			var dir_to_chassis = closest_point.direction_to(chassis_pos)
			var side_to_chassis = sign(closest_transform.basis.x.dot(dir_to_chassis))
			chassis_tracker.transform = closest_transform
			chassis_tracker.position += closest_transform.basis.x * side_to_chassis * dist_to_chassis
			
			var cam_pos = to_local(car.cam_x_form.global_position)
			var closest_point_cam = curve.get_closest_point(cam_pos)
			var closest_offset_cam = curve.get_closest_offset(cam_pos)
			var closest_transform_cam = curve.sample_baked_with_rotation(closest_offset_cam, true, true)
			var track_right_cam = closest_transform_cam.basis.x
			var track_up_cam = closest_transform_cam.basis.y
			var track_fwd_cam = -closest_transform_cam.basis.z
			var dist_to_cam = min(closest_point_cam.distance_to(cam_pos), (surface_width / 2.0) - 4.0)
			var dir_to_cam = closest_point_cam.direction_to(cam_pos)
			var side_to_cam = sign(closest_transform_cam.basis.x.dot(dir_to_cam))
			cam_tracker.transform = closest_transform_cam
			cam_tracker.position += closest_transform_cam.basis.x * side_to_cam * dist_to_cam


func _initialize_trackers():
	if not trackers_initialized:
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
		trackers_initialized = true
	track_length = curve.get_baked_length()
	wheel_min_offset = WHEEL_TRACKER_RADIUS
	wheel_max_offset = track_length - WHEEL_TRACKER_RADIUS
	chassis_min_offset = CHASSIS_TRACKER_RADIUS
	chassis_max_offset = track_length - CHASSIS_TRACKER_RADIUS


func _generate_mesh():
	if curve.point_count > 0:
		var curve_length = curve.get_baked_length()
		var arrmesh := ArrayMesh.new()
		var arr = []
		arr.resize(ArrayMesh.ARRAY_MAX)
		var vertex_array := PackedVector3Array([])
		var normal_array := PackedVector3Array([])
		var uv_array := PackedVector2Array([])
		
		var arr_side_left = []
		arr_side_left.resize(ArrayMesh.ARRAY_MAX)
		var vertex_array_side_left := PackedVector3Array([])
		var normal_array_side_left := PackedVector3Array([])
		var uv_array_side_left := PackedVector2Array([])
		
		var arr_side_right = []
		arr_side_right.resize(ArrayMesh.ARRAY_MAX)
		var vertex_array_side_right := PackedVector3Array([])
		var normal_array_side_right := PackedVector3Array([])
		var uv_array_side_right := PackedVector2Array([])
		
		var curve_points := curve.tessellate_even_length()
		var alternator = 1.0
		for i in curve_points.size() - 1:
			var point = curve_points[i]
			var point_offset = curve.get_closest_offset(point)
			var point_transform = curve.sample_baked_with_rotation(point_offset, true, true)
			var track_right = point_transform.basis.x
			var track_up = point_transform.basis.y
			var track_fwd = -point_transform.basis.z
			
			var point_next = curve_points[i + 1]
			var point_offset_next = curve.get_closest_offset(point_next)
			var point_transform_next = curve.sample_baked_with_rotation(point_offset_next, true, true)
			var track_right_next = point_transform_next.basis.x
			var track_up_next = point_transform_next.basis.y
			var track_fwd_next = -point_transform_next.basis.z
			
			var point0r = point + (track_right * surface_width / 2.0)
			var point0l = point - (track_right * surface_width / 2.0)
			if radius:
				var circle_center = point + Vector3(track_up * radius_up_offset)
				var circle_center_next = point_next + Vector3(track_up_next * radius_up_offset)
				var circle_circumference = radius_up_offset * 2.0 * PI
				var track_coverage = surface_width / circle_circumference
				#track_coverage = clampf(track_coverage, 0.0, 1.0)
				track_coverage *= 2.0
				#track_coverage -= 1.0
				for va in 11:
					var progress = float(va) / 10.0
					progress -= 0.5
					progress *= alternator
					var vertex_angle = track_coverage * progress * PI
					var dir_to_pos = circle_center.direction_to(point)
					var pt = circle_center + (dir_to_pos.rotated(track_fwd, vertex_angle) * radius_value)
					var dir_to_pos_next = circle_center_next.direction_to(point_next)
					var pt_next = circle_center_next + (dir_to_pos_next.rotated(track_fwd_next, vertex_angle) * radius_value)
					if alternator > 0.0:
						vertex_array.append(pt_next)
						normal_array.append(-dir_to_pos_next)
						uv_array.append(Vector2(1.0, point_offset_next / curve_length))
						
						vertex_array.append(pt)
						normal_array.append(-dir_to_pos)
						uv_array.append(Vector2(1.0, point_offset / curve_length))
					else:
						vertex_array.append(pt)
						normal_array.append(-dir_to_pos)
						uv_array.append(Vector2(1.0, point_offset / curve_length))
						
						vertex_array.append(pt_next)
						normal_array.append(-dir_to_pos_next)
						uv_array.append(Vector2(1.0, point_offset_next / curve_length))
				alternator *= -1.0
			else:
				vertex_array.append(point0r)
				vertex_array.append(point0l)
				normal_array.append(track_up)
				normal_array.append(track_up)
				uv_array.append(Vector2(1.0, point_offset / curve_length))
				uv_array.append(Vector2(0.0, point_offset / curve_length))
				
				vertex_array_side_left.append(point0l)
				vertex_array_side_left.append(point0l - track_up)
				normal_array_side_left.append(-track_right)
				normal_array_side_left.append(-track_right)
				uv_array_side_left.append(Vector2(1.0, point_offset / curve_length))
				uv_array_side_left.append(Vector2(0.0, point_offset / curve_length))
				
				vertex_array_side_right.append(point0r - track_up)
				vertex_array_side_right.append(point0r)
				normal_array_side_right.append(track_right)
				normal_array_side_right.append(track_right)
				uv_array_side_right.append(Vector2(1.0, point_offset / curve_length))
				uv_array_side_right.append(Vector2(0.0, point_offset / curve_length))
		arr[ArrayMesh.ARRAY_VERTEX] = vertex_array
		arr[ArrayMesh.ARRAY_NORMAL] = normal_array
		arr[ArrayMesh.ARRAY_TEX_UV] = uv_array
		
		arr_side_left[ArrayMesh.ARRAY_VERTEX] = vertex_array_side_left
		arr_side_left[ArrayMesh.ARRAY_NORMAL] = normal_array_side_left
		arr_side_left[ArrayMesh.ARRAY_TEX_UV] = uv_array_side_left
		
		arr_side_right[ArrayMesh.ARRAY_VERTEX] = vertex_array_side_right
		arr_side_right[ArrayMesh.ARRAY_NORMAL] = normal_array_side_right
		arr_side_right[ArrayMesh.ARRAY_TEX_UV] = uv_array_side_right
		
		arrmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arr)
		arrmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arr)
		arrmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arr_side_left)
		arrmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arr_side_right)
		for child in get_children():
			if child.is_class("MeshInstance3D"):
				child.queue_free()
		var newmesh = MeshInstance3D.new()
		add_child(newmesh)
		newmesh.mesh = arrmesh
		newmesh.set_surface_override_material(0, ROAD_MATERIAL)
		newmesh.set_surface_override_material(1, ROAD_UNDERSIDE_MATERIAL)
		newmesh.set_surface_override_material(2, ROAD_SIDE_MATERIAL)
		newmesh.set_surface_override_material(3, ROAD_SIDE_MATERIAL)
		
		if not Engine.is_editor_hint():
			if not area:
				var new_area = AREA.instantiate()
				add_child(new_area)
				area = new_area
				
			var min_x = 0.0
			var min_y = 0.0
			var min_z = 0.0
			
			var max_x = 0.0
			var max_y = 0.0
			var max_z = 0.0
			
			for point in curve_points:
				min_x = min(min_x, point.x)
				min_y = min(min_y, point.y)
				min_z = min(min_z, point.z)
				
				max_x = max(max_x, point.x)
				max_y = max(max_y, point.y)
				max_z = max(max_z, point.z)
			
			var min_v = Vector3(min_x, min_y, min_z)
			var max_v = Vector3(max_x, max_y, max_z)
			var ctr = min_v.lerp(max_v, 0.5)
			
			var size_x = max_x - min_x + surface_width
			var size_y = max_y - min_y + surface_width
			var size_z = max_z - min_z + surface_width
			
			if area:
				area.position = ctr
				area.get_child(0).shape.size = Vector3(size_x, size_y, size_z)
				if not area.is_connected("body_entered", _body_entered):
					area.body_entered.connect(_body_entered)
					area.body_exited.connect(_body_exited)
				area.set_collision_mask_value(2, true)
				area.set_collision_mask_value(3, true)


func _generate_mesh_draft():
	if curve.point_count > 1:
		var arrmesh := ArrayMesh.new()
		var arr = []
		arr.resize(ArrayMesh.ARRAY_MAX)
		var vertex_array := PackedVector3Array([])
		var normal_array := PackedVector3Array([])
		var uv_array := PackedVector2Array([])
		var curve_points := curve.tessellate_even_length()
		var alternator = 1.0
		for i in curve_points.size() - 1:
			var point = curve_points[i]
			var point_offset = curve.get_closest_offset(point)
			var point_transform = curve.sample_baked_with_rotation(point_offset, true, true)
			var track_right = point_transform.basis.x
			var track_up = point_transform.basis.y
			var track_fwd = -point_transform.basis.z
			
			var point_next = curve_points[i + 1]
			var point_offset_next = curve.get_closest_offset(point_next)
			var point_transform_next = curve.sample_baked_with_rotation(point_offset_next, true, true)
			var track_right_next = point_transform_next.basis.x
			var track_up_next = point_transform_next.basis.y
			var track_fwd_next = -point_transform_next.basis.z
			
			var point0r = point + (track_right * surface_width / 2.0)
			var point0l = point - (track_right * surface_width / 2.0)
			if radius:
				var circle_center = point + Vector3(track_up * radius_up_offset)
				var circle_center_next = point_next + Vector3(track_up_next * radius_up_offset)
				var circle_circumference = radius_up_offset * 2.0 * PI
				var track_coverage = surface_width / circle_circumference
				#track_coverage = clampf(track_coverage, 0.0, 1.0)
				track_coverage *= 2.0
				#track_coverage -= 1.0
				for va in 11:
					var progress = float(va) / 10.0
					progress -= 0.5
					progress *= alternator
					var vertex_angle = track_coverage * progress * PI
					var dir_to_pos = circle_center.direction_to(point)
					var pt = circle_center + (dir_to_pos.rotated(track_fwd, vertex_angle) * radius_value)
					var dir_to_pos_next = circle_center_next.direction_to(point_next)
					var pt_next = circle_center_next + (dir_to_pos_next.rotated(track_fwd_next, vertex_angle) * radius_value)
					if alternator > 0.0:
						vertex_array.append(pt_next)
						normal_array.append(-dir_to_pos_next)
						uv_array.append(Vector2(1.0, point_offset_next / curve.get_baked_length()))
						
						vertex_array.append(pt)
						normal_array.append(-dir_to_pos)
						uv_array.append(Vector2(1.0, point_offset / curve.get_baked_length()))
					else:
						vertex_array.append(pt)
						normal_array.append(-dir_to_pos)
						uv_array.append(Vector2(1.0, point_offset / curve.get_baked_length()))
						
						vertex_array.append(pt_next)
						normal_array.append(-dir_to_pos_next)
						uv_array.append(Vector2(1.0, point_offset_next / curve.get_baked_length()))
				alternator *= -1.0
			else:
				vertex_array.append(point0r)
				vertex_array.append(point0l)
				normal_array.append(track_up)
				normal_array.append(track_up)
				uv_array.append(Vector2(1.0, point_offset / curve.get_baked_length()))
				uv_array.append(Vector2(0.0, point_offset / curve.get_baked_length()))
		arr[ArrayMesh.ARRAY_VERTEX] = vertex_array
		arr[ArrayMesh.ARRAY_NORMAL] = normal_array
		arr[ArrayMesh.ARRAY_TEX_UV] = uv_array
		if radius:
			arrmesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arr)
		else:
			arrmesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr)
		for child in get_children():
			if child.is_class("MeshInstance3D"):
				child.queue_free()
		var newmesh = MeshInstance3D.new()
		add_child(newmesh)
		newmesh.mesh = arrmesh
		newmesh.set_surface_override_material(0, DRAFT_ROAD_MATERIAL)
		print("generated draft road")


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


func _on_curve_changed():
	draft_timer = DRAFT_TIME
	generate_draft = true


func _placeable_points_set():
	print("making curve")
	curve.clear_points()
	for point in placeable_points:
		curve.add_point(to_local(point.global_position),
						point.global_basis.z * point.curve_size,
						-point.global_basis.z * point.curve_size,
						point.road_curve_idx)
		curve.set_point_tilt(point.road_curve_idx, point.tilt)
