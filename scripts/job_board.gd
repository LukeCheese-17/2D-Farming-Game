class_name JobBoard
extends RefCounted
## Tracks the jobs the man on the phone gives: which one is active, its deadline,
## and how much of it has been shipped.

signal changed

## Jobs in the order he gives them. After the last one he repeats them.
var jobs: Array[JobData] = []
var active: JobData
## Last day the items can go in the shipping box.
var deadline := 0
var progress := 0
## Result of the last finished job: "", "done" or "failed". The caller mentions it on his next call.
var last_result := ""

var _next_index := 0


func _init(job_list: Array[JobData]) -> void:
	jobs = job_list


func get_next() -> JobData:
	return jobs[_next_index % jobs.size()]


## Starts the next job on the given day and returns it.
func accept_next(day: int) -> JobData:
	active = get_next()
	deadline = day + active.days - 1
	progress = 0
	_next_index += 1
	changed.emit()
	return active


## Called with each item sold overnight.
func record_sold(item: ItemData, amount: int) -> void:
	if active and item == active.item:
		progress += amount
		changed.emit()


func is_complete() -> bool:
	return active != null and progress >= active.amount


## Ends the active job ("done" or "failed").
func finish(result: String) -> void:
	active = null
	last_result = result
	changed.emit()
