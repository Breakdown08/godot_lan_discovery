class_name Device extends Control

@onready var master_tag:Label = $margin/props/master_tag
@onready var address:Label = $margin/props/id
@onready var status:Panel = $status
@onready var status_timer:Timer = $status_timer

var id:String = ""
var data:Dictionary = {}

func _ready() -> void:
	name = id
	address.text = name
	status_timer.timeout.connect(_on_status_timer_timeout)


func on_device_data_updated(device_id:String, device_data:Dictionary):
	data = device_data
	#if device_id == id:
		#match data[Lobby.DEVICE_DATA_STATUS]:
			#Lobby.Status.DISCONNECTED:
				#status.modulate = Color.RED
			#Lobby.Status.TIMEOUT:
				#status.modulate = Color.GRAY
			#Lobby.Status.ALIVE:
				#status.modulate = Color.GREEN
			#Lobby.Status.DISCOVERY:
				#status.modulate = Color.YELLOW
		#master_tag.visible = true if device_data[Lobby.DEVICE_DATA_IS_HOST] else false


func on_device_disconnected(device_id:String):
	if device_id == id: queue_free()


func _on_status_timer_timeout():
	prints()
