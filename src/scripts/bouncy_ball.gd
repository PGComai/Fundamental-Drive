extends RigidBody3D

@onready var meshy = $Mesh

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#meshy.visible = linear_velocity.length_squared() > 1.0 or get_contact_count() == 0
	meshy.mesh.text = str(round(linear_velocity.length()))
