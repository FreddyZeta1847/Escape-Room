extends Node

## Singleton that handles the attribute-based interaction system.
##
## Items have attributes: Array[String]
## Containers (props) have: required_attribute, lock_type, contained_items
##
## When a player uses an item on a prop, the system checks for attribute matches.
## On success, all contained_items are given to the player automatically.

## Emitted when an item successfully opens a container.
signal container_opened(prop_name: String, item_name: String)
## Emitted when an item fails to open a container (wrong attribute).
signal interaction_failed(prop_name: String, item_name: String)
## Emitted when a combination lock is solved.
signal combination_solved(prop_name: String)
## Emitted when a hidden hotspot is discovered.
signal discovery_made(prop_name: String)

## Lock types for interactive props. Set these on prop scripts as:
##   var lock_type: int = InteractionSystem.LockType.ATTRIBUTE
enum LockType {
	NONE,        ## No lock — plain clickable prop
	ATTRIBUTE,   ## Requires an item with a matching attribute
	COMBINATION, ## Knowledge-based — player enters a code
	DISCOVERY,   ## Hidden hotspot — just find and click
}


## Try to use an inventory item on an attribute-locked container.
## Call this from a prop's _on_item_used() override.
## On success, gives the player all contained_items automatically.
## Returns true if the item matched and the container opened.
func try_use_item(
	item: PopochiuInventoryItem,
	required_attribute: String,
	contained_items: Array,
	prop_name: String
) -> bool:
	if required_attribute.is_empty():
		return false

	# Check if the item has an attributes array and if it contains the required one
	if not "attributes" in item:
		interaction_failed.emit(prop_name, item.script_name)
		return false

	if required_attribute not in item.attributes:
		interaction_failed.emit(prop_name, item.script_name)
		return false

	# Success — give the player all contained items
	await _give_contained_items(contained_items)
	container_opened.emit(prop_name, item.script_name)
	return true


## Validate a combination code attempt.
## Call this from the safe's combination lock UI.
## On success, gives the player all contained_items automatically.
## Returns true if the code matches.
func try_combination(
	entered_code: String,
	correct_code: String,
	contained_items: Array,
	prop_name: String
) -> bool:
	if entered_code != correct_code:
		return false

	await _give_contained_items(contained_items)
	combination_solved.emit(prop_name)
	return true


## Register a discovery (hidden hotspot found and clicked).
## Call this from a prop's _on_click() when revealing a hidden element.
## Gives the player all contained_items automatically.
func register_discovery(contained_items: Array, prop_name: String) -> void:
	await _give_contained_items(contained_items)
	discovery_made.emit(prop_name)


## Check all inventory items for one with the required attribute.
## If found, auto-use it on the container. Returns true if opened.
func try_open_with_inventory(
	required_attribute: String,
	contained_items: Array,
	prop_name: String
) -> bool:
	if required_attribute.is_empty():
		return false

	for item_name: String in I._item_instances:
		var item: PopochiuInventoryItem = I._item_instances[item_name]
		if not item.in_inventory:
			continue
		if "attributes" in item and required_attribute in item.attributes:
			await _give_contained_items(contained_items)
			container_opened.emit(prop_name, item.script_name)
			return true

	return false


## Default message when using the wrong item on a container.
func get_failure_message() -> String:
	return "That doesn't seem to work."


## Default message when clicking a locked container without an active item.
func get_locked_message() -> String:
	return "It's locked. I need something to open it."


## Add each item in contained_items to the player's inventory.
func _give_contained_items(contained_items: Array) -> void:
	for item_name: String in contained_items:
		var item_instance: PopochiuInventoryItem = I.get_item_instance(item_name)
		if item_instance and not item_instance.in_inventory:
			await item_instance.add()
