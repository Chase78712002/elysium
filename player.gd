extends CharacterBody2D


const SPEED: float = 300.0
const ARRIVAL_DIST: float = 8.0
const SEPARATION_DIST: float = 150.0

@onready var agent:NavigationAgent2D = $NavigationAgent2D
var target_pos: Vector2 = Vector2.ZERO
var has_target: bool = false
var desired_velocity: Vector2 = Vector2.ZERO
@export var sync_velocity: Vector2 = Vector2.ZERO


func _enter_tree() -> void:
	# Node name is the peer id (server sets this)
	set_multiplayer_authority(int(name))
func _ready() -> void:
	# Avoidance needs this signal to apply the safe velocity
	agent.max_speed = SPEED
	$NameLabel.text = name
	
	if is_multiplayer_authority():
		$Camera2D.enabled = true
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			target_pos = get_global_mouse_position()
			has_target = true

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not has_target:
		velocity = Vector2.ZERO
		sync_velocity = Vector2.ZERO
		return
		
	var dist = global_position.distance_to(target_pos)
	if dist <= ARRIVAL_DIST:
		velocity = Vector2.ZERO
		sync_velocity = Vector2.ZERO
		has_target = false
		return
		
	desired_velocity = global_position.direction_to(target_pos) * SPEED
	velocity = desired_velocity
	sync_velocity = velocity
	move_and_slide()
	apply_player_separation()

func apply_player_separation()-> void:
	for other in get_tree().get_nodes_in_group("players"):
		if other == self:
			continue

		if not other is CharacterBody2D:
			continue

		var offset :Vector2 = global_position - other.global_position
		var dist :float = offset.length()
		
		if dist == 0.0:
			continue

		if dist < SEPARATION_DIST:
			var push :Vector2 = offset.normalized() * (SEPARATION_DIST - dist)
			global_position += push
	pass
