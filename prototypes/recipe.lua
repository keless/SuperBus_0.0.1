--recipie.lua
data:extend({
	{
		type = "recipe",
		name = "superbus-1",
		energy_required = 0.25,
		enabled = true,
		ingredients = {
			{type="item", name="iron-plate", amount=15},
			{type="item", name="iron-gear-wheel", amount=15},
		},
		results = {
			{type="item", name="superbus-1", amount=1},
		},
		icon="__SuperBus__/graphics/icons/superbus-1.png",
		icon_size = 32,
	},
})