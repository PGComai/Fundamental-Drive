extends AnimatableBody3D


@export var radius := 2000.0
@export var origin := Vector3(0.0, 0.0, 0.0)
@export var enabled := true


var target_pos: Vector3


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if target_pos and enabled:
		var goto = target_pos.normalized()
		if goto.is_equal_approx(Vector3.UP):
			look_at(global_position + goto, Vector3.LEFT)
		elif goto.is_equal_approx(Vector3.LEFT):
			look_at(global_position + goto, Vector3.UP)
		else:
			look_at(global_position + goto, Vector3.UP)


func _on_car_position_signal(pos):
	pass#target_pos = pos
