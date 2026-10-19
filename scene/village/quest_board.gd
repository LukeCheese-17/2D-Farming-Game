extends StaticBody2D
## The village notice board (QST-2): the main quest from the man on the phone,
## and two small notes that change every morning (paid under a stone).


func _ready() -> void:
	$InteractArea.interacted.connect(open)


func open() -> void:
	var board := GameState.quests
	var inv := GameState.inventory
	var index := 0
	while true:
		var options: Array[String] = []
		var main := board.get_main()
		if main:
			if board.is_main_done():
				options.append("%s - done. Call him." % main.title)
			elif main.kind == QuestData.Kind.ITEMS:
				options.append("%s: %d/%d %s" % [main.title, mini(inv.count(main.item), main.amount), main.amount, main.item.display_name])
			else:
				options.append("%s: %s" % [main.title, main.get_goal()])
		for i in board.daily.size():
			var quest := board.daily[i]
			if board.daily_done[i]:
				options.append("Note: %s - done" % quest.item.display_name)
			else:
				options.append("Note: %d/%d %s - %dg" % [mini(inv.count(quest.item), quest.amount), quest.amount,
					quest.item.display_name, quest.reward])
		options.append("Leave")
		var footer := "New notes appear every morning."
		if not board.main_posted:
			footer = "A clean square where a bigger note could go. " + footer
		elif main == null:
			footer = "He hasn't pinned anything new. " + footer
		UI.show_menu("Notice board", options, footer, index)
		index = await UI.menu_finished
		if index < 0 or index == options.size() - 1:
			return
		if main:
			if index == 0:
				await _open_main(main)
				continue
			index -= 1
		await _open_daily(index)
		if main:
			index += 1


func _open_main(quest: QuestData) -> void:
	var board := GameState.quests
	if board.is_main_done():
		UI.post_message("Done. He said to call when it's done.")
		return
	var choices: Array[String] = []
	if quest.kind == QuestData.Kind.ITEMS:
		choices = ["Hand them in", "Leave it"]
	UI.show_dialogue([quest.title.to_upper(), quest.get_note(), "(%s, then call him. %dg.)" % [quest.get_goal(), quest.reward]], choices)
	var choice: int = await UI.dialogue_finished
	if choice == 0 and quest.kind == QuestData.Kind.ITEMS:
		if board.hand_in_main(GameState.inventory):
			UI.post_message("You leave them by the board. Call him for the money.")
		else:
			UI.post_message("You don't have enough %s" % quest.item.display_name)


func _open_daily(i: int) -> void:
	var board := GameState.quests
	if board.daily_done[i]:
		UI.post_message("Already handed in. Come back tomorrow.")
		return
	var quest := board.daily[i]
	if GameState.inventory.count(quest.item) >= quest.amount:
		var reward := board.hand_in_daily(i, GameState.inventory)
		GameState.add_money(reward)
		UI.post_message("You leave them by the board. +%dg under the stone." % reward)
	else:
		UI.show_dialogue([quest.get_note(), "(Today only.)"])
		await UI.dialogue_finished
