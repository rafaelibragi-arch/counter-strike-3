class_name MoveConfig
extends Resource
## CS2-scaled Source movement constants (Clashpoint meters).
## Source 250u run → 6 m/s; air wishspeed cap 30u → 0.72 m/s.

@export_group("Speeds")
@export var run_speed: float = 6.0
@export var walk_speed: float = 3.12
@export var crouch_mul: float = 0.34

@export_group("Acceleration / Friction")
@export var ground_accel: float = 5.5
@export var air_accel: float = 12.0
@export var friction: float = 5.2
@export var stop_speed: float = 1.92
## Source GetAirSpeedCap() = 30u. Scaled: 30/250 * run_speed ≈ 0.72
@export var air_wish_cap: float = 0.72
@export var max_velocity: float = 84.0

@export_group("Jump / Gravity")
@export var jump_vel: float = 7.25
@export var gravity: float = 19.2
## Pre-input window (seconds). ~2 ticks at 64 Hz (CS-like skill window).
@export var jump_buffer: float = 0.03125
## When true, holding jump refreshes buffer in air (CS autobhop). Default OFF.
@export var autobhop: bool = false

@export_group("Capsule")
@export var capsule_radius: float = 0.4
@export var standing_height: float = 1.8
@export var crouch_height: float = 1.15
@export var eye_standing: float = 1.7
## Below crouch capsule top so camera does not clip ceilings.
@export var eye_crouch: float = 0.95
@export var step_height: float = 0.45

@export_group("Look")
@export var mouse_sensitivity: float = 0.0022
@export var max_pitch: float = 1.45
