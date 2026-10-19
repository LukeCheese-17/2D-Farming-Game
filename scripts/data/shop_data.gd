class_name ShopData
extends Resource
## What a rebuilt village building sells and makes.

@export var title: String
## Items bought with money, at each item's buy_price.
@export var stock: Array[ItemData] = []
## Things made from materials.
@export var recipes: Array[RecipeData] = []
@export var greeting := ""
