extends CharacterBody2D


const SPEED: float = 300.0
const ARRIVAL_DIST: float = 8.0

var target_pos: Vector2 = Vector2.ZERO
var has_target: bool = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			target_pos = get_global_mouse_position()
			has_target = true

func _physics_process(delta: float) -> void:
	if not has_target:
		velocity = Vector2.ZERO
		move_and_slide()
		
	var dist = global_position.distance_to(target_pos)
	if dist <= ARRIVAL_DIST:
		velocity = Vector2.ZERO
		has_target = false
	else:
		var dir = global_position.direction_to(target_pos)
		velocity = dir * SPEED
	
	move_and_slide()
		
