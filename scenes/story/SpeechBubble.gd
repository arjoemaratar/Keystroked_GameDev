extends PanelContainer
## Small speech bubble for rival taunts during a song. Doesn't block input.

const StoryData = preload("res://scenes/story/StoryData.gd")

var label: Label
var style: StyleBoxFlat
var tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(250, 0)
	style = StyleBoxFlat.new()
	style.bg_color = Color("#FFF8E7")
	style.border_color = Color("#1B1B2F")
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 3)
	add_theme_stylebox_override("panel", style)

	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(220, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#1B1B2F"))
	add_child(label)
	modulate.a = 0.0

func say(text: String, speaker: String = "", hold_sec: float = 2.2) -> void:
	label.text = text
	style.border_color = StoryData.speaker_color(speaker).darkened(0.2) if speaker != "" else Color("#1B1B2F")
	reset_size()
	pivot_offset = Vector2(20, size.y)
	if tween and tween.is_valid():
		tween.kill()
	modulate.a = 1.0
	scale = Vector2(0.6, 0.6)
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if hold_sec > 0.0:
		tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(hold_sec)
