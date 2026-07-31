extends ImporterSpriteData
class_name TextureAtlasImporterSpriteData

func read_atlas(atlas_path: String):
	var file = FileAccess.open(atlas_path, FileAccess.READ)
	if file == null:
		printerr("Texture Atlas: Failed to open atlas at path: " + atlas_path)
		return
	atlas = JSON.parse_string(file.get_as_text())
	if atlas == null:
		printerr("Texture Atlas: Failed to parse JSON at path: " + atlas_path)

func get_animation_list() -> PackedStringArray:
	if atlas == null:
		read_atlas(atlas_path)
	if atlas == null:
		return []
	
	var anim_list: PackedStringArray
	var regex = RegEx.new()
	regex.compile("\\d+$")
	
	# Adobe Animate format: ATLAS.SPRITES[].SPRITE.name
	var atlas_data = atlas.get("ATLAS", {})
	var sprites = atlas_data.get("SPRITES", null)
	if sprites != null and sprites is Array:
		for entry in sprites:
			var sprite = entry.get("SPRITE", {})
			var frame_name = sprite.get("name", "")
			if frame_name.is_empty():
				continue
			var index_match = regex.search(frame_name)
			var index_str = index_match.get_string() if index_match else ""
			var anim_name = frame_name.trim_suffix(index_str)
			if anim_name.is_empty():
				anim_name = "animation"
			if anim_aliases.has(anim_name):
				anim_name = anim_aliases[anim_name]
			if not anim_list.has(anim_name):
				anim_list.append(anim_name)
		return anim_list
	
	# Standard TexturePacker format: frames{}
	var frames = atlas.get("frames", {})
	if frames is Dictionary:
		for frame_name in frames.keys():
			var index_match = regex.search(frame_name)
			var index_str = index_match.get_string() if index_match else ""
			var anim_name = frame_name.trim_suffix(index_str)
			if anim_aliases.has(anim_name):
				anim_name = anim_aliases[anim_name]
			if not anim_list.has(anim_name):
				anim_list.append(anim_name)
	elif frames is Array:
		for frame in frames:
			var frame_name = frame.get("filename", "")
			if frame_name.is_empty():
				continue
			var index_match = regex.search(frame_name)
			var index_str = index_match.get_string() if index_match else ""
			var anim_name = frame_name.trim_suffix(index_str)
			if anim_aliases.has(anim_name):
				anim_name = anim_aliases[anim_name]
			if not anim_list.has(anim_name):
				anim_list.append(anim_name)
	
	return anim_list
