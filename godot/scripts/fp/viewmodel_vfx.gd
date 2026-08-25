class_name ViewModelVfx
extends Node3D
## Muzzle flash, shell eject — quality-tiered VFX for FP viewmodel.

@export var quality: int = 2

var _muzzle_light: OmniLight3D
var _flash_left: float = 0.0
var _shell_particles: GPUParticles3D


func _ready() -> void:
	_muzzle_light = OmniLight3D.new()
	_muzzle_light.name = "MuzzleLight"
	_muzzle_light.light_color = Color(1.0, 0.67, 0.27)
	_muzzle_light.light_energy = 0.0
	_muzzle_light.omni_range = 3.0
	_muzzle_light.shadow_enabled = false
	_muzzle_light.layers = 2
	add_child(_muzzle_light)

	_shell_particles = GPUParticles3D.new()
	_shell_particles.name = "ShellEject"
	_shell_particles.emitting = false
	_shell_particles.one_shot = true
	_shell_particles.amount = 1
	_shell_particles.lifetime = 0.45
	_shell_particles.explosiveness = 1.0
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.4, 0.6, 0.2)
	pm.spread = 18.0
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 2.4
	pm.gravity = Vector3(0, -4.5, 0)
	pm.scale_min = 0.015
	pm.scale_max = 0.025
	_shell_particles.process_material = pm
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.012
	sm.height = 0.024
	mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.72, 0.22)
	mat.metallic = 0.85
	mat.roughness = 0.25
	mesh.material_override = mat
	_shell_particles.draw_pass_1 = sm
	_shell_particles.layers = 2
	add_child(_shell_particles)


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(0.0, _flash_left - delta)
		if _muzzle_light:
			_muzzle_light.light_energy = _flash_left * 12.0


func trigger_muzzle(pos: Vector3, heavy: bool = false) -> void:
	if quality < 1:
		return
	_muzzle_light.global_position = pos
	_flash_left = 0.06 if not heavy else 0.09


func trigger_shell(pos: Vector3) -> void:
	if quality < 2:
		return
	_shell_particles.global_position = pos
	_shell_particles.restart()
	_shell_particles.emitting = true


func set_quality(q: int) -> void:
	quality = q
