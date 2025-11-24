class_name Console extends Control

static var instance:TextEdit


func  _ready() -> void:
	instance = $margin/panel/scroll/console


func start():
	pass


static func write(data):
	instance.text += "%s\n" % str(data)
