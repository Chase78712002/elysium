extends Node2D

const PORT := 32100
const MAX_CLIENTS := 32


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		start_server()
	
func start_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_CLIENTS)

	if error != OK:
		push_error("Failed to start server %s" % error)
		return

	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(func(): print("✅ connected to server"))
	print("✅ Server Listening (UPD) on port %d" % PORT)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
