extends CharacterBody2D


const SPEED: float = 300.0
const ARRIVAL_DIST: float = 8.0

@onready var agent:NavigationAgent2D = $NavigationAgent2D
var target_pos: Vector2 = Vector2.ZERO
var has_target: bool = false
var desired_velocity: Vector2 = Vector2.ZERO



func _enter_tree() -> void:
	# Node name is the peer id (server sets this)
	set_multiplayer_authority(int(name))

func _ready() -> void:
	# Avoidance needs this signal to apply the safe velocity	
	agent.velocity_computed.connect(_on_velocity_computed)
	agent.max_speed = SPEED

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			target_pos = get_global_mouse_position()
			has_target = true

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not has_target:
		agent.set_velocity(Vector2.ZERO)
		return
		
	var dist = global_position.distance_to(target_pos)
	if dist <= ARRIVAL_DIST:
		agent.set_velocity(Vector2.ZERO)
		has_target = false
		return
	desired_velocity = global_position.direction_to(target_pos) * SPEED
	agent.set_velocity(desired_velocity)



func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if not is_multiplayer_authority():
		return

	var v := safe_velocity
	if v == Vector2.ZERO and has_target:
		v = desired_velocity
	velocity = v
	move_and_slide()	
