extends Control

var phase: float = 0.0
var marker: float = 0.5
var pulse: float = 0.0

func _process(delta: float) -> void:
	phase = fposmod(phase + delta * 1.85, TAU)
	marker = 0.5 + sin(phase) * 0.46
	pulse += delta * 3.0
	queue_redraw()

func get_timing_grade() -> String:
	var distance: float = absf(marker - 0.5)
	if distance <= 0.085:
		return "perfect"
	if distance <= 0.24:
		return "good"
	return "rough"

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 20.0 or h < 20.0:
		return
	var bar := Rect2(8.0, 25.0, w - 16.0, 18.0)
	draw_string(ThemeDB.fallback_font, Vector2(10.0, 16.0), "РИТМ УДАРА • ПОПАДИ В ЗОЛОТУЮ ЗОНУ", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d8c5b1"))
	draw_rect(bar, Color("#211c25"), true)
	draw_rect(Rect2(bar.position.x + bar.size.x * 0.26, bar.position.y, bar.size.x * 0.48, bar.size.y), Color("#58604b"), true)
	draw_rect(Rect2(bar.position.x + bar.size.x * 0.415, bar.position.y, bar.size.x * 0.17, bar.size.y), Color("#c49a54"), true)
	draw_rect(bar, Color("#79636a"), false, 2.0)
	var x: float = bar.position.x + marker * bar.size.x
	draw_line(Vector2(x, bar.position.y - 5.0), Vector2(x, bar.position.y + bar.size.y + 5.0), Color("#fff0cb"), 4.0)
	var glow: float = 0.5 + 0.5 * sin(pulse)
	draw_circle(Vector2(x, bar.position.y + bar.size.y * 0.5), 3.0 + glow * 2.0, Color("#ffcf7d"))
	var grade: String = get_timing_grade()
	var caption: String = "ИДЕАЛЬНО" if grade == "perfect" else ("ХОРОШО" if grade == "good" else "ПОПРОБУЙ ПОПАСТЬ")
	var tint: Color = Color("#ffe0a0") if grade == "perfect" else (Color("#c5d5a5") if grade == "good" else Color("#c99b91"))
	draw_string(ThemeDB.fallback_font, Vector2(w - 10.0, h - 3.0), caption, HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, tint)
