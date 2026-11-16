class_name Visualizer
extends Control

@export var bars: int:
	set(value):
		bars = value
		_draw_visualizer()

@export_enum("Circle", "Circle Inverted", "Bar") var type: String

@export var radius: float = 140
@export var width_ratio: float = 1.0
@export var start_angle: float = -90
@export var angle_offset: float = 0.0
@export var start_range: float = 32
@export var hrtz_per_jump: float = 80
@export var length_radtio: float = 50

var _drawn: bool = false

func _ready() -> void:
	add_to_group("visualizer")
	_draw_visualizer()
	
	
func _draw_visualizer():
	_drawn = false
	for each in get_children():
		each.queue_free()

	match type:
		"Circle":
			_circle()
		"Circle Inverted":
			_circle_inverted()
		"Bar":
			_bar()
	_drawn = true


func set_type(t):
	type = t
	_draw_visualizer()

func _circle():
		
	var angle_step = TAU/bars
	var center = size / 2.0
	var width = (TAU * radius / bars ) * width_ratio
	for i in range(bars):
		var c = ColorRect.new()
		add_child(c)
		c.size = Vector2(width / 2.0, 100)
		
		c.pivot_offset = c.size / 2.0
		var angle = deg_to_rad(start_angle) + angle_step * i
		var direction = Vector2(cos(angle), sin(angle) )
		c.position = center + direction * (radius + 100 / 2.0)
		c.rotation = angle - PI / 2.0


func _circle_inverted():
		
	var angle_step = TAU/bars
	var center = size / 2.0
	var width = (TAU * radius / bars ) * width_ratio
	for i in range(bars):
		var c = ColorRect.new()
		add_child(c)
		c.size = Vector2(width / 2.0, 100)
		c.pivot_offset = c.size / 2.0
		var angle = deg_to_rad(start_angle) + angle_step * i
		var direction = Vector2(cos(angle), sin(angle) )
		c.position = center + direction * (radius + 100 / 2.0)
		c.rotation = angle + PI / 2.0


func _bar():
	var width = size.x / bars
	for i in range(bars):
		var c = ColorRect.new()
		c.size = Vector2(width, 100)
		c.position = Vector2(1*i*width, size.y)
		c.rotation = -PI
		add_child(c)


func _process(delta: float) -> void:
	if _drawn == false: return
	var spa = AudioServer.get_bus_effect_instance(0, 1) as AudioEffectSpectrumAnalyzerInstance
	var c = 1
	for each in get_children():
		each.size = Vector2((TAU * radius / bars) * width_ratio, spa.get_magnitude_for_frequency_range(start_range * c, start_range * c + hrtz_per_jump).y * length_radtio)
		c+=1
