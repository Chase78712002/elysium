extends CharacterBody2D


const SPEED = 300.0
var target_pos
func _physics_process(delta: float) -> void:
	move_and_slide()
	position += target_pos

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print("Viewport Resolution:", get_viewport().get_visible_rect().size)
		target_pos = get_global_mouse_position()
		print("Mouse sets to target pos:", target_pos)
