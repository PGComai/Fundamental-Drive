extends RigidBody3D

const THROTTLE_MULTIPLIER = 3500.0
const STRAIGHT_MULTIPLIER = 2500.0


@export var throttle := 0.0
@export var car: Node3D
@export var diameter: float
@export var mesh: MeshInstance3D
@export var smoke: GPUParticles3D
@export var attractor: GPUParticlesAttractorSphere3D


var wheel_angular_velocity: float
var braking_multiplier := 1.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _physics_process(delta):
	if get_contact_count() > 0:
		var vel = linear_velocity
		var velnorm = vel.normalized()
		var vxz = velnorm.dot(-global_basis.x)
		var vel_len = clampf(vel.length(), 1.0, 50.0)
		wheel_angular_velocity = vel.length() * PI * diameter
		if not is_zero_approx(wheel_angular_velocity):
			mesh.rotate_object_local(Vector3.UP, wheel_angular_velocity)
		var absvxz = car.grip_curve.sample_baked(1.0 - abs(vxz))
		var sideways = car.sideways_curve.sample_baked(abs(vxz))
		if smoke:
			smoke.emitting = absvxz < 0.6 and vel_len > 1.0
			if attractor:
				attractor.strength = abs(throttle) * 128.0
		apply_central_force(global_basis.x * vxz * delta * STRAIGHT_MULTIPLIER * vel_len * sideways * absvxz)
		apply_central_force(global_basis.z * throttle * delta * THROTTLE_MULTIPLIER * absvxz * braking_multiplier)
	else:
		smoke.emitting = false
