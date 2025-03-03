tool
extends BehaviorDecorator
class_name BehaviorRepeatUntilSucceed, "repeat_success_icon.png"

# Decorator Node - Repeats the same node until we get an OK response
#   this node ignores running and failed responses, choosing to retick the node instead


func tick(tick: Tick) -> int:
	# 0..1 children
	for c in get_children():
		while true:
			if c._execute(tick) == OK:
				return OK
	
	return OK
