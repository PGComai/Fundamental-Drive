extends AnimatableBody3D


var default_y := 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass#default_y = global_position.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_car_position_signal(pos: Vector3):
	var car_pos_xz := Vector2(pos.x, pos.z)
	var my_pos_xz := Vector2(global_position.x, global_position.z)
	var dist = car_pos_xz.distance_squared_to(my_pos_xz) * 0.015
	dist = clampf(dist, 4.0, 1000.0)
	#print(dist)
	global_position.y = default_y - dist + 4.0
	
