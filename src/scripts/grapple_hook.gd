extends RigidBody3D


@export var force := 10.0
@export var launch := false:
	set(value):
		if value:
			_launch()


static var rope_points: Array[Vector3]

var ready_to_grab := false
var grabbing_now := false
var retracting := false
var retracted := true
var grab_point: Vector3


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	if retracting:
		position = lerp(position, Vector3.ZERO, 0.3)
		if position.is_equal_approx(Vector3.ZERO):
			print("back")
			retracting = false
			retracted = true
			visible = false


func _launch():
	if retracted:
		visible = true
		retracted = false
		print("launch")
		top_level = false
		global_transform = get_parent().global_transform
		grabbing_now = false
		ready_to_grab = true
		freeze = false
		apply_central_impulse(-global_basis.z * force)
	elif not retracting:
		print("unlaunch")
		grab_point = global_position
		top_level = false
		freeze = true
		#position = to_local(grab_point)
		retracting = true
		grabbing_now = false


func _on_body_entered(body):
	if ready_to_grab:
		if true:#body.is_in_group("grabbable"):
			ready_to_grab = false
			grabbing_now = true
			freeze = true
			top_level = true
			grab_point = global_position
			print("grab")
