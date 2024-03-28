extends Node3D


@onready var timer = $Timer
@onready var mesh_instance_3d = $MeshInstance3D
@onready var mesh_instance_3d_2 = $MeshInstance3D2
@onready var mesh_instance_3d_3 = $MeshInstance3D3
@onready var area_3d = $Area3D
@onready var audio_stream_player = $AudioStreamPlayer
@onready var gpu_particles_3d = $GPUParticles3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_3d_body_entered(body):
	if body.is_in_group("chassis") or body.is_in_group("wheel"):
		_pop()


func _pop():
	mesh_instance_3d.visible = false
	mesh_instance_3d_2.visible = false
	mesh_instance_3d_3.visible = false
	set_deferred("monitoring", false)
	timer.start()
	audio_stream_player.play()
	gpu_particles_3d.emitting = true
	


func _on_timer_timeout():
	queue_free()
