## Thanks to 
## https://github.com/solobot2/godotId3TagParser/blob/master/addons/Id3TagParser/MP3ID3Tag.gd

class_name ID3Parser
extends RefCounted

const TAG_HEADER_LENGTH: int = 10
const FRAME_HEADER_LENGTH: int = 10

var _stream: AudioStreamMP3
var _ID3Header: ID3MainHeader
var _frames: Dictionary = {}


class ID3MainHeader:
	var isId3: bool = false
	var id3Ver: String = ""
	var unsync: bool = false
	var compress: bool = false
	var size: int = 0


var stream: AudioStreamMP3:
	set(value):
		_stream = value
		_clear()

	get:
		return _stream


var header: ID3MainHeader:
	get:
		if _stream == null:
			return null

		if _ID3Header == null:
			_ID3Header = _decode_head()

		return _ID3Header


var frames: Dictionary:
	get:
		if _frames.is_empty():
			_frames = _decode_frame_heads()

		return _frames


func _clear() -> void:
	_ID3Header = null
	_frames.clear()


func _decode_head() -> ID3MainHeader:
	var result := ID3MainHeader.new()

	if _stream == null:
		return result

	var data: PackedByteArray = _stream.data

	if data.size() < TAG_HEADER_LENGTH:
		return result

	if data[0] != 0x49 or data[1] != 0x44 or data[2] != 0x33:
		return result

	var major: int = data[3]
	var minor: int = data[4]
	var flags: int = data[5]

	if major != 3 and major != 4:
		return result

	if minor == 0xFF:
		return result

	result.isId3 = true
	result.id3Ver = str(major) + "." + str(minor)
	result.unsync = (flags & 0x80) != 0
	result.compress = (flags & 0x40) != 0

	result.size = (
		(data[6] << 21)
		| (data[7] << 14)
		| (data[8] << 7)
		| data[9]
	)

	if result.size > 0x0FFFFFFF:
		result.isId3 = false
		return result

	return result


func _decode_frame_heads() -> Dictionary:
	var result: Dictionary = {}

	if header == null or not header.isId3:
		return result

	if header.compress:
		return result

	var data: PackedByteArray = _stream.data

	var frame_start: int = TAG_HEADER_LENGTH
	var tag_end: int = mini(
		TAG_HEADER_LENGTH + header.size,
		data.size()
	)

	while frame_start + FRAME_HEADER_LENGTH <= tag_end:
		var frame_id_bytes := data.slice(
			frame_start,
			frame_start + 4
		)

		if frame_id_bytes[0] == 0:
			break

		var frame_id := (
			char(frame_id_bytes[0])
			+ char(frame_id_bytes[1])
			+ char(frame_id_bytes[2])
			+ char(frame_id_bytes[3])
		)

		var frame_length: int

		if header.id3Ver.begins_with("4."):
			frame_length = (
				(data[frame_start + 4] << 21)
				| (data[frame_start + 5] << 14)
				| (data[frame_start + 6] << 7)
				| data[frame_start + 7]
			)
		else:
			frame_length = (
				(data[frame_start + 4] << 24)
				| (data[frame_start + 5] << 16)
				| (data[frame_start + 6] << 8)
				| data[frame_start + 7]
			)

		if frame_length <= 0:
			break

		var frame_data_start: int = frame_start + FRAME_HEADER_LENGTH
		var frame_end: int = frame_data_start + frame_length

		if frame_end > tag_end:
			break

		result[StringName(frame_id)] = [
			frame_start,
			frame_length
		]

		frame_start = frame_end

	return result


func _get_frame_bytes(frameName: StringName) -> PackedByteArray:
	if not frames.has(frameName):
		return PackedByteArray()

	var start: int = frames[frameName][0] + FRAME_HEADER_LENGTH
	var length: int = frames[frameName][1]
	var end: int = start + length

	if start < 0 or end > _stream.data.size():
		return PackedByteArray()

	return _stream.data.slice(start, end)



func _decode_byte_text(text: PackedByteArray, encoding: int) -> String:
	match encoding:

		0:

			var result: String = ""

			for byte in text:
				if byte == 0:
					continue

				result += char(byte)

			return result

		1:

			return _decode_utf16(text, true)

		2:

			return _decode_utf16(text, false)

		3:

			var clean := _remove_trailing_zeroes(text, 1)
			return clean.get_string_from_utf8()

		_:
			return ""


func _decode_utf16(bytes: PackedByteArray, check_bom: bool) -> String:

	var little_endian: bool = false
	var start: int = 0

	if bytes.size() >= 2:
		if bytes[0] == 0xFF and bytes[1] == 0xFE:
			little_endian = true
			start = 2

		elif bytes[0] == 0xFE and bytes[1] == 0xFF:
			little_endian = false
			start = 2

		elif check_bom:
			# UTF-16 encoding requires a BOM.
			return ""

	var clean := bytes.slice(start)
	clean = _remove_trailing_zeroes(clean, 2)

	# UTF-16 requires pairs of bytes.
	if clean.size() % 2 != 0:
		clean.resize(clean.size() - 1)

	if not little_endian:
		var swapped := PackedByteArray()

		for i in range(0, clean.size(), 2):
			swapped.append(clean[i + 1])
			swapped.append(clean[i])

		clean = swapped

	return clean.get_string_from_utf16()


func _remove_trailing_zeroes(bytes: PackedByteArray,alignment: int) -> PackedByteArray:

	var end: int = bytes.size()

	if alignment == 2:
		while end >= 2:
			if bytes[end - 1] != 0 or bytes[end - 2] != 0:
				break

			end -= 2

	else:
		while end > 0 and bytes[end - 1] == 0:
			end -= 1

	return bytes.slice(0, end)


func _get_frame_data_string(frameName: StringName) -> String:
	var bytes := _get_frame_bytes(frameName)

	if bytes.is_empty():
		return ""

	var encoding: int = bytes[0]
	var text := bytes.slice(1)

	return _decode_byte_text(text, encoding).strip_edges()


func get_frame_data(frameName: StringName) -> Variant:
	if not frames.has(frameName):
		return null

	if frameName.begins_with("T"):
		return _get_frame_data_string(frameName)

	match frameName:
		&"COMM":
			return _get_frame_comment_dict(frameName)

		&"APIC":
			return _get_frame_image(frameName)

		_:
			return null


func _read_terminated(bytes: PackedByteArray, start: int, unicode: bool) -> Array:

	var terminator_size: int = 2 if unicode else 1
	var end: int = start

	while end + terminator_size <= bytes.size():

		if unicode:
			if bytes[end] == 0 and bytes[end + 1] == 0:
				return [
					bytes.slice(start, end),
					end + 2
				]
		else:
			if bytes[end] == 0:
				return [
					bytes.slice(start, end),
					end + 1
				]

		end += terminator_size

	return [
		bytes.slice(start),
		bytes.size()
	]


func _get_frame_comment_dict(frameName: StringName) -> Dictionary:
	var bytes := _get_frame_bytes(frameName)

	if bytes.size() < 4:
		return {}

	var encoding: int = bytes[0]
	var unicode: bool = encoding == 1 or encoding == 2

	var lang := bytes.slice(1, 4).get_string_from_ascii()

	var description_data: Array = _read_terminated(bytes, 4, unicode)

	var short_content: String = _decode_byte_text(description_data[0], encoding)

	var long_content: String = _decode_byte_text(bytes.slice(description_data[1]), encoding)

	return {
		"lang": lang,
		"shortContent": short_content,
		"longContent": long_content
	}


func _get_frame_image(frameName: StringName) -> Dictionary:
	var bytes := _get_frame_bytes(frameName)

	if bytes.size() < 5:
		return {}

	var encoding: int = bytes[0]
	var unicode: bool = encoding == 1 or encoding == 2

	var mime_data: Array = _read_terminated(bytes, 1, false)

	var mime_type: String = mime_data[0].get_string_from_ascii()
	var position: int = mime_data[1]

	if position >= bytes.size():
		return {}

	var picture_type: int = bytes[position]
	position += 1

	var description_data: Array = _read_terminated(bytes, position, unicode)

	var description: String = _decode_byte_text(description_data[0], encoding)

	position = description_data[1]

	return {
		"mimeType": mime_type,
		"pictureType": picture_type,
		"description": description,
		"pictureBytes": bytes.slice(position)
	}


func _ensure_string(frameName: StringName) -> String:
	var data: Variant = get_frame_data(frameName)

	if data is String:
		return data

	return ""


func _ensure_dict(frameName: StringName) -> Dictionary:
	var data: Variant = get_frame_data(frameName)

	if data is Dictionary:
		return data

	return {}


func get_artist() -> String:
	return _ensure_string(&"TPE1")


func get_track_name() -> String:
	return _ensure_string(&"TIT2")


func get_album() -> String:
	return _ensure_string(&"TALB")


func get_year() -> String:
	var year := _ensure_string(&"TDRC")

	if year.is_empty():
		year = _ensure_string(&"TYER")

	return year


func get_key() -> String:
	return _ensure_string(&"TKEY")


func get_attached_picture() -> Image:
	var picture: Dictionary = _ensure_dict(&"APIC")

	if picture.is_empty():
		return null

	var image := Image.new()
	var error: Error

	match picture.get("mimeType", ""):
		"image/jpeg", "image/jpg":
			error = image.load_jpg_from_buffer(picture.pictureBytes)

		"image/png":
			error = image.load_png_from_buffer(picture.pictureBytes)

		_:
			return null

	if error != OK:
		return null

	return image
