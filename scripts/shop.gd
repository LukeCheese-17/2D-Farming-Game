class_name Shop
## Runs a shop menu for a ShopData: buy stock with money, make recipes from materials.


static func open(shop: ShopData) -> void:
	if shop.greeting != "":
		UI.show_dialogue([shop.greeting])
		await UI.dialogue_finished
	var index := 0
	while true:
		var options: Array[String] = []
		for item in shop.stock:
			options.append("%s - %dg" % [item.display_name, item.buy_price])
		for recipe in shop.recipes:
			options.append("%s - %s" % [recipe.result.display_name, recipe.get_cost_text()])
		options.append("Leave")
		UI.show_menu(shop.title, options, "You have %dg" % GameState.money, index)
		index = await UI.menu_finished
		if index < 0 or index == options.size() - 1:
			return
		if index < shop.stock.size():
			var item := shop.stock[index]
			if GameState.buy(item):
				UI.post_message("Bought %s" % item.display_name)
			else:
				UI.post_message("Not enough money" if GameState.money < item.buy_price else "Your bag is full")
		else:
			var recipe := shop.recipes[index - shop.stock.size()]
			if GameState.make(recipe):
				UI.post_message("You got the %s" % recipe.result.display_name.to_lower())
			elif recipe.replaces and GameState.inventory.count(recipe.replaces) == 0:
				UI.post_message("Bring your %s" % recipe.replaces.display_name.to_lower())
			else:
				UI.post_message("You don't have everything")
