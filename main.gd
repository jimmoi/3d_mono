extends Node3D

@export var default_rotation_speed = 30.0 # Use floating point for speed
@export var min_barrel_angle = -60 # Example: Minimum angle (horizontal)
@export var max_barrel_angle = -5 # Example: Maximum angle (vertical)
@export var initial_barrel_angle = -45
@export var bullet_trajectory = preload("res://trajectory.tscn")
var explosion_effect = preload("res://explosion.tscn")
@export var bullet_speed = 10 # m/s

var mortar
var mortar_barrel
var mortar_muzzle
var mortar_status = true # True is ready, False is reloading
var rotation_speed: float
enum fine_tune_mode {ELE, AZI}
var current_fine_tune_mode = fine_tune_mode["ELE"]
var mortar_barrel_length: float

var last_track
var main_cam
var shell_cam

func _ready() -> void:
	mortar = $motar
	mortar_barrel = $motar/mesh/body
	mortar_muzzle = $motar/mesh/body/mesh_muzzle
	mortar_barrel.rotation.x = deg_to_rad(initial_barrel_angle)
	mortar_barrel_length = mortar_barrel.get_node("mesh_barrel").mesh.height	
	main_cam = $motar/Camera3D
	
func _physics_process(delta: float) -> void:
	mortar_movement(delta)
	mortar_movement_fine()
	mortar_barrel.rotation.x = deg_to_rad(clamp(rad_to_deg(mortar_barrel.rotation.x), min_barrel_angle, max_barrel_angle))
	show_text()
	fire_trajectory()
	switch_shell_camera()
	
func mortar_movement(delta):
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

	
func mortar_movement_fine():
	if Input.is_action_just_pressed("change_mode"):
		current_fine_tune_mode = (current_fine_tune_mode+1)%len(fine_tune_mode)
	
	match current_fine_tune_mode:
		fine_tune_mode.AZI:
			if Input.is_action_just_pressed("fine_tune_up"):
				mortar.rotate_y(deg_to_rad(0.1))
			elif Input.is_action_just_pressed("fine_tune_down"):
				mortar.rotate_y(deg_to_rad(-0.1))
		fine_tune_mode.ELE:
			if Input.is_action_just_pressed("fine_tune_up"):
				mortar_barrel.rotate_x(deg_to_rad(-0.1))
			elif Input.is_action_just_pressed("fine_tune_down"):
				mortar_barrel.rotate_x(deg_to_rad(0.1))
	pass
func show_text():
	var azimuth = rad_to_deg(mortar.rotation.y)
	var elevation = -rad_to_deg(mortar_barrel.rotation.x)
	$ui/motar_property.text = "Battery Status\n" +\
	"Elevation: %.2f\n" % elevation +\
	"Azimuth: %.2f\n" % (-azimuth if -azimuth > 0 else 360-azimuth) +\
	"Fine-tune mode: %s\n" % fine_tune_mode.keys()[current_fine_tune_mode]
	#################################
	if mortar_status:
		$ui/mortar_status.self_modulate = Color.GREEN
		$ui/mortar_status.text = "Ready"
	else:
		$ui/mortar_status.self_modulate = Color.RED
		$ui/mortar_status.text = "Reloading"
	#################################
	if last_track != null:
		$ui/shell_status.text = "Shell Status\n" +\
		"Shell Velocity: %.2f\n" % last_track.linear_velocity.length() +\
		"Shell Velocity-up: %.2f\n" % last_track.linear_velocity.y +\
		"Shell Velocity-forwad: %.2f\n" % sqrt(last_track.linear_velocity.x**2 + last_track.linear_velocity.z**2) +\
		"Shell height: %.2f\n" % last_track.global_position.y +\
		"Shell distance-battery: %.2f\n" % (last_track.global_position - mortar.global_position).length()
	else:
		$ui/shell_status.text = "Shell Status\n" +\
		"No last shell"
func fire_trajectory():
	if Input.is_action_just_pressed("fire") and mortar_status:
		$sfx/fire.play()
		var bullet_obj = bullet_trajectory.instantiate()
		bullet_obj.explode.connect(create_explosion)
		last_track = bullet_obj
		add_child(bullet_obj)
		
		bullet_obj.global_transform = mortar_muzzle.global_transform
		var forward_vector: Vector3 = bullet_obj.global_transform.basis.y
		bullet_obj.linear_velocity = forward_vector * bullet_speed
		mortar_status = false
		$reload_cool_down.start()

func switch_shell_camera():
	if (last_track != null) and Input.is_action_pressed("switch_cam"):
		shell_cam = last_track.get_node("camera")
		shell_cam.make_current()
	else:
		main_cam.make_current()
		
func _on_reload_cool_down_timeout() -> void:
	mortar_status = true
	
func create_explosion(position):
	$sfx/explode.play()
	var explosion = explosion_effect.instantiate()
	explosion.global_position = position
	add_child(explosion)
