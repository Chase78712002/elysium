extends CharacterBody2D


const SPEED: float = 300.0
const ARRIVAL_DIST: float = 8.0
const SEPARATION_DIST: float = 150.0
const ATTACK_RANGE: float = 200.0
const MAX_HP: int = 100
@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
var target_pos: Vector2 = Vector2.ZERO
var has_target: bool = false
var is_attacking: bool = false
var hp: int = MAX_HP
var spawn_position: Vector2 = Vector2.ZERO
var desired_velocity: Vector2 = Vector2.ZERO
@export var sync_velocity: Vector2 = Vector2.ZERO
@export var player_display_name: String = ""

func _enter_tree() -> void:
	# Node name is the peer id (server sets this)
	set_multiplayer_authority(int(name))
func _ready() -> void:
	# Avoidance needs this signal to apply the safe velocity
	agent.max_speed = SPEED
	spawn_position = global_position
	anim_sprite.play("idle")
	anim_sprite.animation_finished.connect(_on_attack_finished)
	$NameLabel.text = player_display_name if player_display_name != "" else name 
	
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
			var clicked_pos = get_global_mouse_position()
			has_target = true

			# Ask physics world: what's at this position
			var space = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			
			query.position = clicked_pos
			var results = space.intersect_point(query)
			
			var clicked_creature = null
			for result in results:
				if result.collider.is_in_group("creatures"):
					clicked_creature = result.collider
					break
					
			if clicked_creature:
				var dist = global_position.distance_to(clicked_creature.global_position)
				if dist <= ATTACK_RANGE:
					is_attacking = true
					anim_sprite.play("attack")
					clicked_creature.take_damage.rpc_id(1,1)
				else:
					target_pos = clicked_creature.global_position
					has_target = true
			else:
				target_pos = clicked_pos
				has_target = true

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not has_target:
		velocity = Vector2.ZERO
		sync_velocity = Vector2.ZERO
		if not is_attacking:
			anim_sprite.play("idle")
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
	
	if not is_attacking:
		if velocity != Vector2.ZERO:
			anim_sprite.play("walk")
		else:
			anim_sprite.play("idle")

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

func _on_attack_finished()->void:
	if anim_sprite.animation == "attack":
		is_attacking = false
		anim_sprite.play("idle")

@rpc("authority","call_local","reliable")
func take_damage(amount: int) -> void:
	hp -= amount
	prints(name, "HP:", hp)
	if hp <= 0:
		restart()

func restart() -> void:
	pass
