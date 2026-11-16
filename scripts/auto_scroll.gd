class_name AutoScroll
extends ScrollContainer

@export var speed: float = 1.0
@export var scroll_h: bool = false
@export var scroll_v: bool = false

var scroll_timer: Timer

func _ready() -> void:
	scroll_timer = Timer.new()
	add_child(scroll_timer)
	scroll_timer.timeout.connect(_on_scroll)
	scroll_timer.wait_time = speed
	scroll_timer.start()

func _on_scroll():
	if scroll_h:
		scroll_horizontal += 1

		if scroll_horizontal >= get_h_scroll_bar().max_value - get_h_scroll_bar().page:
			scroll_horizontal = 0
	if scroll_v:
		scroll_vertical += 1
	
