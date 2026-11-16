class_name MusicLibrary
extends Node

signal library_updated(lib)
signal playing
var library: Dictionary

func _ready() -> void:
	add_to_group("music_library")


func set_library(lib):
	library = lib.duplicate()
	library_updated.emit(library)

func get_track(album, track_name, id) -> MusicTrack:
	if library.has(album) == false: return null
	if library.get(album) == null: return null
	var fp: String = track_name
	var m = OS.get_system_dir(OS.SYSTEM_DIR_MUSIC)
	var p = m+"/"+fp
	
	if FileAccess.file_exists(p) == false: return null
	var mt = MusicTrack.new()
	var aus: AudioStream
	var data = []
	match fp.get_extension().to_lower():
		"ogg":
			aus = AudioStreamOggVorbis.load_from_file(p)
		"mp3":
			aus = AudioStreamMP3.load_from_file(p)
		"wav":
			aus = AudioStreamWAV.load_from_file(p)
	mt.load_track(aus, m + "/"+album, album, id)
	return mt
