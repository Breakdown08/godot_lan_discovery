extends Control

@onready var lobby:Lobby = $margin/panel/zones/lobby
@onready var console:Console = $margin/panel/zones/console


func _ready() -> void:
	console.start()
	lobby.start()
