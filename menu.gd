extends Node

# The project starts here instead of loading main.tscn immediately.  Keeping
# the menu in its own tiny scene matters on the web: loading main.gd also loads
# every model referenced by its preload constants, and the fully built room
# used to keep rendering behind the menu.
const SHELL_SCRIPT := preload("res://scripts/systems/Shell.gd")

func _ready() -> void:
	Game.prepare_boot()
	# Development/audit launches still enter the actual game directly.
	if not Game.should_show_menu():
		get_tree().change_scene_to_file.call_deferred(Game.GAME_SCENE)
		return

	var shell := SHELL_SCRIPT.new()
	add_child(shell)
	shell.setup(Game.resolve_circle())
	shell.show_main_menu()
	# Platform queues this request until the asynchronous SDK init completes.
	if has_node("/root/Platform"):
		get_node("/root/Platform").report_ready()
