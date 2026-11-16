class_name MusicPlayer
extends Node

signal playing
signal stopped
signal track_loaded(t)
@export var player: AudioStreamPlayer
var music_library: MusicLibrary
var current_album: String
var last_track: MusicTrack
var current_track: MusicTrack
var stopped_time: float

func _ready() -> void:
	add_to_group("music_player")
	music_library = get_tree().get_first_node_in_group("music_library")
	music_library.library_updated.connect(_on_library_updated)

	
	
func _on_library_updated():
	pass

func is_playing():
	return player.is_playing()

func play(album, song, id):
	var track = music_library.get_track(album, song, id)
	current_album = album
	play_track(track)

func play_track(track):
	if track == null: return
	current_album = track.file_album
	if current_track:
		last_track = current_track
	current_track = track
	player.stream = current_track.track
	player.play()
	playing.emit()
	track_loaded.emit(track)

func resume():
	player.play(stopped_time)
	playing.emit()

func stop():
	stopped_time = player.get_playback_position()
	player.stop()
	stopped.emit()


func seek(v):
	player.play(v)

func back():
	if current_track == null: return
	if last_track:
		play_track(last_track)
		return
	# Get the current -1 track of the current album
	var v = wrapi(current_track.id-1, 0, music_library.library.get(current_track.file_album).size())
	play(current_track.file_album, music_library.library.get(current_track.file_album)[v], v)
	
	
func next():
	var v = wrapi(current_track.id+1, 0, music_library.library.get(current_track.file_album).size())
	play(current_track.file_album, music_library.library.get(current_track.file_album)[v], v)
