extends Node2D

const PORT := 32100
const MAX_CLIENTS := 32

@onready var players := $Players
var player_scene := preload("res://Player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		start_server()
	else:
		connect_to_server("45.77.215.222")
	
func start_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_CLIENTS)

	if error != OK:
		push_error("Failed to start server %s" % error)
		return

	multiplayer.multiplayer_peer = peer

	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

	_on_player_connected(1)
	print("✅ Server Listening (UDP) on port %d" % PORT)


func connect_to_server(ip: String) -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip, PORT)

	if error != OK:
		push_error("Failed to create client %s" % error)
		return

	multiplayer.multiplayer_peer = peer
	print("✅ Client connecting to %s:%d" % [ip, PORT])

	multiplayer.connected_to_server.connect(func(): print("✅ connected to server"))
	multiplayer.connection_failed.connect(func(): print("💔 connection failed:"))
	multiplayer.server_disconnected.connect(func(): print("⚠️ server disconnected:"))


func _on_player_connected(id: int)-> void:
	print("✅ peer connected:", id)	

	if not multiplayer.is_server():
		return

	var p := player_scene.instantiate()
	p.name = str(id)
	players.add_child(p)
	p.position = Vector2(400,300)

	print("Spawn Player: %s, Position: %s" % [p.name, p.position] )

func _on_player_disconnected(id: int):
	print("👋 peer disconnected:",id)

	if not multiplayer.is_server():
		return

	var node := players.get_node_or_null(str(id))
	if node:
		node.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
