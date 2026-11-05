extends Control

@onready var grid_container: HBoxContainer = $ScrollContainer/CardsHBox
@onready var back_button: Button = $TopBar/BackButton

var levels_data: Array = []

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	load_levels_data()
	build_level_cards()

func load_levels_data() -> void:
	var path = "res://data/levels.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var text = file.get_as_text()
		var parsed = JSON.parse_string(text)
		if parsed is Array:
			levels_data = parsed

func build_level_cards() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	for lvl in levels_data:
		var lvl_id = lvl.get("id", "")
		var is_unlocked = GameState.is_level_unlocked(lvl_id)
		var best_rank = GameState.get_best_rank(lvl_id)
		var best_score = GameState.get_best_score(lvl_id)

		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(250, 420)

		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3

		if is_unlocked:
			style.bg_color = Color("#1F1F35")
			style.border_color = Color("#F7D117") if best_rank in ["S", "A"] else Color("#FFF8E7")
		else:
			style.bg_color = Color("#151522")
			style.border_color = Color("#3A3A4D")

		style.shadow_color = Color(0, 0, 0, 0.4)
		style.shadow_size = 6
		style.shadow_offset = Vector2(3, 4)
		card.add_theme_stylebox_override("panel", style)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_top", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_bottom", 16)
		card.add_child(margin)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		margin.add_child(vbox)

		# Subtitle / District
		var sub_label = Label.new()
		sub_label.text = lvl.get("subtitle", "District")
		sub_label.add_theme_font_size_override("font_size", 14)
		sub_label.add_theme_color_override("font_color", Color("#F7D117") if is_unlocked else Color("#777788"))
		vbox.add_child(sub_label)

		# Title
		var title_label = Label.new()
		title_label.text = lvl.get("title", "Level")
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.add_theme_font_size_override("font_size", 20)
		title_label.add_theme_color_override("font_color", Color("#FFF8E7") if is_unlocked else Color("#666677"))
		vbox.add_child(title_label)

		# Rival
		var rival_label = Label.new()
		rival_label.text = "Rival: " + lvl.get("rival", "")
		rival_label.add_theme_font_size_override("font_size", 14)
		rival_label.add_theme_color_override("font_color", Color("#C85A6E") if is_unlocked else Color("#666677"))
		vbox.add_child(rival_label)

		# Concept Badge
		var concept_label = Label.new()
		concept_label.text = "Concept:\n" + lvl.get("concept", "")
		concept_label.add_theme_font_size_override("font_size", 13)
		concept_label.add_theme_color_override("font_color", Color("#4A7DBF") if is_unlocked else Color("#555566"))
		vbox.add_child(concept_label)

		var spacer = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(spacer)

		# Rank & Score
		var rank_label = Label.new()
		rank_label.text = "RANK: " + best_rank
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_label.add_theme_font_size_override("font_size", 28)
		rank_label.add_theme_color_override("font_color", Color("#F7D117") if best_rank in ["S", "A"] else Color("#FFF8E7"))
		vbox.add_child(rank_label)

		var score_label = Label.new()
		score_label.text = "BEST: %d" % best_score
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.add_theme_font_size_override("font_size", 13)
		score_label.add_theme_color_override("font_color", Color("#FFF8E7").lerp(Color("#1B1B2F"), 0.3))
		vbox.add_child(score_label)

		# Play / Locked Button
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 42)
		if is_unlocked:
			btn.text = "PLAY"
			btn.pressed.connect(func(): _start_level(lvl_id))
		else:
			btn.text = "LOCKED"
			btn.disabled = true
			var tip = Label.new()
			tip.text = lvl.get("unlock_req", "Locked")
			tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tip.add_theme_font_size_override("font_size", 11)
			tip.add_theme_color_override("font_color", Color("#888899"))
			vbox.add_child(tip)

		vbox.add_child(btn)
		grid_container.add_child(card)

func _start_level(level_id: String) -> void:
	GameState.selected_level_id = level_id
	get_tree().change_scene_to_file("res://scenes/gameplay/Song.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

