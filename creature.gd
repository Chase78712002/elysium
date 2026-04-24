extends StaticBody2D

const MAX_HP = 10
var hp = MAX_HP

func take_damage(amount:int) -> void:
	hp -= amount
	prints("creature taking damage", amount)
	prints(name, "HP:", hp)
	
	if hp <= 0:
		if multiplayer.is_server():
			queue_free()
		prints(name, "is dead")
