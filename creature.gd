extends StaticBody2D

const MAX_HP = 10
var hp = MAX_HP
var spawn_position: Vector2 = Vector2.ZERO

@rpc("any_peer", "call_local","reliable")
func take_damage(amount:int) -> void:
	hp -= amount
	prints("creature taking damage", amount)
	prints(name, "HP:", hp)
	
	if hp <= 0:
		prints(name, "is dead")
		if multiplayer.is_server():
			respawn()

func _ready() -> void:
	spawn_position = global_position
	
@rpc("authority","call_local","reliable")
func set_visiblity(value: bool) -> void:
	visible = value
	
func respawn() -> void:
	set_visiblity.rpc(false)
	prints("Respawning...")
	await get_tree().create_timer(5.0).timeout
	hp = MAX_HP
	global_position = spawn_position
	set_visiblity.rpc(true)
