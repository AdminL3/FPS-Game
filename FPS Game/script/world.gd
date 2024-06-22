extends Node

@onready var menu = $CanvasLayer/Menu
const Player = preload("res://scenes/player.tscn")
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar

func _unhandled_input(event):
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()



func _ready():
	if OS.has_feature("dedicated_server"):
		print("Starting dedicated server...")
		_on_host_pressed()
	else:
		_on_join_pressed()



func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()
	menu.hide()
	hud.show()
	peer.create_server(8080)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _on_join_pressed():
	print("Connecting to server")
	menu.hide()
	hud.show()
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("52.138.195.100", 8080)
	multiplayer.multiplayer_peer = peer

func _on_peer_connected(id):
	print("Client connected with ID: %d" % id)
	addplayer(id)
	
func _on_peer_disconnected(id):
	print("Client disconnected with ID: %d" % id)
	remove_player(id)
	
func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
		
func addplayer(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
	
func update_health_bar(value):
	health_bar.value = value


func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)
