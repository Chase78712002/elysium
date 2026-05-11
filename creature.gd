extends StaticBody2D

const MAX_HP = 10
const ATTACK_RANGE: float = 150.0
const ATTACK_DAMAGE: int = 5
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
	if multiplayer.is_server():
		attack_loop()	

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

func attack_loop() -> void:
	while true:
		await get_tree().create_timer(2.0).timeout	
		if not visible:
			continue
		for player in get_tree().get_nodes_in_group("players"):
			var dist = global_position.distance_to(player.global_position)	
			if dist <= ATTACK_RANGE:
				player.take_damage.rpc(ATTACK_DAMAGE)
