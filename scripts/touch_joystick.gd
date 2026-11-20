extends Control

signal vector_changed(value: Vector2)

var finger_index: int = -1
var stick_value: Vector2 = Vector2.ZERO
var knob_position: Vector2 = Vector2.ZERO
var active_radius: float = 62.0
var display_label: String = "MOVE"

func _ready() -> void:
    custom_minimum_size = Vector2(180, 180)
    mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and finger_index == -1:
            finger_index = event.index
            _update_stick(event.position)
        elif not event.pressed and event.index == finger_index:
            _release_stick()
    elif event is InputEventScreenDrag and event.index == finger_index:
        _update_stick(event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            finger_index = 999
            _update_stick(event.position)
        else:
            _release_stick()
    elif event is InputEventMouseMotion and finger_index == 999 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        _update_stick(event.position)

func _release_stick() -> void:
    finger_index = -1
    stick_value = Vector2.ZERO
    knob_position = size * 0.5
    vector_changed.emit(stick_value)
    queue_redraw()

func _update_stick(point: Vector2) -> void:
    var center := size * 0.5
    var offset := point - center
    if offset.length() > active_radius:
        offset = offset.normalized() * active_radius
    knob_position = center + offset
    stick_value = Vector2(offset.x / active_radius, offset.y / active_radius)
    vector_changed.emit(stick_value)
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    var knob := knob_position if knob_position != Vector2.ZERO else center
    draw_circle(center, active_radius + 13.0, Color(0.025, 0.035, 0.032, 0.66))
    draw_arc(center, active_radius + 13.0, 0.0, TAU, 64, Color(0.68, 0.76, 0.66, 0.52), 2.2)
    draw_arc(center, active_radius - 8.0, 0.0, TAU, 64, Color(0.64, 0.72, 0.63, 0.16), 1.0)
    draw_line(center + Vector2(-active_radius + 8.0, 0), center + Vector2(active_radius - 8.0, 0), Color(0.7, 0.77, 0.68, 0.12), 1.0)
    draw_line(center + Vector2(0, -active_radius + 8.0), center + Vector2(0, active_radius - 8.0), Color(0.7, 0.77, 0.68, 0.12), 1.0)
    draw_circle(knob, 29.0 if active_radius > 52.0 else 25.0, Color(0.42, 0.51, 0.43, 0.94))
    draw_circle(knob, 21.0 if active_radius > 52.0 else 18.0, Color(0.19, 0.27, 0.22, 0.98))
    draw_arc(knob, 29.0 if active_radius > 52.0 else 25.0, 0.0, TAU, 48, Color(0.91, 0.91, 0.78, 0.86), 2.0)
    var font := get_theme_default_font()
    if font:
        draw_string(font, center + Vector2(-active_radius, active_radius + 30.0), display_label, HORIZONTAL_ALIGNMENT_CENTER, active_radius * 2.0, 13, Color(0.86, 0.9, 0.82, 0.9))
