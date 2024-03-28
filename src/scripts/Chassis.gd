extends RigidBody3D


const SPRING_LENGTH_TYPE_0 = 6.0
const SPRING_LENGTH_TYPE_1 = 12.0


var look_dir := Vector3.FORWARD
var spawn_transform: Transform3D
var target_up_dir := Vector3.UP
var up_dir := Vector3.UP
var last_pos := Vector3.ZERO
var manual_up := false
var last_up_dir := Vector3.UP

var global: Node


@onready var cam_base = $CamBase
@onready var down_cast = $DownCast
@onready var spring_arm_3d = $CamBase/SpringArm3D


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.camera_type_changed.connect(_on_global_camera_type_changed)
	last_pos = global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var lin_vel = linear_velocity
	if global.camera_type == 0:
		pass
	if lin_vel.length_squared() < 2.0:
		look_dir = look_dir.lerp(-global_basis.z, 0.01)
		look_dir.y *= 0.8
	else:
		var ang_to_up = lin_vel.angle_to(Vector3.UP)
		if not manual_up and (ang_to_up < PI/4.0 or ang_to_up > 3.0*PI/4.0):
			target_up_dir = last_up_dir
			#look_dir = look_dir.lerp(lin_vel, 0.1)
		else:
			look_dir = look_dir.lerp(lin_vel, 0.1)
	up_dir = up_dir.lerp(target_up_dir, 0.1)
	global.camera_up = up_dir
	cam_base.look_at(cam_base.global_position + look_dir.normalized(), up_dir)
	last_pos = global_position


func _physics_process(delta):
	if down_cast.is_colliding():
		var norm = down_cast.get_collision_normal()
		last_up_dir = norm
		#target_up_dir = norm
		manual_up = true
	else:
		last_up_dir = Vector3.UP
		target_up_dir = Vector3.UP
		manual_up = false


func _on_global_camera_type_changed():
	if global.camera_type == 0:
		spring_arm_3d.spring_length = SPRING_LENGTH_TYPE_0
	elif global.camera_type == 1:
		spring_arm_3d.spring_length = SPRING_LENGTH_TYPE_1
