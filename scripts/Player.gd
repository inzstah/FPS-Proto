extends CharacterBody3D

# Player nodes
@onready var neck = $Neck
@onready var head = $Neck/Head
@onready var standing_collision_shape = $StandingCollisionShape
@onready var crouching_collision_shape = $CrouchingCollisionShape
@onready var ray_cast_3d = $RayCast3D
@onready var camera_3d = $Neck/Head/Eyes/Camera3D

# Speed vars
var current_speed = 5.0

var walking_speed = 5.0
var sprinting_speed = 8.0
var crouching_speed = 3.0

# States
var walking = false
var sprinting = false
var crouching = false
var sliding = false
var free_looking = false
var can_jump = true

# Slide vars
var slide_timer = 0.0
var max_slide_timer = 0.5
var slide_vector = Vector2.ZERO
var slide_speed = 20.0

# Movement vars
var jump_velocity = 4.5

var lerp_speed = 10.0
var air_lerp_speed = 3.0

var crouching_depth = -0.5

var free_look_tilt_amount = 0.0

# Input vars
var direction = Vector3.ZERO
var mouse_sens = 0.1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Looking around with mouse
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			# neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	
	# Movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
		
	# Handle movement states
	
	# Crouching
	if Input.is_action_pressed("crouch") || sliding:
		
		current_speed = lerp(current_speed, crouching_speed, delta * lerp_speed)
		
		head.position.y = lerp(head.position.y, 1.8 + crouching_depth, delta*lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		#Slide begin logic
		
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = max_slide_timer
			slide_vector = input_dir
			free_looking = false
			print("Sliding starts")
		
		walking = false
		sprinting = false
		crouching = true
	
	elif !ray_cast_3d.is_colliding():
	
	# Standing
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		
		head.position.y = lerp(head.position.y, 1.8, delta*lerp_speed)
		
		if Input.is_action_pressed("sprint"):
			# Sprinting
			current_speed = lerp(current_speed,sprinting_speed, delta*lerp_speed)
			
			walking = false
			sprinting = true
			crouching = false
		else:
			# Walking
			current_speed = lerp(current_speed,walking_speed, delta*lerp_speed)
			
			walking = true
			sprinting = false
			crouching = false
	
	# Handle free looking
	if Input.is_action_pressed("free_look") && sliding:
		free_looking = true
		# camera_3d.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt_amount)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta*lerp_speed)
		# camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, delta*lerp_speed)
	# Handle sliding
	if sliding:
		can_jump = false
		slide_timer -= delta
		if slide_timer <= 0.1:
			sliding = false
			print("Sliding ends")
			free_looking = false
			can_jump = true
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and can_jump:
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*air_lerp_speed)
	
	if sliding: 
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		current_speed = (slide_timer + 0.15) * slide_speed
		
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
