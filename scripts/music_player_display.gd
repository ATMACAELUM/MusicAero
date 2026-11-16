class_name MusicPlayerDisplay
extends Control

@export var search_bar: LineEdit
@export var search_tree: Tree
@export var back_button: Button
@export var pause_play_button: Button
@export var next_button: Button
@export var cover_texture_rect: TextureRect
@export var play_bar: HSlider

@export var selected_track_name_label: Label
@export var selected_track_artist_label: Label
@export var selected_track_album_label: Label


@export var volume_button: Button
@export var volume_slider: HSlider

@export var min_button: Button
@export var quit_button: Button
@export var visualizer_options: OptionButton
@export var settings_button: Button
@export var settings_panel: Control
@export var eq_32: HSlider
@export var eq_100: HSlider
@export var eq_320: HSlider
@export var eq_1000: HSlider
@export var eq_3200: HSlider
@export var eq_10000: HSlider

var dragging_play_bar = false
var last_volume = 0

func _ready() -> void:
	var mp = get_tree().get_first_node_in_group("music_player") as MusicPlayer
	if mp:
		mp.track_loaded.connect(_on_track_loaded)
		mp.playing.connect(_on_mp_play)
		mp.stopped.connect(_on_mp_stopped)
	back_button.pressed.connect(_on_back_pressed)
	next_button.pressed.connect(_on_next_pressed)
	search_bar.focus_entered.connect(_on_search_focus)
	search_bar.focus_exited.connect(_on_search_focus_exit)
	search_bar.editing_toggled.connect(_on_search_edit)
	search_tree.focus_exited.connect(_on_search_focus_exit)
	search_tree.item_selected.connect(_on_item_select)
	pause_play_button.pressed.connect(_on_pause_play_pressed)
	play_bar.drag_started.connect(_on_drag_start)
	play_bar.drag_ended.connect(_on_drag_stop)
	volume_button.pressed.connect(_on_volume_pressed)
	volume_slider.max_value = 1
	volume_slider.drag_ended.connect(_on_volume_drag_stop)
	volume_slider.value = AudioServer.get_bus_volume_linear(0)
	quit_button.pressed.connect(get_tree().quit)
	min_button.pressed.connect(func(): get_tree().root.mode = Window.MODE_MINIMIZED)
	visualizer_options.get_popup().id_pressed.connect(_on_id_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	eq_32.min_value = -60
	eq_32.max_value = 24
	eq_32.value_changed.connect(_on_eq_slide_end.bind(0))
	eq_100.min_value = -60
	eq_100.max_value = 24
	eq_100.value_changed.connect(_on_eq_slide_end.bind(1))
	eq_320.min_value = -60
	eq_320.max_value = 24
	eq_320.value_changed.connect(_on_eq_slide_end.bind(2))
	eq_1000.min_value = -60
	eq_1000.max_value = 24
	eq_1000.value_changed.connect(_on_eq_slide_end.bind(3))
	eq_3200.min_value = -60
	eq_3200.max_value = 24
	eq_3200.value_changed.connect(_on_eq_slide_end.bind(4))
	eq_10000.min_value = -60
	eq_10000.max_value = 24
	eq_10000.value_changed.connect(_on_eq_slide_end.bind(5))
	
	
	
	load_all_albums()
	_on_volume_changed()
	get_viewport().transparent_bg = true
	
	
func _process(delta: float) -> void:
	var m = get_tree().get_first_node_in_group("music_player") as MusicPlayer
	if m:
		if m.is_playing() and dragging_play_bar == false:
			play_bar.max_value = m.player.stream.get_length()
			play_bar.value = m.player.get_playback_position()	

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			search_bar.release_focus()

func _on_track_loaded(t: MusicTrack):
	if t == null: return
	selected_track_name_label.text = t.title
	selected_track_artist_label.text = t.artist
	selected_track_album_label.text = t.album

func _on_back_pressed():
	var mp = get_tree().get_first_node_in_group("music_player") as MusicPlayer
	if mp == null: return
	mp.back()
	
func _on_next_pressed():
	var mp = get_tree().get_first_node_in_group("music_player") as MusicPlayer
	if mp == null: return
	mp.next()


func _on_search_edit():
	search_tree.visible = true

func _on_search_focus():
	search_tree.visible = true
	pass
	
	
func _on_search_focus_exit():
	await get_tree().process_frame
	if search_tree.has_focus(): return
	search_tree.visible = false
	
	
func load_all_albums():
	var mp = get_tree().get_first_node_in_group("music_player") as MusicPlayer
	if mp == null: return
	
	search_tree.clear()
	var root = search_tree.create_item()
	search_tree.hide_root = true
	for each in mp.music_library.library.keys():
		var album = root.create_child()
		album.set_text(0, each)
		#album.set_text(1, str(mp.music_library.library.get(each).size()))
		var c = 0
		for song in mp.music_library.library.get(each):
			var s = album.create_child()
			s.set_metadata(0, {"album": each, "song": song, "id": c})
			s.set_text(0, song.split("/")[1])
			c+= 1


func _on_item_select():
	var mp = get_tree().get_first_node_in_group("music_player") as MusicPlayer
	if mp == null: return
	var meta = search_tree.get_selected().get_metadata(0)
	if meta == null: return
	mp.play(meta.get("album"), meta.get("song"), meta.get("id"))


func _on_mp_play():
	var mp = get_tree().get_first_node_in_group("music_player") as MusicPlayer
	pause_play_button.icon = load("res://icons/pause.png")
	if mp:
		if mp.current_track == null: return
		cover_texture_rect.texture = mp.current_track.cover
	
func _on_mp_stopped():
	pause_play_button.icon = load("res://icons/play.png")

func _on_pause_play_pressed():
	var mp = get_tree().get_first_node_in_group("music_player") as MusicPlayer
	if mp == null: return
	if mp.is_playing():
		mp.stop()
	else:
		mp.resume()


func _on_drag_start():
	dragging_play_bar = true
	
	
func _on_drag_stop(v):
	var x = play_bar.value
	dragging_play_bar = false
	var mp = get_tree().get_first_node_in_group("music_player") as MusicPlayer
	if mp == null: return
	mp.seek(x)


func _on_volume_pressed():
	var volume = AudioServer.get_bus_volume_linear(0)
	if volume != 0:
		last_volume = volume
		AudioServer.set_bus_volume_linear(0, 0)
	else:
		AudioServer.set_bus_volume_db(0, last_volume)
	
	_on_volume_changed()


func _on_volume_drag_stop(_x):
	AudioServer.set_bus_volume_linear(0, volume_slider.value)
	_on_volume_changed()


func _on_volume_changed():
	if AudioServer.get_bus_volume_linear(0) > 0:
		volume_button.icon = load("res://icons/speaker_on.png")
	elif AudioServer.get_bus_volume_linear(0) == 0:
		volume_button.icon = load("res://icons/speaker_off.png")
	if volume_slider.value != AudioServer.get_bus_volume_linear(0):
		volume_slider.set_value_no_signal(AudioServer.get_bus_volume_linear(0))


func _on_id_pressed(id):
	var visualiser = get_tree().get_first_node_in_group("visualizer") as Visualizer
	if visualiser == null: return
	match id:
		1:
			visualiser.set_type("Bar")
		2:
			visualiser.set_type("Circle")
		3:
			visualiser.set_type("Circle Inverted")

func _on_eq_slide_end(v, id):
	var a = AudioServer.get_bus_effect(0, 0) as AudioEffectEQ
	a.set_band_gain_db(id, v)

func _on_settings_pressed():
	settings_panel.visible = !settings_panel.visible
