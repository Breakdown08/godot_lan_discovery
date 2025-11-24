class_name Lobby extends Control

@onready var discovery_timer:Timer = $discovery_timer
@onready var devices:VBoxContainer = $margin/panel/scroll/devices

const DISCOVERY_PASSWORD:String = "DnAGD"
const DISCOVERY_DELIMITER:String = ";"
const MULTICAST_GROUP:String = "224.0.0.1"
const DISCOVERY_PORT:int = 5555

const DEVICE_DATA_STATUS:String = "status"
const DEVICE_DATA_RECONNECTS_COUNT:String = "reconnects_count"
const DEVICE_DATA_IS_HOST:String = "is_host"
const DEVICE_DATA_ID:String = "id"

const DEVICE:PackedScene = preload("res://modules/lobby/device/device.tscn")

enum Status {DISCOVERY, ALIVE, TIMEOUT, DISCONNECTED}

var _discovery_connection:PacketPeerUDP

var id:String = ""
var port:int = 0

var id_table:Dictionary[String, Dictionary]

signal device_data_updated(device_id:String, device_data:Dictionary)


func _ready() -> void:
	set_process(false)
	discovery_timer.timeout.connect(_discovery)


func start() -> void:
	set_process(true)
	id = _get_local_ip_address()
	_discovery_connection = PacketPeerUDP.new()
	_discovery_connection.set_broadcast_enabled(true)
	_discovery_connection.set_dest_address(MULTICAST_GROUP, DISCOVERY_PORT)
	for iface in IP.get_local_interfaces():
		if iface.addresses[0].begins_with("192.168."):
			var bind_result:Error = _discovery_connection.join_multicast_group("224.0.0.1", iface.name)
			Console.write("bind_result %s" % str(bind_result))
	discovery_timer.start()


func _discovery():
	var device_data:Dictionary = _create_device_data(id)
	_discovery_connection.put_packet(str("%s%s%s" % [
			DISCOVERY_PASSWORD, 
			DISCOVERY_DELIMITER, 
			JSON.stringify(device_data)
		]
	).to_utf8_buffer())
	Console.write("discovery sent '%s-%s'" % [DISCOVERY_PASSWORD, id])


func _get_local_ip_address() -> String:
	var local_ips = IP.get_local_addresses()
	for result in local_ips:
		if result.begins_with("192.168."):
			return result
	return ""


func _process(_delta):
	while _discovery_connection.get_available_packet_count() > 0:
		var packet = _discovery_connection.get_packet()
		var received_data = packet.get_string_from_utf8()
		var sender_id:String = ""
		if received_data.begins_with(DISCOVERY_PASSWORD):
			var device_data:Dictionary = JSON.parse_string(received_data.split(DISCOVERY_DELIMITER)[1])
			sender_id = device_data[DEVICE_DATA_ID]
			if sender_id != self.id:
				if not id_table.has(sender_id):
					id_table[sender_id] = device_data
					devices.add_child(_create_device(sender_id, device_data))
					Console.write("Device found: %s" % sender_id)
				else:
					id_table[sender_id][DEVICE_DATA_STATUS] = Status.ALIVE
					id_table[sender_id][DEVICE_DATA_RECONNECTS_COUNT] = 0
					device_data_updated.emit(sender_id, id_table[sender_id])


func _create_device_data(device_id:String) -> Dictionary:
	var device_data:Dictionary = {
		DEVICE_DATA_STATUS : Status.DISCOVERY,
		DEVICE_DATA_RECONNECTS_COUNT : 0,
		DEVICE_DATA_IS_HOST : false,
		DEVICE_DATA_ID : device_id
	}
	return device_data


func _create_device(device_id:String, device_data:Dictionary) -> Device:
	var device:Device = DEVICE.instantiate()
	device.id = device_id
	device.data = device_data
	device_data_updated.connect(device.on_device_data_updated)
	return device


#func start() -> void:
	#set_process(true)
	#_discovery_connection = PacketPeerUDP.new()
	#_discovery_connection.set_broadcast_enabled(true)
	#var bind_result:Error = _discovery_connection.bind(DISCOVERY_PORT)
	#Console.write("[DISCOVERY_CONNECTION]: PORT BIND RESULT: %s" % bind_result)
	#_private_connection = PacketPeerUDP.new()
	#_private_connection.set_broadcast_enabled(true)
	#_private_connection.bind(port)
	#port = _private_connection.get_local_port()
	#id = "%s:%s" % [_get_local_ip_address(), str(port)]
	#Console.write("Started with id %s" % id)
	#_discovery_connection.set_dest_address(BROADCAST_MASK, DISCOVERY_PORT)
	#discovery_timer.start()
