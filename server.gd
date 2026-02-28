extends Node2D

const PORT := 32100
const MAX_CLIENTS := 32


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		start_server()
	else:
		connect_to_server("127.0.0.1")
	
func start_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_CLIENTS)

	if error != OK:
		push_error("Failed to start server %s" % error)
		return

	multiplayer.multiplayer_peer = peer

	multiplayer.peer_connected.connect(func(id): print("✅ peer connected:", id))
	multiplayer.peer_disconnected.connect(func(id): print("👋 peer disconnected:",id))
	print("✅ Server Listening (UPD) on port %d" % PORT)

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
