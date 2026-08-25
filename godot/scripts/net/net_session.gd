extends Node
## Autoload NetSession — offline-first multiplayer stub (64 Hz tick).

signal connected(peer_id: int)
signal disconnected
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

enum Mode { OFFLINE, LISTEN, DEDICATED_CLIENT }

const DEFAULT_PORT := 7777
const TICK_HZ := 64

var mode: Mode = Mode.OFFLINE
var peer_id: int = 1
var tick: int = 0
var port: int = DEFAULT_PORT

var _peer: MultiplayerPeer


func _ready() -> void:
	mode = Mode.OFFLINE
	peer_id = 1
	if multiplayer:
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _physics_process(_delta: float) -> void:
	tick += 1


func host_lan(p_port: int = DEFAULT_PORT) -> Error:
	disconnect_session()
	port = p_port
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, 10)
	if err != OK:
		push_warning("NetSession: host_lan failed %s — staying offline" % err)
		mode = Mode.OFFLINE
		peer_id = 1
		return err
	_peer = peer
	multiplayer.multiplayer_peer = peer
	mode = Mode.LISTEN
	peer_id = multiplayer.get_unique_id()
	connected.emit(peer_id)
	return OK


func join_lan(ip: String, p_port: int = DEFAULT_PORT) -> Error:
	disconnect_session()
	port = p_port
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		push_warning("NetSession: join_lan failed %s — staying offline" % err)
		mode = Mode.OFFLINE
		peer_id = 1
		return err
	_peer = peer
	multiplayer.multiplayer_peer = peer
	mode = Mode.DEDICATED_CLIENT
	peer_id = multiplayer.get_unique_id()
	connected.emit(peer_id)
	return OK


func disconnect_session() -> void:
	if multiplayer and multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer = null
	_peer = null
	mode = Mode.OFFLINE
	peer_id = 1
	disconnected.emit()


func is_online() -> bool:
	return mode != Mode.OFFLINE


func _on_peer_connected(id: int) -> void:
	peer_joined.emit(id)


func _on_peer_disconnected(id: int) -> void:
	peer_left.emit(id)
