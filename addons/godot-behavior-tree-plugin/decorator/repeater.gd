tool
extends BehaviorDecorator
class_name BehaviorRepeater, "repeat_icon.png"

# Decorator Node - repeats the same node until we either get a busy response
# This node ignores failed and OK responses, choosing to retick the node instead


# Whether there should be a limitted number of attempts before succeeding
export(bool) var limit_repeats: bool = false
# The maximum number of execution attempts per tick (if limit enabled)
export(int) var max_attempts: int = 3


func tick(tick: Tick) -> int:
	# 0..1 children
	for child in get_children():
		var attempts: int = 0
		while not (limit_repeats and attempts < max_attempts):
			attempts += 1
			if child.tick(tick) == ERR_BUSY:
				return ERR_BUSY
	
	return OK
