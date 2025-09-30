extends Node3D

@export var default_rotation_speed = 30.0 # Use floating point for speed
@export var min_barrel_angle = -60 # Example: Minimum angle (horizontal)
@export var max_barrel_angle = -5 # Example: Maximum angle (vertical)
@export var initial_barrel_angle = -45

var mortar: Node3D
var mortar_barrel: Node3D
var rotation_speed: float
# Variable to track the barrel's rotation to clamp it


func _ready() -> void:

	mortar = $motar
	
	mortar_barrel = $motar/mesh/body
	mortar_barrel.rotation.x = deg_to_rad(initial_barrel_angle)

func _physics_process(delta: float) -> void:
	rotation_speed = default_rotation_speed
	if Input.is_key_pressed(KEY_SHIFT):
		rotation_speed *= 2.0
	
	if Input.is_key_pressed(KEY_CTRL):
		rotation_speed *= 0.5

	# --- Mortar Base Rotation (Yaw) ---
	var delta_rotation = rotation_speed * delta
	
	if Input.is_action_pressed("left"):
		mortar.rotate_y(deg_to_rad(delta_rotation))
	elif Input.is_action_pressed("right"):
		mortar.rotate_y(deg_to_rad(-delta_rotation))

	# --- Mortar Barrel Rotation (Pitch) ---
	var barrel_rotation_amount = 0.0
	
	if Input.is_action_pressed("up"):
		mortar_barrel.rotate_x(deg_to_rad(-delta_rotation))
	elif Input.is_action_pressed("down"):
		mortar_barrel.rotate_x(deg_to_rad(delta_rotation))

	mortar_barrel.rotation.x = deg_to_rad(clamp(rad_to_deg(mortar_barrel.rotation.x), min_barrel_angle, max_barrel_angle))
	
	
	show_mortar_property()
	
func show_mortar_property():
	var elevation = rad_to_deg(mortar.rotation.y)
	var azimuth = -rad_to_deg(mortar_barrel.rotation.x)
	$ui/Label.text = "Elevation: %.2f" % elevation + "\n" + "Azimuth: %.2f" % azimuth
	
