class_name MusicScanner
extends Node


func _ready() -> void:
	scan()
	
func scan():
	var library = {}
	var x = OS.get_system_dir(OS.SYSTEM_DIR_MUSIC)
	for each in DirAccess.get_directories_at(x):
		var album = each
		library[each] = []
		for file in DirAccess.get_files_at(x + "/" + each):
			if file.contains("ogg") or file.contains("mp3") or file.contains("wav"):
				library[album].append(album + "/" + file)
	var ml = get_tree().get_first_node_in_group("music_library") as MusicLibrary
	if ml == null: return
	ml.set_library(library)
		
