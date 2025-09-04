@tool
extends EditorPlugin

var audio_player : AudioStreamPlayer

func _enter_tree() -> void:
	var script_editor = get_editor_interface().get_script_editor()
	script_editor.connect("editor_script_changed", Callable(self, "_on_editor_script_changed"))
	
	# 🔊 setup audio player
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = load("res://addons/CodeFX/assets/sfx/key_press.wav")
	add_child(audio_player)

	# apply to all open editors after one frame
	call_deferred("_refresh_all_editors")


func _exit_tree() -> void:
	if audio_player and audio_player.is_inside_tree():
		audio_player.queue_free()


func _on_editor_script_changed(script: Script) -> void:
	await get_tree().process_frame
	_refresh_all_editors()


func _refresh_all_editors() -> void:
	var editors = get_editor_interface().get_script_editor().get_open_script_editors()
	for e in editors:
		_apply_sfx(e)


func _apply_sfx(editor: Control) -> void:
	var code_edit = _get_code_edit(editor)
	if code_edit == null:
		return
	
	if not code_edit.is_connected("gui_input", Callable(self, "_on_editor_gui_input")):
		code_edit.connect("gui_input", Callable(self, "_on_editor_gui_input"))


func _get_code_edit(node: Node) -> TextEdit:
	for child in node.get_children():
		if child is TextEdit:
			return child
		var found = _get_code_edit(child)
		if found:
			return found
	return null


func _on_editor_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if audio_player.playing:
			audio_player.stop()

		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER:
				audio_player.pitch_scale = randf_range(0.8, 0.9)
				audio_player.volume_db = 0.0
			KEY_BACKSPACE:
				audio_player.pitch_scale = randf_range(1.2, 1.3)
				audio_player.volume_db = -2.0
			KEY_SPACE:
				audio_player.pitch_scale = randf_range(0.95, 1.05)
				audio_player.volume_db = -4.0
			_:
				audio_player.pitch_scale = randf_range(0.9, 1.1)
				audio_player.volume_db = -2.0

		audio_player.volume_db += randf_range(-12.5, -7.5)
		audio_player.play()
