@tool
extends SpriteImporter

func get_format_name() -> StringName:
	return "Texture Atlas"

func get_importer_data_class() -> String:
	return "TextureAtlasImporterSpriteData"

func needs_atlas_path() -> bool:
	return true

func get_atlas_extension() -> String:
	return ".json"

func convert_sprite(sprite_data_array: Array, disabled_anims: Array[String] = []) -> SpriteFrames:
	var sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation("default")
	
	var frame_list: Dictionary[String, Array]
	
	for sprite_data: TextureAtlasImporterSpriteData in sprite_data_array:
		sprite_data.read_atlas(sprite_data.atlas_path)
		var json_data = sprite_data.atlas
		if json_data == null:
			continue
		
		var frames_array: Array = []
		
		# Adobe Animate format: ATLAS.SPRITES[].SPRITE
		var atlas_data = json_data.get("ATLAS", {})
		var sprites = atlas_data.get("SPRITES", null)
		if sprites != null and sprites is Array:
			for entry in sprites:
				var sprite = entry.get("SPRITE", {})
				var frame_info = {
					"name": sprite.get("name", ""),
					"x": sprite.get("x", 0.0),
					"y": sprite.get("y", 0.0),
					"w": sprite.get("w", 0.0),
					"h": sprite.get("h", 0.0),
					"rotated": sprite.get("rotated", false)
				}
				frames_array.append(frame_info)
		
		# Standard TexturePacker format: frames{}
		if frames_array.is_empty():
			var frames_data = json_data.get("frames", {})
			if frames_data is Dictionary:
				for frame_name in frames_data.keys():
					var f = frames_data[frame_name].duplicate()
					f["_filename"] = frame_name
					frames_array.append(f)
			elif frames_data is Array:
				frames_array = frames_data.duplicate()
		
		if frames_array.is_empty():
			continue
		
		var regex = RegEx.new()
		regex.compile("\\d+$")
		var last_replaced_anim: String
		
		for frame_info in frames_array:
			var filename = frame_info.get("_filename", frame_info.get("name", frame_info.get("filename", "")))
			if filename.is_empty():
				continue
			
			var index_match = regex.search(filename)
			var index_str = index_match.get_string() if index_match else ""
			var anim_name = filename.trim_suffix(index_str)
			if anim_name.is_empty():
				anim_name = "animation"
			
			if sprite_data.anim_aliases.has(anim_name):
				if anim_name != last_replaced_anim:
					print("Animation: " + anim_name + " replaced with: " + sprite_data.anim_aliases[anim_name])
				last_replaced_anim = anim_name
				anim_name = sprite_data.anim_aliases[anim_name]
			
			var region = Rect2(
				frame_info.get("x", frame_info.get("frame", {}).get("x", 0.0)),
				frame_info.get("y", frame_info.get("frame", {}).get("y", 0.0)),
				frame_info.get("w", frame_info.get("frame", {}).get("w", 0.0)),
				frame_info.get("h", frame_info.get("frame", {}).get("h", 0.0))
			)
			
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = sprite_data.texture
			atlas_tex.region = region
			atlas_tex.filter_clip = true
			
			var rotated = frame_info.get("rotated", false)
			if rotated:
				atlas_tex.region = Rect2(region.position.x, region.position.y, region.size.y, region.size.x)
			
			var trimmed = frame_info.get("trimmed", false)
			if trimmed:
				var sprite_source = frame_info.get("spriteSourceSize", {})
				var source_size = frame_info.get("sourceSize", {})
				atlas_tex.margin = Rect2(
					sprite_source.get("x", 0.0),
					sprite_source.get("y", 0.0),
					source_size.get("w", 0.0) - region.size.x,
					source_size.get("h", 0.0) - region.size.y
				)
			
			if not frame_list.has(anim_name):
				frame_list[anim_name] = []
				if not sprite_frames.has_animation(anim_name):
					sprite_frames.add_animation(anim_name)
					sprite_frames.set_animation_loop(anim_name, sprite_data.loop)
					sprite_frames.set_animation_speed(anim_name, sprite_data.fps)
			
			frame_list[anim_name].append(atlas_tex)
	
	for anim: String in frame_list.keys():
		if disabled_anims.has(anim):
			continue
		for frame: AtlasTexture in frame_list[anim]:
			sprite_frames.add_frame(anim, frame)
	
	return sprite_frames
