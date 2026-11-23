extends RefCounted
## Shared helpers for story dialogue: loading data/dialogue/*.json and speaker colors.

const SPEAKER_COLORS: Dictionary = {
	"Narrator": Color("#C9C3B3"),
	"Clap": Color("#F7D117"),
	"Beats": Color("#D8B263"),
	"The Straight Man": Color("#C85A6E"),
	"Swing Queen": Color("#4A7DBF"),
	"The Syncopator": Color("#4E9A5E"),
	"Tri": Color("#D17B4A"),
	"Quad": Color("#E89A6B"),
	"The Twins": Color("#D17B4A"),
	"The Twins (Tri & Quad)": Color("#D17B4A"),
	"The Metronome": Color("#00E5FF"),
}

static func speaker_color(speaker: String) -> Color:
	return SPEAKER_COLORS.get(speaker, Color("#FFF8E7"))

static func load_dialogue(path: String) -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_warning("StoryData: could not parse dialogue " + path)
	return {}
