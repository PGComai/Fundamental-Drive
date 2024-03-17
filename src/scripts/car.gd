extends Node3D


signal velocity(vel: Vector3)
signal position_signal(pos: Vector3)


const WHEEL_RADIUS = 0.4
const ENGINE_NOTE_TIME = 0.125

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

@onready var flipped_cast = $Chassis/FlippedCast
#@onready var midi_player : MidiPlayer = $MidiPlayer
#@onready var ux = $UX
#@onready var v_box_container_params = $UX/MarginContainer/VBoxContainerParams
@onready var cam_x_form = $Chassis/CamBase/SpringArm3D/CamXForm
@onready var audio_stream_player_engine = $Chassis/AudioStreamPlayerEngine


#@onready var label_value_ll_softness = $UX/MarginContainer/VBoxContainerParams/Param1/LabelValueLLSoftness
#@onready var label_value_ll_restitution = $UX/MarginContainer/VBoxContainerParams/Param2/LabelValueLLRestitution
#@onready var label_value_ll_damping = $UX/MarginContainer/VBoxContainerParams/Param3/LabelValueLLDamping
#@onready var label_value_s_stiffness = $UX/MarginContainer/VBoxContainerParams/Param4/LabelValueSStiffness
#@onready var label_value_s_damping = $UX/MarginContainer/VBoxContainerParams/Param5/LabelValueSDamping
#
#@onready var h_slider_ll_softness = $UX/MarginContainer/VBoxContainerParams/Param1/HSliderLLSoftness
#@onready var h_slider_ll_restitution = $UX/MarginContainer/VBoxContainerParams/Param2/HSliderLLRestitution
#@onready var h_slider_ll_damping = $UX/MarginContainer/VBoxContainerParams/Param3/HSliderLLDamping
#@onready var h_slider_s_stiffness = $UX/MarginContainer/VBoxContainerParams/Param4/HSliderSStiffness
#@onready var h_slider_s_damping = $UX/MarginContainer/VBoxContainerParams/Param5/HSliderSDamping


var joints: Array[Generic6DOFJoint3D]
var wheels: Array[RigidBody3D]
var drive_wheels: Array[RigidBody3D]
var wheel_angle := 0.0

var node_holder: Node


var spawn_transform: Transform3D

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

var global: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	#v_box_container_params.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spawn_transform = chassis.global_transform
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
	drive_wheels = [wheel_bl,
			wheel_br]
	node_holder = get_node("/root/NodeHolder")
	node_holder.player_node = self


func _physics_process(delta):
	if not global.build_mode:
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
		
	for wheel: RigidBody3D in wheels:
		var wheel_ang_rot = wheel_fl.angular_velocity.x
		wheel_ang_rot = remap(abs(wheel_ang_rot), 0.0, 200.0, 0.0, 1.0)
		wheel_ang_rot = rpm_torque_response.sample_baked(wheel_ang_rot)
		wheel.braking_multiplier = brake_multiplier
		wheel.throttle = throttle


#func note_mute_cuica():
	#midi_percussion(78, 90)


func hydraulics():
	var lift_dist = -0.3
	var default_dist = -0.1
	if Input.get_connected_joypads().size() > 0 and not global.kb_input:
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
	else:
		if (Input.is_action_pressed("lift back kb")
		or Input.is_action_pressed("lift left kb")
		or Input.is_action_just_pressed("jump")):
			joint_bl.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, lift_dist)
			joint_bl.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, lift_dist - 0.1)
		else:
			joint_bl.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, default_dist)
			joint_bl.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, default_dist - 0.1)
		if (Input.is_action_pressed("lift back kb")
		or Input.is_action_pressed("lift right kb")
		or Input.is_action_just_pressed("jump")):
			joint_br.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, lift_dist)
			joint_br.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, lift_dist - 0.1)
		else:
			joint_br.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, default_dist)
			joint_br.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, default_dist - 0.1)
		if (Input.is_action_pressed("lift fwd kb")
		or Input.is_action_pressed("lift right kb")
		or Input.is_action_just_pressed("jump")):
			joint_fr.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, lift_dist)
			joint_fr.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, lift_dist - 0.1)
		else:
			joint_fr.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, default_dist)
			joint_fr.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, default_dist - 0.1)
		if (Input.is_action_pressed("lift fwd kb")
		or Input.is_action_pressed("lift left kb")
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
		#midi_percussion(60, 90)
	if Input.is_action_just_pressed("lift fwd"):
		pass
		wheel_fl.bounce_noise.play()
		wheel_fr.bounce_noise.play()
		#midi_percussion(60, 90)
	if Input.is_action_just_pressed("lift left"):
		pass
		wheel_bl.bounce_noise.play()
		wheel_fl.bounce_noise.play()
		#midi_percussion(60, 90)
	if Input.is_action_just_pressed("lift right"):
		pass
		wheel_fr.bounce_noise.play()
		wheel_br.bounce_noise.play()
		#midi_percussion(60, 90)
	if Input.is_action_just_pressed("jump"):
		pass
		wheel_bl.bounce_noise.play()
		wheel_br.bounce_noise.play()
		wheel_fl.bounce_noise.play()
		wheel_fr.bounce_noise.play()
		#midi_percussion(61, 90)


func input_flip():
	if (Input.is_action_just_pressed("flip")
	and chassis.linear_velocity.length_squared() < 1.5):
		print(chassis.global_basis.y.dot(Vector3.DOWN))
		if chassis.global_basis.y.dot(Vector3.DOWN) >= 0.0:
			flipped = true
			chassis.apply_central_impulse(Vector3.UP * 70.0)
			chassis.apply_torque_impulse(chassis.global_basis.z * 15.0)
			print("flipped")
	if flipped:
		pass


#func midi_off(instrument: int, velocity: int, pitch: int, channel: int = 0):
	#midi_player.receive_raw_midi_message(make_midi_event(channel, MIDI_MESSAGE_PROGRAM_CHANGE, pitch, velocity, instrument))
	#midi_player.receive_raw_midi_message(make_midi_event(channel, MIDI_MESSAGE_NOTE_OFF, pitch, velocity, instrument))
#
#
#func midi_on(instrument: int, velocity: int, pitch: int, channel: int = 0):
	#midi_player.receive_raw_midi_message(make_midi_event(channel, MIDI_MESSAGE_PROGRAM_CHANGE, pitch, velocity, instrument))
	#midi_player.receive_raw_midi_message(make_midi_event(channel, MIDI_MESSAGE_NOTE_ON, pitch, velocity, instrument))
#
#
#func midi_normal(instrument: int, velocity: int, pitch: int, channel: int = 0):
	#midi_player.receive_raw_midi_message(make_midi_event(channel, MIDI_MESSAGE_PROGRAM_CHANGE, pitch, velocity, instrument))
	#midi_player.receive_raw_midi_message(make_midi_event(channel, MIDI_MESSAGE_NOTE_OFF, pitch, velocity, instrument))
	#midi_player.receive_raw_midi_message(make_midi_event(channel, MIDI_MESSAGE_NOTE_ON, pitch, velocity, instrument))
#
#
#func midi_percussion(instrument: int, velocity: int):
	##midi_player.receive_raw_midi_message(make_midi_event(9, MIDI_MESSAGE_NOTE_OFF, instrument, velocity, 0))
	#midi_player.receive_raw_midi_message(make_midi_event(9, MIDI_MESSAGE_NOTE_ON, instrument, velocity, 0))


func make_midi_event(channel: int,
					message: MIDIMessage,
					pitch: int,
					velocity: int,
					instrument: int = 0) -> InputEventMIDI:
	var msg: InputEventMIDI = InputEventMIDI.new()
	msg.message = message
	msg.channel = channel
	msg.instrument = instrument
	if message == MIDI_MESSAGE_NOTE_ON or message == MIDI_MESSAGE_NOTE_OFF:
		msg.pitch = pitch
		msg.velocity = velocity
	elif message == MIDI_MESSAGE_PITCH_BEND:
		msg.pitch = pitch
	return msg


func set_joint_params(param: Generic6DOFJoint3D.Param, value: float):
	for joint: Generic6DOFJoint3D in joints:
		joint.set_param_y(param, value)

#
#func _on_h_slider_ll_softness_value_changed(value):
	#set_joint_params(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, value)
	#label_value_ll_softness.text = str(value)
#
#func _on_h_slider_ll_restitution_value_changed(value):
	#set_joint_params(Generic6DOFJoint3D.PARAM_LINEAR_RESTITUTION, value)
	#label_value_ll_restitution.text = str(value)
#
#
#func _on_h_slider_ll_damping_value_changed(value):
	#set_joint_params(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING, value)
	#label_value_ll_damping.text = str(value)
#
#
#func _on_h_slider_s_stiffness_value_changed(value):
	#set_joint_params(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, value)
	#label_value_s_stiffness.text = str(value)
#
#
#func _on_h_slider_s_damping_value_changed(value):
	#set_joint_params(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, value)
	#label_value_s_damping.text = str(value)
#
#
#func _on_button_default_button_up():
	#var value = default_joint_params["LLSoftness"]
	#label_value_ll_softness.text = str(value)
	#h_slider_ll_softness.set_value_no_signal(value)
	#set_joint_params(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, value)
	#value = default_joint_params["LLRestitution"]
	#label_value_ll_restitution.text = str(value)
	#h_slider_ll_restitution.set_value_no_signal(value)
	#set_joint_params(Generic6DOFJoint3D.PARAM_LINEAR_RESTITUTION, value)
	#value = default_joint_params["LLDamping"]
	#label_value_ll_damping.text = str(value)
	#h_slider_ll_damping.set_value_no_signal(value)
	#set_joint_params(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING, value)
	#value = default_joint_params["SStiffness"]
	#label_value_s_stiffness.text = str(value)
	#h_slider_s_stiffness.set_value_no_signal(value)
	#set_joint_params(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, value)
	#value = default_joint_params["SDamping"]
	#label_value_s_damping.text = str(value)
	#h_slider_s_damping.set_value_no_signal(value)
	#set_joint_params(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, value)


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
