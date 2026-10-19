class_name JobData
extends Resource
## A task the man on the phone gives: ship some items by a deadline for money.
## To add a job, create a .tres from this script in data/jobs and list it in GameState.jobs.

@export var item: ItemData
@export var amount := 5
@export var reward := 100
## Days the player has, counting today. The items must be in the shipping box by the end of day + days - 1.
@export var days := 3
## What the caller says. {amount}, {item}, {deadline} and {reward} are filled in.
@export var lines: Array[String] = []


func get_lines(deadline: int) -> Array[String]:
	var values := {"amount": amount, "item": item.display_name, "deadline": deadline, "reward": reward}
	var result: Array[String] = []
	for line in lines:
		result.append(line.format(values))
	return result
