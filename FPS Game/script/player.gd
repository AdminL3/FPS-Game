extends CharacterBody3D

@onready var camera = $Camera3D
@onready var animation_player = $AnimationPlayer
@onready var flash = $Camera3D/Pistol/Flash
@onready var raycast = $Camera3D/RayCast3D

signal health_changed(value)

var health = 3

const SPEED = 7
const JUMP_VELOCITY = 8

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	
func _ready():
	if not is_multiplayer_authority(): return
	 
	Input.mouse_mode =  Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		camera.rotate_x(-event.relative.y * 0.005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if Input.is_action_just_pressed("shoot") \
			and animation_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())
	
func _physics_process(delta):
	
	if not is_multiplayer_authority(): return
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "front", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
@rpc("call_local")
func play_shoot_effects():
	animation_player.stop()
	animation_player.play("shoot")
	flash.restart()
	flash.emitting = true

@rpc("any_peer")
func receive_damage():
	health-=1
	if health<=0:
		health=3
		position=Vector3.ZERO
		position.y = 10
	health_changed.emit(health)
		
func _on_animation_player_animation_finished(anim_name):
	if anim_name=="shoot":
		animation_player.play("idle")
