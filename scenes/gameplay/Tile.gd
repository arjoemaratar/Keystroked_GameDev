extends Control

const TileDefs = preload("res://scenes/gameplay/TileDefs.gd")

var tile_type: String = "Q"
var primary_dir: String = "left" # "left", "down", "up", "right", "rest"
var sub_hits: Array = [] # Array of Dictionary { "offset": float, "dir": String }
var sub_states: Array[int] = [] # 0: pending, 1: hit, 2: missed

var is_active: bool = false
var is_play_phase: bool = false
var playhead_progress: float = 0.0 # 0.0 to 1.0 within this beat
var scale_factor: float = 1.0

# Animation effects
var hit_pop_scale: float = 1.0
var hit_flash_alpha: float = 0.0
var pop_ring_radius: float = 0.0
var pop_ring_alpha: float = 0.0
var idle_anim_time: float = 0.0

# Press cues from Song.gd: Array of { sub: int, remain: float, dir: String }.
# remain is 1.0 when the cue appears, 0.0 exactly when to press, negative = late.
var cues: Array = []
const CUE_TARGET_RADIUS: float = 25.0
const CUE_START_RADIUS: float = 58.0
const CUE_NOW_BAND: float = 0.07 # |remain| below this shows the NOW flash

var ink_color: Color = Color("#1B1B2F")
var paper_white: Color = Color("#FFF8E7")
var paper_tint: Color = Color("#FFFDF5")
var hero_yellow: Color = Color("#F7D117")
var notebook_rule: Color = Color(0.85, 0.90, 0.96, 0.75)
var notebook_margin: Color = Color(0.98, 0.65, 0.65, 0.70)
var gold_color: Color = Color("#FFD000")

const DIR_COLORS = {
	"left": Color("#C85A6E"),
	"down": Color("#4A7DBF"),
	"up": Color("#4E9A5E"),
	"right": Color("#D17B4A"),
	"rest": Color("#9D4EDD")
}

const TYPE_SYMBOLS = {
	"Q": "♩",
	"E2": "♫",
	"S4": "♬",
	"TR": "3",
	"ER": "𝄾♪",
	"R": "𝄽"
}

func _ready() -> void:
	custom_minimum_size = Vector2(106, 116)
	size = Vector2(106, 116)
	pivot_offset = size / 2.0

func setup(t_type: String, p_dir: String, hits_data: Array = []) -> void:
	tile_type = t_type
	primary_dir = p_dir
	sub_hits.clear()
	sub_states.clear()

	if hits_data.size() > 0:
		sub_hits = hits_data.duplicate()
	else:
		# Offsets come from tiles.json so drawing matches Song.gd judging
		for off in TileDefs.get_hit_offsets(tile_type):
			sub_hits.append({ "offset": off, "dir": primary_dir })
		if sub_hits.is_empty():
			primary_dir = "rest"

	for _h in sub_hits:
		sub_states.append(0)

	reset_state()
	queue_redraw()

func reset_state() -> void:
	cues = []
	for i in range(sub_states.size()):
		sub_states[i] = 0
	is_active = false
	playhead_progress = 0.0
	scale_factor = 1.0
	hit_pop_scale = 1.0
	hit_flash_alpha = 0.0
	pop_ring_alpha = 0.0
	queue_redraw()

func set_active(active: bool, play_phase: bool) -> void:
	is_active = active
	is_play_phase = play_phase
	if active:
		var tween = create_tween()
		scale_factor = 1.14
		tween.tween_property(self, "scale_factor", 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()

func set_progress(p: float) -> void:
	playhead_progress = clampf(p, 0.0, 1.0)
	queue_redraw()

func mark_sub_hit(index: int, rating: String) -> void:
	if index >= 0 and index < sub_states.size():
		sub_states[index] = 1 if (rating == "Perfect" or rating == "Good") else 2

		# Juicy pop animation
		hit_flash_alpha = 0.7
		pop_ring_radius = 8.0
		pop_ring_alpha = 1.0
		hit_pop_scale = 1.22

		var tween = create_tween()
		tween.tween_property(self, "hit_pop_scale", 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(self, "hit_flash_alpha", 0.0, 0.2)
		tween.parallel().tween_property(self, "pop_ring_radius", 36.0, 0.22)
		tween.parallel().tween_property(self, "pop_ring_alpha", 0.0, 0.22)
		queue_redraw()

func pulse_listen(index: int) -> void:
	if index >= 0 and index < sub_states.size():
		sub_states[index] = 1

	hit_flash_alpha = 0.5
	hit_pop_scale = 1.15
	var tween = create_tween()
	tween.tween_property(self, "hit_pop_scale", 1.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "hit_flash_alpha", 0.0, 0.18)
	queue_redraw()

func _process(delta: float) -> void:
	idle_anim_time += delta
	if is_active or hit_flash_alpha > 0.01 or not cues.is_empty():
		queue_redraw()

func _draw() -> void:
	var total_scale = scale_factor * hit_pop_scale
	var rect = Rect2(Vector2.ZERO, size)
	var center = rect.size / 2.0
	draw_set_transform(center * (1.0 - total_scale), 0.0, Vector2(total_scale, total_scale))

	var dir_col = DIR_COLORS.get(primary_dir, Color("#C85A6E"))

	# 1. Soft Paper Drop Shadow
	var shadow_rect = Rect2(Vector2(5, 6), rect.size)
	draw_rect_rounded(shadow_rect, 14.0, Color(0.1, 0.1, 0.18, 0.38))

	# 2. Glowing Golden Active Border Aura
	if is_active:
		var aura_col = hero_yellow
		aura_col.a = 0.4 + sin(idle_anim_time * 8.0) * 0.15
		var aura_rect = Rect2(Vector2(-3, -3), rect.size + Vector2(6, 6))
		draw_rect_rounded(aura_rect, 16.0, aura_col)

	# 3. Card Base: Warm Cream Notebook Paper
	var bg_col = paper_tint
	if is_active:
		bg_col = hero_yellow.lerp(paper_white, 0.65)
	draw_rect_rounded(rect, 14.0, bg_col)

	# 4. Realistic Ruled Notebook Lines Texture
	draw_notebook_texture(rect)

	# 5. Bottom-Right Paper Fold / Peel Corner
	draw_folded_paper_corner(rect)

	# 6. Direction Header Strip
	var header_h = 26.0
	var header_rect = Rect2(0, 0, rect.size.x, header_h)
	draw_rect_rounded_top(header_rect, 14.0, dir_col)

	# Stitched Perforation line under header
	draw_dashes(Vector2(6, header_h), Vector2(rect.size.x - 6, header_h), ink_color.lerp(paper_white, 0.4), 1.5, 3.0, 3.0)

	# 7. Washi Tape Strip at Top (playful craft detail)
	draw_washi_tape(rect, dir_col)

	# 8. Thick Comic Outline (3.5px ink border)
	draw_rect_rounded_outline(rect, 14.0, ink_color, 3.5)

	# 9. Header Text & Notation Stamp Badge
	draw_header_badge(rect, dir_col)

	# 10. Center Arrow Glyph (with 3D Paper Bevel) or Rest Face
	var center_glyph_pos = Vector2(rect.size.x / 2.0, 64.0)
	if primary_dir == "rest":
		draw_rest_face(center_glyph_pos)
	else:
		draw_tactile_arrow(center_glyph_pos, primary_dir, dir_col)

	# 11. Bottom Sub-hit Rhythm Beads / Stamps
	draw_sub_hit_beads(rect)

	# 12. Diagonal Glossy Sticker Sheen across card
	draw_glossy_sticker_sheen(rect)

	# 13. Hit Flash / Shockwave Ring
	if pop_ring_alpha > 0.01:
		var ring_col = hero_yellow
		ring_col.a = pop_ring_alpha
		draw_arc(center_glyph_pos, pop_ring_radius, 0, TAU, 24, ring_col, 3.0)

	# 14. Luminous Scanning Laser Playhead
	if is_active:
		draw_laser_playhead(rect)

	# 15. Press cue rings (closing exactly on the press moment)
	if not cues.is_empty():
		draw_press_cues(rect, center_glyph_pos)

func set_cues(new_cues: Array) -> void:
	if new_cues.is_empty() and cues.is_empty():
		return
	cues = new_cues
	queue_redraw()

func draw_press_cues(r: Rect2, glyph_pos: Vector2) -> void:
	# The next note to press gets the big ring around the arrow
	var next_cue: Dictionary = cues[0]
	for c in cues:
		if float(c["remain"]) < float(next_cue["remain"]):
			next_cue = c

	var remain: float = float(next_cue["remain"])
	var col: Color = DIR_COLORS.get(str(next_cue["dir"]), hero_yellow)
	var is_now: bool = absf(remain) <= CUE_NOW_BAND

	# Target ring (where the shrinking ring has to land)
	draw_arc(glyph_pos, CUE_TARGET_RADIUS, 0, TAU, 32, Color(ink_color, 0.55), 2.0)

	if is_now:
		var glow = hero_yellow
		glow.a = 0.55
		draw_circle(glyph_pos, CUE_TARGET_RADIUS + 3.0, glow)
		draw_arc(glyph_pos, CUE_TARGET_RADIUS, 0, TAU, 32, ink_color, 5.0)
		draw_arc(glyph_pos, CUE_TARGET_RADIUS, 0, TAU, 32, hero_yellow, 3.0)
		var font = ThemeDB.fallback_font
		var txt = "NOW!"
		var ts = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 15)
		var tp = Vector2((r.size.x - ts.x) / 2.0, glyph_pos.y + CUE_TARGET_RADIUS + 15.0)
		draw_string_outline(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, ink_color)
		draw_string(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, hero_yellow)
	elif remain > 0.0:
		var radius = lerpf(CUE_TARGET_RADIUS, CUE_START_RADIUS, clampf(remain, 0.0, 1.0))
		var ring = col
		ring.a = lerpf(1.0, 0.6, clampf(remain, 0.0, 1.0))
		draw_arc(glyph_pos, radius, 0, TAU, 48, Color(ink_color, ring.a), 9.0)
		draw_arc(glyph_pos, radius, 0, TAU, 48, ring.lightened(0.15), 5.5)

	# Small rings on the rhythm beads show which sub-hit each cue belongs to
	if sub_hits.size() > 1 or (sub_hits.size() == 1 and not is_zero_approx(float(sub_hits[0].get("offset", 0.0)))):
		var dot_y = r.size.y - 14.0
		var usable_w = r.size.x - 28.0
		for c in cues:
			var idx: int = int(c["sub"])
			if idx < 0 or idx >= sub_hits.size():
				continue
			var x = 14.0 + float(sub_hits[idx].get("offset", 0.0)) * usable_w
			var rem: float = float(c["remain"])
			if absf(rem) <= CUE_NOW_BAND:
				draw_arc(Vector2(x, dot_y), 9.0, 0, TAU, 16, hero_yellow, 3.0)
			elif rem > 0.0:
				draw_arc(Vector2(x, dot_y), lerpf(8.0, 18.0, clampf(rem, 0.0, 1.0)), 0, TAU, 20, Color(ink_color, 0.8), 2.0)

func draw_notebook_texture(r: Rect2) -> void:
	# Horizontal faint blue ruled lines
	for ly in range(36, int(r.size.y) - 20, 14):
		draw_line(Vector2(8, ly), Vector2(r.size.x - 8, ly), notebook_rule, 1.2)

	# Vertical red left margin line
	draw_line(Vector2(20, 27), Vector2(20, r.size.y - 8), notebook_margin, 1.5)

func draw_folded_paper_corner(r: Rect2) -> void:
	var fold_size = 14.0
	var br = r.size
	# Paper underside triangle shadow
	var fold_shadow_pts = PackedVector2Array([
		Vector2(br.x - fold_size - 2, br.y),
		Vector2(br.x, br.y - fold_size - 2),
		Vector2(br.x - fold_size - 2, br.y - fold_size - 2)
	])
	draw_colored_polygon(fold_shadow_pts, Color(0.1, 0.1, 0.15, 0.2))

	# Paper underside flap
	var flap_pts = PackedVector2Array([
		Vector2(br.x - fold_size, br.y),
		Vector2(br.x, br.y - fold_size),
		Vector2(br.x - fold_size, br.y - fold_size)
	])
	draw_colored_polygon(flap_pts, paper_white.darkened(0.12))
	draw_polyline(flap_pts + PackedVector2Array([flap_pts[0]]), ink_color, 1.8)

func draw_washi_tape(r: Rect2, theme_col: Color) -> void:
	# Cute decorative patterned tape strip pinning top of card
	var tw = 38.0
	var th = 12.0
	var tx = (r.size.x - tw) / 2.0
	var ty = -5.0
	var tape_rect = Rect2(tx, ty, tw, th)

	# Tape shadow
	draw_rect_rounded(Rect2(tx + 1, ty + 2, tw, th), 3.0, Color(0.1, 0.1, 0.15, 0.25))

	# Translucent Tape body
	var t_col = theme_col.lightened(0.4)
	t_col.a = 0.85
	draw_rect_rounded(tape_rect, 3.0, t_col)

	# Diagonal micro-stripes on tape
	for sx in range(int(tx) + 4, int(tx + tw) - 2, 7):
		draw_line(Vector2(sx, ty + 1), Vector2(sx + 5, ty + th - 1), paper_white, 1.5)

	# Tape outline
	draw_rect_rounded_outline(tape_rect, 3.0, ink_color, 1.5)

func draw_header_badge(r: Rect2, theme_col: Color) -> void:
	var font = ThemeDB.fallback_font
	var not_sym = TileDefs.get_symbol(tile_type, TYPE_SYMBOLS.get(tile_type, "♩"))
	var header_str = "%s  %s" % [tile_type, not_sym]

	# Embossed white pill badge in header
	var b_size = font.get_string_size(header_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
	var badge_w = b_size.x + 16.0
	var badge_x = (r.size.x - badge_w) / 2.0
	var badge_rect = Rect2(badge_x, 4, badge_w, 18)

	draw_rect_rounded(badge_rect, 6.0, ink_color.darkened(0.2))
	draw_rect_rounded_outline(badge_rect, 6.0, paper_white.lerp(theme_col, 0.4), 1.2)
	draw_string(font, Vector2((r.size.x - b_size.x) / 2.0, 17), header_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, paper_white)

func draw_tactile_arrow(center: Vector2, dir: String, fill_col: Color) -> void:
	var angle = 0.0
	match dir:
		"left": angle = PI
		"down": angle = PI / 2.0
		"up": angle = -PI / 2.0
		"right": angle = 0.0

	var points = PackedVector2Array([
		Vector2(20, 0),
		Vector2(-4, -16),
		Vector2(-4, -8),
		Vector2(-20, -8),
		Vector2(-20, 8),
		Vector2(-4, 8),
		Vector2(-4, 16)
	])

	var rotated_pts = PackedVector2Array()
	var shadow_pts = PackedVector2Array()
	for pt in points:
		var rot = pt.rotated(angle)
		rotated_pts.append(center + rot)
		shadow_pts.append(center + rot + Vector2(2, 3))

	# Arrow Drop Shadow
	draw_colored_polygon(shadow_pts, Color(0.1, 0.1, 0.15, 0.28))

	# Arrow Base Fill
	draw_colored_polygon(rotated_pts, fill_col)

	# Inner Highlight Rim along upper edges
	var hi_col = fill_col.lightened(0.4)
	for i in range(1, 4):
		draw_line(rotated_pts[i], rotated_pts[i + 1], hi_col, 2.0)

	# Thick Ink Outline
	draw_polyline(rotated_pts + PackedVector2Array([rotated_pts[0]]), ink_color, 2.8)

	# Center Pop Star Dot
	draw_circle(center, 3.2, paper_white)
	draw_arc(center, 3.2, 0, TAU, 8, ink_color, 1.5)

func draw_rest_face(center: Vector2) -> void:
	# Sleeping comic character face
	# Closed smiling eye arcs ⌒ ⌒
	draw_arc(center + Vector2(-9, -2), 5.5, PI + 0.3, TAU - 0.3, 8, ink_color, 2.5)
	draw_arc(center + Vector2(9, -2), 5.5, PI + 0.3, TAU - 0.3, 8, ink_color, 2.5)

	# Rosy blushing cheeks
	draw_circle(center + Vector2(-15, 4), 4.0, Color(0.98, 0.55, 0.65, 0.5))
	draw_circle(center + Vector2(15, 4), 4.0, Color(0.98, 0.55, 0.65, 0.5))

	# Smiling sleeping mouth
	draw_arc(center + Vector2(0, 6), 6.0, 0.2, PI - 0.2, 10, ink_color, 2.5)

	# Floating animated "zZ" lettering
	var float_y = sin(idle_anim_time * 3.5) * 2.5
	var font = ThemeDB.fallback_font
	draw_string(font, center + Vector2(-10, -18 + float_y), "zZ", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, DIR_COLORS["rest"])

func draw_sub_hit_beads(r: Rect2) -> void:
	# Skip the bead row for a plain on-beat single hit (Q); still show it for
	# single off-beat hits like ER so the player can see where the note lands.
	if sub_hits.is_empty():
		return
	if sub_hits.size() == 1 and is_zero_approx(float(sub_hits[0].get("offset", 0.0))):
		return

	var dot_y = r.size.y - 14.0
	var usable_w = r.size.x - 28.0

	for i in range(sub_hits.size()):
		var h_info = sub_hits[i]
		var offset_val = float(h_info.get("offset", 0.0))
		var sub_dir = str(h_info.get("dir", primary_dir))
		var dot_x = 14.0 + (offset_val * usable_w)
		var dot_pos = Vector2(dot_x, dot_y)
		var state = sub_states[i] if i < sub_states.size() else 0

		# Bead drop shadow
		draw_circle(dot_pos + Vector2(1, 1.5), 5.5, Color(0.1, 0.1, 0.15, 0.25))

		match state:
			1: # Hit! (Gleaming Emerald / Gold Jewel Bead)
				var hit_col = Color("#38B000")
				draw_circle(dot_pos, 5.5, hit_col)
				# Specular shine dot
				draw_circle(dot_pos + Vector2(-1.5, -1.5), 1.8, paper_white)
				draw_arc(dot_pos, 5.5, 0, TAU, 14, ink_color, 2.0)
			2: # Missed (Stamped Red X)
				draw_circle(dot_pos, 5.0, Color("#D90429"))
				draw_arc(dot_pos, 5.0, 0, TAU, 12, ink_color, 1.8)
				# Mini X
				draw_line(dot_pos + Vector2(-2, -2), dot_pos + Vector2(2, 2), paper_white, 1.5)
				draw_line(dot_pos + Vector2(2, -2), dot_pos + Vector2(-2, 2), paper_white, 1.5)
			_: # Pending (Stamped Rhythm Bead)
				var base_c = DIR_COLORS.get(sub_dir, ink_color)
				draw_circle(dot_pos, 4.8, base_c.lerp(paper_white, 0.4))
				draw_arc(dot_pos, 4.8, 0, TAU, 12, ink_color, 1.8)
				draw_circle(dot_pos, 1.8, ink_color)

func draw_glossy_sticker_sheen(r: Rect2) -> void:
	# Diagonal white translucent sheen across card (collectible sticker shine)
	var sheen_col = Color(1.0, 1.0, 1.0, 0.12)
	var pts = PackedVector2Array([
		Vector2(10, r.size.y - 10),
		Vector2(r.size.x - 20, 32),
		Vector2(r.size.x - 10, 32),
		Vector2(20, r.size.y - 10)
	])
	draw_colored_polygon(pts, sheen_col)

func draw_laser_playhead(r: Rect2) -> void:
	var sweep_x = r.size.x * playhead_progress

	# Soft laser glow halo
	var glow_col = hero_yellow
	glow_col.a = 0.35
	draw_rect(Rect2(sweep_x - 4, 27, 8, r.size.y - 35), glow_col)

	# Bright laser core beam
	draw_line(Vector2(sweep_x, 27), Vector2(sweep_x, r.size.y - 8), hero_yellow, 3.2)
	draw_line(Vector2(sweep_x, 27), Vector2(sweep_x, r.size.y - 8), paper_white, 1.2)

	# Top and Bottom Diamond Playhead Markers
	draw_diamond(Vector2(sweep_x, 27), 4.5, hero_yellow, ink_color)
	draw_diamond(Vector2(sweep_x, r.size.y - 8), 4.5, hero_yellow, ink_color)

func draw_diamond(pos: Vector2, r: float, fill_col: Color, out_col: Color) -> void:
	var pts = PackedVector2Array([
		pos + Vector2(0, -r),
		pos + Vector2(r, 0),
		pos + Vector2(0, r),
		pos + Vector2(-r, 0)
	])
	draw_colored_polygon(pts, fill_col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), out_col, 1.5)

# Drawing Helpers
func draw_dashes(from_pos: Vector2, to_pos: Vector2, col: Color, width: float, dash_len: float, gap_len: float) -> void:
	var total_dist = from_pos.distance_to(to_pos)
	if total_dist <= 0.001:
		return
	var dir = (to_pos - from_pos).normalized()
	var cur = 0.0
	while cur < total_dist:
		var end_pt = min(cur + dash_len, total_dist)
		draw_line(from_pos + (dir * cur), from_pos + (dir * end_pt), col, width)
		cur += dash_len + gap_len

func draw_rect_rounded(r: Rect2, radius: float, col: Color) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	style.bg_color = col
	style.draw(get_canvas_item(), r)

func draw_rect_rounded_top(r: Rect2, radius: float, col: Color) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.bg_color = col
	style.draw(get_canvas_item(), r)

func draw_rect_rounded_outline(r: Rect2, radius: float, col: Color, width: float) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	style.draw_center = false
	style.border_width_left = int(width)
	style.border_width_top = int(width)
	style.border_width_right = int(width)
	style.border_width_bottom = int(width)
	style.border_color = col
	style.draw(get_canvas_item(), r)
