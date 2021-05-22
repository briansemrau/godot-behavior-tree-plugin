# Godot Engine Behavior Tree Editor Plugin

A Behavior Tree implementation for the Godot Engine, written in pure GDScript.

This project is a Godot Engine addon that adds a collection of nodes to the editor that facilitate the implementation of Behavior Trees. It is released under the terms of the MIT License.

This is a fork from Brandon Lamb (https://github.com/godot-addons/godot-behavior-tree-plugin) which is a fork from Jeff Olson (https://github.com/olsonjeffery/behv_godot), which is itself based on ideas/concepts from https://github.com/quabug/godot_behavior_tree.

# Installation and Basic Usage

1. Clone this repository into your `res://addons/` or use git submodule.
2. In your project settings, enable the plugin
3. Add a `BehaviorTree` and a `Blackboard` node to a scene
4. In `_process` or `_physics_process` call the tree's tick function passing in the actor and the blackboard instance (e.g. `$BehaviorTree.tick(actor, $Blackboard)`)
5. In your actions, extend the default action script and add a tick method where all of your logic will go ([See example](#implementing-your-own-type) or [`bt_base.gd`](addons/godot-behavior-tree-plugin/bt_base.gd#L51))

# Design philosophy

- Easy to use and reason about - just Behavior Trees!
- Unobtrusive - to integrate an existing workflow
  - the BT primitives are implemented as Nodes that get added directly onto a scene; Actions are just normal nodes that you extend with a script. This enables easy reuse with scene instances and editor copy/paste functionality.
  - Build out a tree and attach it to your actor/entity sprite and just call `.tick()` during `_process()` or `_physics_process()`
  - Uses a simple `Dictionary` value as the context object
- Add add little as possible to Godot -
  - The system uses existing numeric constants (`OK`, `FAILED` and `ERR_BUSY`) as stand-ins for the existing "Success, Failure, Running" concepts in BT.
  - The entire thing is implemented as a pure-GDScript addon that can be easily added to a project without having to rebuild the Godot editor

# State Values

* `OK` (a.k.a. "Success"): Returned when a criterion has been met by a condition node or an action node has been completed successfully;

* `FAILED`: Returned when a criterion has not been met by a condition node or an action node could not finish its execution for any reason;

* `ERR_BUSY` (a.k.a. "Running"): Returned when an action node has been initialized but is still waiting the its resolution.

* ~~`BehaviorError`: Returned when some unexpected error happened in the tree, probably by a programming error (trying to verify an undefined variable). Its use depends on the final implementation of the leaf nodes.~~

# Node types

## BehaviorTree

Place this at the root of your tree at the AI/agent level. The [`BehaviorTree`](addons/godot-behavior-tree-plugin/behavior_tree.gd) node accepts only a *single child* node. For example, you would probably add some kind of composite such as a [`BehaviorSequence`](#behaviorsequence) node.

From a code perspective, this is a very simple node intended to be the root / entry-point to your Behavior tree logic. It creates a 'tick' object and will then simply call down to its child's `tick(tick)` function recursively.

## Tick object

The [`Tick`](addons/godot-behavior-tree-plugin/tick.gd) object is created internally by the BehaviorTree, and passed in to each child node.  It mostly functions as a way to pass references through the tree (automatically containing a reference to the tree, the blackboard, and the actor the tree is currently acting on).

## Blackboard

The [`Blackboard`](addons/godot-behavior-tree-plugin/blackboard.gd) acts as a memory repository for your actor.  It is passed in to the tree, and its `get()` and `set()` functions will store things based on arguments given.  For example, passing `get()` a key, a reference to the tree (contained on the `Tick` object), and a reference to the node, a node can pull node-specific information.  Leaving off the node reference will automatically make the `get()` search only the tree level storage.  Using `set()` works similiarly.  Calling `set()` with a key and a value will set an entry in memory for any user of the blackboard; calling it with a tree reference as well will store it in the memory for only that tree (or anything with a reference to the tree); and with a tree and a node will store it in memory for that node in the specific tree.
All nodes will have access to a `Blackboard`, as it is stored on a [`Tick`](#tick-object) object.

## Composite Types

Composite nodes can have one or more children. The node is responsible to propagate the tick signal to its children, respecting some order. A composite node also must decide which and when to return the state values of its children, when the value is `OK` or `FAILED`. Notice that when a child returns `ERR_BUSY` ~~or `BehaviorError`~~, the composite node must return the state immediately. All composite nodes are represented graphically as a white box with a certain symbol inside.

<details>
<summary>Click to show composite types</summary>

### BehaviorSequence

A [`BehaviorSequence`](addons/godot-behavior-tree-plugin/composite/sequence.gd) node runs a collection of child nodes, stopping at the first failure or `ERR_BUSY`.

The `BehaviorSequence` node ticks its children sequentially until one of them returns `FAILED` or `ERR_BUSY` ~~or `BehaviorError`~~. If all children return the success state, the sequence also returns `OK`.

  - Will return and complete if any child returns `FAILED`, returning `FAILED`
  - Will return `OK` if all children return `OK`
  - Will return if any child returns `ERR_BUSY`. ~~Will resume at the `ERR_BUSY`-returning child~~

If you want the sequence to remember its place between ticks if a child returns `ERR_BUSY`, use [`BehaviorSequenceMem`](addons/godot-behavior-tree-plugin/composite/mem_sequence.gd). This is useful for sequenced animations.

### BehaviorSelector

A [`BehaviorSelector`](addons/godot-behavior-tree-plugin/composite/selector.gd) node runs a collection of child nodes, stopping at the first success or `ERR_BUSY`.

The `BehaviorSelector` node ticks its children sequentially until one of them returns `OK` or `ERR_BUSY`. If all children return the failure state, the selector also returns `FAILED`.

For instance, suppose that a cleaning robot have a behavior to turn itself off. When the robot tries to turn itself off, the first action is performed and the robot tries to get back to its charging dock and turn off all its systems, but if this action fail for some reason (e.g., it could not find the dock) an emergency shutdown will be performed.

  - Will return and complete if any child returns `OK`, returning `OK`
  - Will return `FAILED` if all children return `FAILED`
  - Will return if any child returns `ERR_BUSY`. ~~Will resume at the `ERR_BUSY`-returning child~~

If you want the selector to remember its place between ticks if a child returns `ERR_BUSY`, use [`BehaviorSelectorMem`](addons/godot-behavior-tree-plugin/mem_selector.gd). This may be useful for preventing higher priority behaviors from interrupting lower priority behaviors.

</details>

## Decorator Types

Decorators are special nodes that can have only a single child. The goal of the decorator is to change the behavior of the child by manipulating the returning value or changing its ticking frequency. For example, a decorator may invert the result state of its child, similar to the NOT operator, or it can repeat the execution of the child for a predefined number of times.

<details>
<summary>Click to show decorator types</summary>

### Failer

The [`BehaviorFailer`](addons/godot-behavior-tree-plugin/decorator/failer.gd) decorator is the inverse of [`BehaviorSuceeder`](#succeeder), this decorator return `FAILED` for any child result.

### Inverter

The [`BehaviorInverter`](addons/godot-behavior-tree-plugin/decorator/inverter.gd) decorator negates the result of its child node, i.e., `OK` state becomes `FAILED`, and `FAILED` becomes `OK`. Notice that inverter does not change `ERR_BUSY` ~~or `BehaviorError` states~~.

### Limiter

The [`BehaviorLimiter`](addons/godot-behavior-tree-plugin/decorator/limiter.gd) decorator imposes a maximum number of calls its child can have within the whole execution of the Behavior Tree, i.e., after a certain number of calls, its child will never be called again.

### ~~Max Time~~

~~The `BehaviorMaxTime` decorator limits the maximum time its child can be running. If the child does not complete its execution before the maximum time, the child task is terminated and a failure is returned, as shown algorithm below.~~

### Wait

The [`BehaviorWait`](addons/godot-behavior-tree-plugin/decorator/wait.gd) decorator creates a delay between each time the child is ticked.

### Repeater

The [`BehaviorRepeater`](addons/godot-behavior-tree-plugin/decorator/repeater.gd) decorator ticks the child repeatedly until the child returns a `ERR_BUSY` state. Additionally, a maximum number of repetition can be provided. Beware that without a limit, this can easily create an infinite loop and halt your game.

### Repeat Until Failed

The [`BehaviorRepeatUntilFailed`](addons/godot-behavior-tree-plugin/decorator/repeat_until_fail.gd) decorator keeps calling its child until the child returns a `FAILED` value. When this happen, the decorator return a `OK` state.

### Repeat Until Succeed

Similar to the [`BehaviorRepeatUntilFailed`](#repeat-until-failed) decorator, the [`BehaviorRepeatUntilSucceed`](addons/godot-behavior-tree-plugin/decorator/repeat_until_succeed.gd) decorator calls the child until it returns a `OK`.

### Succeeder

The [`BehaviorSucceeder`](addons/godot-behavior-tree-plugin/decorator/succeeder.gd) is a decorator that returns `OK` always, no matter what its child returns. This is useful for actions that you don't need to succeed, as well as for debug and test purposes.

</details>

## Leaf Types

Leaf nodes are the primitive building blocks of behavior trees. These nodes do not have any children and therefore do not propagate the tick signal. These nodes perform some computation and return a state value. There are two types of leaf nodes (conditions and actions) and are categorized by their responsibility.

<details>
<summary>Click to show leaf types</summary>

### Action

[`BehaviorAction`](addons/godot-behavior-tree-plugin/leaf/action.gd) nodes perform computations to change the actor state. The actions implementation depends on the actor type, e.g., the actions of a robot may involve sending motor signals, sending sounds through speakers or turning on lights, while the actions of a NPC may involve executing animations, performing spacial transformations, playing a sound, etc.

Actions may not be only external (i.e, actions that changes the environment as result of changes on the agent), they can be internal too, e.g., registering logs, saving files, changing internal variables, etc.

An action returns `OK` if it could be completed; returns `FAILED` if, for any reason, it could not be finished; or returns `ERR_BUSY` while executing the action.

### Condition

[`BehaviorCondition`](addons/godot-behavior-tree-plugin/condition.gd) nodes check whether a certain condition has been met or not. In order to accomplish this, the node must have a target variable (e.g. a perception information such as "obstacle distance" or "other agent visibility"; or an internal variable such as "battery level" or "hungry level"; etc.) and a criteria to base the decision (e.g.: "obstacle distance > 100m?" or "battery power < 10%?").

These nodes return `OK` if the condition has been met and `FAILED` otherwise. Notice that, conditions do not return `ERR_BUSY` nor change values of system.

</details>

## Implementing Your Own Type

When creating a behavior tree, you will eventually need to implement your own actions, conditions, or even your own decorators and composite nodes.

<details>
<summary>
Click to view example BehaviorAction
</summary>

```gdscript
extends BehaviorAction # or BehaviorCondition, BehaviorDecorator, BehaviorTreeNode

# Called every tick before `tick`. This is rarely useful.
#func enter(tick: Tick) -> void:
#	pass

# Called once before `tick` when the node begins evaluation.
#func open(tick: Tick) -> void:
#	pass

func tick(tick: Tick) -> int:
	# Implement node execution and state evaluation here.
	
	# Example:
	var enemy = tick.blackboard.get("targetted_enemy", tick.tree)
	var actor = tick.actor
	if not actor.is_in_range(enemy):  # alternatively, make this a prior condition in a sequence
		return FAILED
	actor.attack(enemy)
	
	return OK

# Called once after `tick` when the node reaches status SUCCESS (OK) or FAILED.
#func close(tick: Tick) -> void:
#	pass

# Called every tick after `tick`. This is rarely useful.
#func exit(tick: Tick) -> void:
#	pass
```
</details>

# Links

* https://github.com/Kriet108/godot-behavior-tree-plugin
* https://github.com/brandonlamb/godot-behavior-tree-plugin
* https://github.com/olsonjeffery/behv_godot
* https://github.com/quabug/godot_behavior_tree
* http://blog.renatopp.com/2014/07/25/an-introduction-to-behavior-trees-part-1/
* http://blog.renatopp.com/2014/08/10/an-introduction-to-behavior-trees-part-2/
* http://blog.renatopp.com/2014/08/10/an-introduction-to-behavior-trees-part-3/
