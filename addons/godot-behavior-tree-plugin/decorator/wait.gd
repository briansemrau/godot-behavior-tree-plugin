tool
extends BehaviorDecorator
class_name BehaviorWait, "wait_icon.png"


# The time (in seconds) between each time the child is ticked.
export(float) var wait_time: float = 1.0
# Whether to wait before the first time the child is ticked when this node is opened.
export(bool) var wait_before_first_tick: bool = true

var _tick_time: float = 0.0


func _process(delta: float):
	_tick_time -= delta


func is_waiting() -> bool:
	return _tick_time > 0.0


func reset_wait():
	_tick_time = wait_time


func open(_tick: Tick) -> void:
	if wait_before_first_tick:
		_tick_time = wait_time
	else:
		_tick_time = 0.0
	set_process(true)


func tick(tick: Tick) -> int:
	if not is_waiting():
		# 0..1 children
		for c in get_children():
			var result = c.tick(tick)
			reset_wait()
			return result
	
	# Timer still ticking
	return ERR_BUSY


func close(_tick: Tick) -> void:
	set_process(false)
