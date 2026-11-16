class_name MusicTrack
extends Resource


@export var file_path: String = ""
@export var file_album: String = ""
@export var id: int
@export var title: String = ""
@export var artist: String = ""
@export var album: String = ""
@export var cover: Texture2D
@export var track: AudioStream


func load_track(t: AudioStream, path = "", album_path = "", _id: int = 0):
	track = t
	file_path = path
	id = _id
	file_album = album_path
	for file in DirAccess.open(file_path).get_files():
		if file.contains("cover"):
			if file.get_extension().to_lower() == "jpg" or file.get_extension().to_lower() == "png":
				cover = ImageTexture.create_from_image(Image.load_from_file(file_path + "/" + file))

	if track is AudioStreamMP3:
		var id3_parser = ID3Parser.new()
		id3_parser.stream =  track
		artist = id3_parser.get_artist()
		album = id3_parser.get_album()
		title = id3_parser.get_track_name()
		if cover == null:
			var texture = Texture2D.new()
			texture = id3_parser.get_attached_picture()
			cover = texture
	elif track is AudioStreamWAV or track is AudioStreamOggVorbis:
		print(track.tags)
		title = track.tags.get("title")
		album = track.tags.get("album")
		artist = track.tags.get("artist")
