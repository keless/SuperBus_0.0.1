--item.lua
data:extend({

    {
        type = "item",
        name = "superbus-1",
        icon = "__SuperBus__/graphics/icons/superbus-1.png",
        icon_size = 32,
        flags = {"goes-to-quickbar"},
        subgroup = "belt",
        order = "a[transport-belt]-b[superbus-1]",
        place_result = "superbus-1",
        stack_size = 50
    },
})