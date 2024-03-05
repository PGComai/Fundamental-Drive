extends RigidBody3D

@onready var meshy = $Mesh

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#apply_central_force(-global_position.normalized() * delta * 4000.0)
	meshy.mesh.text = str(round(linear_velocity.length()))
