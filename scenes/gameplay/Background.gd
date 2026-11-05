extends Control

var night_purple: Color = Color("#3B2F63")
var dark_navy: Color = Color("#181829")
var mid_navy: Color = Color("#232338")
var hero_yellow: Color = Color("#F7D117")
var paper_white: Color = Color("#FFF8E7")

func _draw() -> void:
	# 1. Sky fill
	draw_rect(Rect2(Vector2.ZERO, size), night_purple)

	# 2. Giant stylized paper clock / stopped metronome tower in background (Story setup)
	var tower_x = size.x / 2.0
	# Far tower silhouette
	draw_rect(Rect2(tower_x - 70, 70, 140, size.y), mid_navy)
	# Tower peak triangle
	draw_colored_polygon(PackedVector2Array([
		Vector2(tower_x - 70, 70),
		Vector2(tower_x + 70, 70),
		Vector2(tower_x, 15)
	]), mid_navy)

	# Stopped Metronome pendulum arm
	draw_line(Vector2(tower_x, 80), Vector2(tower_x + 35, 170), hero_yellow.lerp(night_purple, 0.4), 6.0)
	draw_circle(Vector2(tower_x + 35, 170), 12.0, hero_yellow.lerp(night_purple, 0.4))

	# 3. City skyline layer 1 (Distant buildings)
	var buildings_far = [
		Rect2(40, 220, 110, size.y),
		Rect2(160, 190, 80, size.y),
		Rect2(250, 240, 90, size.y),
		Rect2(940, 200, 95, size.y),
		Rect2(1050, 180, 85, size.y),
		Rect2(1150, 230, 90, size.y),
	]
	for b in buildings_far:
		draw_rect(b, mid_navy)

	# 4. City skyline layer 2 (Near rooftops with paper drop shadows)
	var buildings_near = [
		Rect2(10, 310, 160, size.y),
		Rect2(180, 290, 110, size.y),
		Rect2(990, 280, 120, size.y),
		Rect2(1120, 310, 150, size.y),
	]
	for b in buildings_near:
		# Shadow
		draw_rect(Rect2(b.position + Vector2(6, 6), b.size), Color(0.08, 0.08, 0.12, 0.4))
		# Near building body
		draw_rect(b, dark_navy)

		# Small lit paper windows in Hero Yellow
		for wy in range(int(b.position.y) + 30, int(size.y) - 60, 45):
			for wx in range(int(b.position.x) + 20, int(b.position.x + b.size.x) - 25, 30):
				if (wx + wy) % 2 == 0:
					draw_rect(Rect2(wx, wy, 12, 16), hero_yellow.lerp(paper_white, 0.3))

	# 5. Street floor stage
	var stage_rect = Rect2(0, size.y - 85, size.x, 85)
	draw_rect(stage_rect, dark_navy)
	draw_line(Vector2(0, size.y - 85), Vector2(size.x, size.y - 85), hero_yellow, 3.0)

	# Decorative paper dashed rhythm road line
	for rx in range(20, int(size.x), 50):
		draw_line(Vector2(rx, size.y - 42), Vector2(rx + 28, size.y - 42), paper_white.lerp(dark_navy, 0.6), 3.0)
