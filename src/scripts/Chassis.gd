extends RigidBody3D

@onready var cam_base = $CamBase

var look_dir := Vector3.FORWARD

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if linear_velocity.length_squared() < 0.5:
		look_dir = look_dir.slerp(-global_basis.z, 0.03)
	else:
		look_dir = look_dir.slerp(linear_velocity, 0.1)
	look_dir.y *= 0.2
	cam_base.look_at(global_position + look_dir, Vector3.UP)


func _physics_process(delta):
	pass