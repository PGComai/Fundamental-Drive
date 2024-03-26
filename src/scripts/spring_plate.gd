extends Node3D
class_name SpringPlate


const SPRING_FORCE = 40000.0
const DEFAULT_MASS = 1.0
const DEFAULT_PITCH = 1.0


@export var plate_radius := 5.0:
	set(value):
		plate_radius = clampf(value, 5.0, 40.0)
		_set_plate_radius()


var base_distance := 0.0
var plate_material: ShaderMaterial
var potential_energy := 0.0:
	set(value):
		potential_energy = clampf(value, 0.0, 1.0)
var emission_energy := 0.0:
	set(value):
		emission_energy = clampf(value, 0.0, 1.0)
		if plate_material:
			if not is_zero_approx(emission_energy):
				plate_material.set_shader_parameter("Emission", emission_energy)
			else:
				plate_material.set_shader_parameter("Emission", 0.0)
var diff := 0.0
var normal_pitch := 1.0

@onready var base = $Base
@onready var plate = $Plate
@onready var collision_shape_3d = $Plate/CollisionShape3D
@onready var mesh_instance_3d = $Plate/CollisionShape3D/MeshInstance3D
@onready var audio_stream_player_3d = $AudioStreamPlayer3D
@onready var timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready():
	base_distance = base.global_position.distance_squared_to(plate.global_position)
	_set_plate_radius()
	plate_material = mesh_instance_3d.get_surface_override_material(0)


func _process(delta):
	if potential_energy > 0.1:
		emission_energy += potential_energy
		if not audio_stream_player_3d.playing:
			audio_stream_player_3d.play()
			timer.start()
	else:
		emission_energy = lerp(emission_energy, 0.0, 0.01)
	var spring_audio = remap(diff, -6.0, 6.0, -0.7, 0.7)
	audio_stream_player_3d.pitch_scale = normal_pitch + clamp(spring_audio, -0.7, 0.7)
	audio_stream_player_3d.volume_db = remap(potential_energy, 0.0, 1.0, -10.0, 0.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var current_distance = base.global_position.distance_squared_to(plate.global_position)
	diff = base_distance - current_distance
	potential_energy = remap(abs(diff), 0.0, 6.0, 0.0, 1.0)
	plate.apply_central_force(base.global_basis.y * delta * diff * SPRING_FORCE)


func _set_plate_radius():
	print("setting plate radius: %s" % plate_radius)
	collision_shape_3d.shape.radius = snappedf(plate_radius, 1.0)
	mesh_instance_3d.mesh.top_radius = snappedf(plate_radius, 1.0)
	mesh_instance_3d.mesh.bottom_radius = snappedf(plate_radius, 1.0)
	audio_stream_player_3d.unit_size = plate_radius * (5.0 / 3.0)
	normal_pitch = remap(-plate_radius, -40.0, -5.0, 0.3, 1.0)
	plate.mass = remap(plate_radius, 5.0, 40.0, 1.0, 5.0)


func _on_timer_timeout():
	if potential_energy <= 0.1:
		audio_stream_player_3d.stop()
	else:
		timer.start()
