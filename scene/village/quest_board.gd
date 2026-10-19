extends StaticBody2D
## The village notice board (QST-2): new notes every morning. Take a note, bring
## the items back here, and the money is left under a stone.


func _ready() -> void:
	$InteractArea.interacted.connect(open)


func open() -> void:
	var board := GameState.quests
	var index := 0
	while true:
		var options: Array[String] = []
		for a in board.active:
			options.append("Hand in %d %s (%d/%d) - %dg, by day %d" % [a.quest.amount, a.quest.item.display_name,
				mini(GameState.inventory.count(a.quest.item), a.quest.amount), a.quest.amount, a.quest.reward, a.deadline])
		for quest in board.offers:
			options.append("Note: %d %s - %dg" % [quest.amount, quest.item.display_name, quest.reward])
		options.append("Leave")
		var footer := "Notes taken: %d/%d" % [board.active.size(), QuestBoard.MAX_ACTIVE]
		if board.offers.is_empty() and board.active.is_empty():
			footer = "The board is empty. New notes appear by morning."
		UI.show_menu("Notice board", options, footer, index)
		index = await UI.menu_finished
		if index < 0 or index == options.size() - 1:
			return
		if index < board.active.size():
			var a: QuestBoard.Active = board.active[index]
			var reward := board.hand_in(a, GameState.inventory)
			if reward > 0:
				GameState.add_money(reward)
				UI.post_message("You leave them by the board. +%dg under the stone." % reward)
			else:
				UI.post_message("You don't have enough %s" % a.quest.item.display_name)
		else:
			var quest: QuestData = board.offers[index - board.active.size()]
			UI.show_dialogue([quest.get_note(), "(%d days to bring them.)" % quest.days], ["Take the note", "Leave it"])
			var choice: int = await UI.dialogue_finished
			if choice == 0:
				if board.take(quest, GameState.day):
					UI.post_message("You take the note. The pin is still warm.")
				else:
					UI.post_message("You can't carry any more notes.")
			index = 0
