extends Node
class_name BehaviorTreeNode, "root_icon.png"


const Tick = preload("tick.gd")


func _execute(tick: Tick) -> int:
	_enter(tick)
	
	if not tick.blackboard.get('isOpen', tick.tree, self):
		_open(tick)
	
	var status := _tick(tick)
	
	if status != ERR_BUSY:
		_close(tick)
	
	_exit(tick)
	
	return status


func _enter(tick: Tick) -> void:
	tick.enter_node(self)  # debug call to be filled out in Tick object
	enter(tick)


func _open(tick: Tick) -> void:
	tick.open_node(self)
	tick.blackboard.set('isOpen', true, tick.tree, self)
	open(tick)


func _tick(tick: Tick) -> int:
	tick.tick_node(self)
	return tick(tick)


func _close(tick: Tick) -> void:
	tick.close_node(self)
	tick.blackboard.set('isOpen', false, tick.tree, self)
	close(tick)


func _exit(tick: Tick) -> void:
	tick.exit_node(self)
	exit(tick)


# The following functions are to be overridden in extending nodes

# Called every tick before `tick`.
func enter(tick: Tick) -> void:
	pass

# Called once before `tick` when the node begins evaluation.
func open(tick: Tick) -> void:
	pass

func tick(tick: Tick) -> int:
	# Implement node execution and state evaluation here.
	return OK

# Called once after `tick` when the node reaches status SUCCESS (OK) or FAILED.
func close(tick: Tick) -> void:
	pass

# Called every tick after `tick`
func exit(tick: Tick) -> void:
	pass
