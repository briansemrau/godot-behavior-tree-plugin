tool
extends BehaviorDecorator
class_name BehaviorLimiter, "limiter_icon.png"


export(int) var max_calls: int = 0
var total_calls: int = 0


# Decorator Node
func tick(tick: Tick) -> int:
	if total_calls >= max_calls:
		return FAILED
	
	# 0..1 children
	for c in get_children():
		total_calls += 1
		return c._execute(tick)
	
	return FAILED
