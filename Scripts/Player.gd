extends CharacterBody3D

# Movement
var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003 # TODO: Make this configurable
const HIT_STAGGER = 8.0

# Head bob
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0 # track locatoin on sign wave

const GROUND_INERTIA = 7.0
const AIR_CONTROL_MODIFIER = 3.0

# FOV vars
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5
const FOV_DIFF_PERCENT = 8.0

# signal
signal player_hit

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Get the input direction and handle the movement/deceleration.
	# TODO: Replace UI actions with custom gameplay actions
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * GROUND_INERTIA)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * GROUND_INERTIA)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * AIR_CONTROL_MODIFIER)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * AIR_CONTROL_MODIFIER)
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE + velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * FOV_DIFF_PERCENT)
	
	move_and_slide()
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ) * BOB_AMP
	return pos
	
func hit(dir):
	emit_signal("player_hit")
	velocity += dir * HIT_STAGGER
