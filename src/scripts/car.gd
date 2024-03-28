extends Node3D


signal velocity(vel: Vector3)
signal position_signal(pos: Vector3)


const WHEEL_RADIUS = 0.4
const ENGINE_NOTE_TIME = 0.125
const RESPAWN_TIME = 0.3

@export var rpm_torque_response: Curve
@export var grip_curve: Curve
@export var sideways_curve: Curve

@onready var joint_fl = $Chassis/JointFL
@onready var joint_fr = $Chassis/JointFR
@onready var joint_bl = $Chassis/JointBL
@onready var joint_br = $Chassis/JointBR

@onready var wheel_fl = $WheelFL
@onready var wheel_fr = $WheelFR
@onready var wheel_bl = $WheelBL
@onready var wheel_br = $WheelBR

@onready var chassis = $Chassis
@onready var cam_x_form = $Chassis/CamBase/SpringArm3D/CamXForm

@onready var audio_stream_player_engine = $Chassis/AudioStreamPlayerEngine
@onready var audio_stream_player_engine_2 = $Chassis/AudioStreamPlayerEngine2


var joints: Array[Generic6DOFJoint3D]
var wheels: Array[RigidBody3D]
var drive_wheels: Array[RigidBody3D]
var wheel_angle := 0.0

var node_holder: Node

var flipped := false
var engine_note_timer := 0.1
var engine_rpm := 0.0:
	set(value):
		engine_rpm = clampf(value, 1.0, 2.0)
var engine_sound := false
var default_joint_params: Dictionary
var engine_sound_2 := false
var engine_sound_2_ins := 46
var engine_sound_percussion := 35
var engine_beat_counter := 0
var second_beat_timing := false
var second_beat_timer := 0.08
var throttle := 0.0
var respawn_timer := 0.0

var global: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	#v_box_container_params.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	joints = [joint_fl,
			joint_fr,
			joint_bl,
			joint_br]
	#for joint: Generic6DOFJoint3D in joints:
		#var llsoft = snappedf(joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS), 0.01)
		#var llrest = snappedf(joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_RESTITUTION), 0.01)
		#var lldamp = snappedf(joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING), 0.01)
		#var sstiff = snappedf(joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS), 0.01)
		#var sdamp = snappedf(joint.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING), 0.01)
		#label_value_ll_softness.text = str(llsoft)
		#h_slider_ll_softness.set_value_no_signal(llsoft)
		#label_value_ll_restitution.text = str(llrest)
		#h_slider_ll_restitution.set_value_no_signal(llrest)
		#label_value_ll_damping.text = str(lldamp)
		#h_slider_ll_damping.set_value_no_signal(lldamp)
		#label_value_s_stiffness.text = str(sstiff)
		#h_slider_s_stiffness.set_value_no_signal(sstiff)
		#label_value_s_damping.text = str(sdamp)
		#h_slider_s_damping.set_value_no_signal(sdamp)
		#default_joint_params = {"LLSoftness": llsoft,
								#"LLRestitution": llrest,
								#"LLDamping": lldamp,
								#"SStiffness": sstiff,
								#"SDamping": sdamp}
	wheels = [wheel_fl,
			wheel_fr,
			wheel_bl,
			wheel_br]
	_set_spawn_transforms()
	node_holder = get_node("/root/NodeHolder")
	node_holder.player_node = self


func _physics_process(delta):
	if global.player_state == 0:
		emit_signal("position_signal", chassis.global_position)
		emit_signal("velocity", chassis.linear_velocity)
		throttle = -Input.get_axis("back", "fwd")
		var turn = Input.get_axis("left", "right")
		var turn_limiter = remap(chassis.linear_velocity.length_squared(), 0.0, 20000.0, 0.0, 1.0)
		turn_limiter = 1.0 - clamp(turn_limiter, 0.0, 0.95)
		
		if is_equal_approx(turn, 0.0):
			wheel_angle = lerp_angle(wheel_angle, 0.0, 0.1)
		else:
			wheel_angle = lerp_angle(wheel_angle, turn * PI/10.0 * turn_limiter, 0.1)
		wheel_angle = clamp(wheel_angle, -PI/10.0, PI/10.0)
		
		input_percussion()
		hydraulics()
		input_flip()
	else:
		wheel_angle = lerp_angle(wheel_angle, 0.0, 0.1)
	
	joint_fl.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, wheel_angle)
	joint_fl.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, wheel_angle)
	joint_fr.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, wheel_angle)
	joint_fr.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, wheel_angle)


func _process(delta):
	if Input.is_action_just_pressed("respawn"):
		respawn_timer = RESPAWN_TIME
	if Input.is_action_pressed("respawn"):
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			_respawn()
	
	var heading = sign(chassis.linear_velocity.dot(chassis.global_basis.z))
	# -1 is forward
	
	var speed_note_factor = remap(chassis.linear_velocity.length_squared(), 0.0, 8000.0, 1.0, 1.5)
	speed_note_factor = clamp(speed_note_factor, 1.0, 1.5)
	
	var brake_multiplier = 1.0

	if heading == sign(throttle):
		engine_rpm = lerp(engine_rpm, speed_note_factor + abs(throttle * 0.3), 0.1)
	else:
		engine_rpm = lerp(engine_rpm, speed_note_factor, 0.03)
		brake_multiplier = 2.0
	audio_stream_player_engine.pitch_scale = engine_rpm
	audio_stream_player_engine_2.pitch_scale = engine_rpm * 0.9
	audio_stream_player_engine_2.volume_db = remap(speed_note_factor, 1.0, 1.5, -10.0, 0.0)
		
	for wheel: RigidBody3D in wheels:
		var wheel_ang_rot = wheel_fl.angular_velocity.x
		wheel_ang_rot = remap(abs(wheel_ang_rot), 0.0, 200.0, 0.0, 1.0)
		wheel_ang_rot = rpm_torque_response.sample_baked(wheel_ang_rot)
		wheel.braking_multiplier = brake_multiplier
		wheel.throttle = throttle


func _set_spawn_transforms():
	chassis.spawn_transform = chassis.global_transform
	for wheel in wheels:
		wheel.spawn_transform = wheel.global_transform


func _respawn():
	chassis.freeze = true
	for wheel in wheels:
		wheel.freeze = true
	chassis.global_transform = chassis.spawn_transform
	for wheel in wheels:
		wheel.global_transform = wheel.spawn_transform
	chassis.freeze = false
	for wheel in wheels:
		wheel.freeze = false


func hydraulics():
	var lift_dist = -0.3
	var default_dist = -0.1
	
	if (Input.is_action_pressed("lift back")
	or Input.is_action_pressed("lift left")
	or Input.is_action_just_pressed("jump")):
		joint_bl.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, lift_dist)
		joint_bl.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, lift_dist - 0.1)
	else:
		joint_bl.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, default_dist)
		joint_bl.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, default_dist - 0.1)
	if (Input.is_action_pressed("lift back")
	or Input.is_action_pressed("lift right")
	or Input.is_action_just_pressed("jump")):
		joint_br.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, lift_dist)
		joint_br.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, lift_dist - 0.1)
	else:
		joint_br.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, default_dist)
		joint_br.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, default_dist - 0.1)
	if (Input.is_action_pressed("lift fwd")
	or Input.is_action_pressed("lift right")
	or Input.is_action_just_pressed("jump")):
		joint_fr.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, lift_dist)
		joint_fr.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, lift_dist - 0.1)
	else:
		joint_fr.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, default_dist)
		joint_fr.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, default_dist - 0.1)
	if (Input.is_action_pressed("lift fwd")
	or Input.is_action_pressed("lift left")
	or Input.is_action_just_pressed("jump")):
		joint_fl.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, lift_dist)
		joint_fl.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, lift_dist - 0.1)
	else:
		joint_fl.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, default_dist)
		joint_fl.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, default_dist - 0.1)


func input_percussion():
	if Input.is_action_just_pressed("lift back"):
		pass
		wheel_bl.bounce_noise.play()
		wheel_br.bounce_noise.play()
	if Input.is_action_just_pressed("lift fwd"):
		pass
		wheel_fl.bounce_noise.play()
		wheel_fr.bounce_noise.play()
	if Input.is_action_just_pressed("lift left"):
		pass
		wheel_bl.bounce_noise.play()
		wheel_fl.bounce_noise.play()
	if Input.is_action_just_pressed("lift right"):
		pass
		wheel_fr.bounce_noise.play()
		wheel_br.bounce_noise.play()
	if Input.is_action_just_pressed("jump"):
		pass
		wheel_bl.bounce_noise.play()
		wheel_br.bounce_noise.play()
		wheel_fl.bounce_noise.play()
		wheel_fr.bounce_noise.play()


func input_flip():
	if (Input.is_action_just_pressed("flip")
	and chassis.linear_velocity.length_squared() < 100.0
	and chassis.get_contact_count() > 0):
		print(chassis.global_basis.y.dot(Vector3.DOWN))
		if chassis.global_basis.y.dot(Vector3.DOWN) >= 0.0:
			flipped = true
			chassis.apply_central_impulse(Vector3.UP * 70.0)
			chassis.apply_torque_impulse(chassis.global_basis.z * 15.0)
			print("flipped")
	if flipped:
		pass


func set_joint_params(param: Generic6DOFJoint3D.Param, value: float):
	for joint: Generic6DOFJoint3D in joints:
		joint.set_param_y(param, value)


func body_note(body: Node):
	if body.is_in_group("bouncy ball"):
		# good: 60, 
		pass
		#midi_percussion(64, 60)
	elif body.is_in_group("billiard ball"):
		pass
		#midi_percussion(76, 70)
	elif body.is_in_group("cymbal"):
		pass
		#midi_percussion(52, 80)
	elif body.is_in_group("wood"):
		pass
		#midi_percussion(77, 50)


func _on_wheel_fl_body_entered(body):
	body_note(body)


func _on_wheel_fr_body_entered(body):
	body_note(body)


func _on_wheel_bl_body_entered(body):
	body_note(body)


func _on_wheel_br_body_entered(body):
	body_note(body)


func _on_chassis_body_entered(body):
	body_note(body)
