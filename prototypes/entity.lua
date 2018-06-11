--entity.lua
require("prototypes.render_utils")

--hack: modify assmembling-machine-2
require "util"
local overrideAS2 = table.deepcopy(data.raw['assembling-machine']['assembling-machine-2'])
--hack: make assembly 2 machines show fluid boxes always
--overrideAS2.fluid_boxes.off_when_no_fluid_recipe = false
overrideAS2.supports_direction = true
overrideAS2.rotatable = true

data:extend({
  overrideAS2,


  {
    type = "assembling-machine",
    name = "superbus-1",
    icon = "__SuperBus__/graphics/icons/superbus-1.png",
    icon_size = 32,
    flags = {"placeable-neutral", "placeable-player", "player-creation"},
    minable = {hardness = 0.2, mining_time = 0.5, result = "superbus-1"},
    max_health = 350,
    inventory_size = 16,
    tile_width = 4,
    tile_height = 4,
    collision_box = {{-1.8, -1.8}, {1.8, 1.8}},
    selection_box = {{-2, -2}, {2, 2}},
    corpse = "big-remnants",
    dying_explosion = "medium-explosion",
    --alert_icon_shift = util.by_pixel(-3, -12),
    fast_replaceable_group = "superbus",
    animation = make_4way_animation_from_spritesheet({
      layers =
      {
        {
          filename = "__SuperBus__/graphics/entity/superbus-1.png",
          width = 108,
          height = 114,
          line_length = 8,
          scale = 1.33,
          shift = util.by_pixel(10, 2),
        },
        {
          filename = "__SuperBus__/graphics/entity/superbus-1-shadow.png",
          width = 95,
          height = 83,
          line_length = 1,
          repeat_count = 32,
          draw_as_shadow = true,
          scale = 1.33,
          shift = util.by_pixel(8.5, 5.5),
        },
      },
    }),
    open_sound = { filename = "__base__/sound/machine-open.ogg", volume = 0.85 },
    close_sound = { filename = "__base__/sound/machine-close.ogg", volume = 0.75 },
    vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
    working_sound =
    {
      sound =
      {
        filename = "__base__/sound/fast-transport-belt.ogg",
        volume = 0.2
      },
      max_sounds_per_type = 1
    },
    module_specification =
    {
      module_slots = 3
    },
    allowed_effects = {"speed"},
    supports_direction = true,
    rotatable = true,
    fluid_boxes = {
      {
        production_type = "input",
        pipe_covers = invisible_pipecoverpictures(),
        base_area = 10,
        base_level = 1,
        pipe_connections = {
          { type="input", position = {1.5, 2.4} }, -- front
          { type="input", position = {2.4, 1.5} }, -- side1
          { type="input", position = {-2.4, 1.5} }, -- side2
        },
      },
      {
        production_type = "input",
        pipe_covers = invisible_pipecoverpictures(),
        base_area = 10,
        base_level = 1,
        pipe_connections = {
          { type="input", position = {0.5, 2.4} }, -- front
          { type="input", position = {2.4, 0.5} }, -- side1
          { type="input", position = {-2.4, 0.5} }, -- side2
        },
      },
      {
        production_type = "input",
        pipe_covers = invisible_pipecoverpictures(),
        base_area = 10,
        base_level = 1,
        pipe_connections = {
          { type="input", position = {-0.5, 2.4} }, -- front
          { type="input", position = {2.4, -0.5} }, -- side1
          { type="input", position = {-2.4, -0.5} }, -- side2
        },
      },
      {
        production_type = "input",
        pipe_covers = invisible_pipecoverpictures(),
        base_area = 10,
        base_level = 1,
        pipe_connections = {
          { type="input", position = {-1.5, 2.4} }, -- front
          { type="input", position = {2.4, -1.5} }, -- side1
          { type="input", position = {-2.4, -1.5} }, -- side2
        },
      },
      {
        production_type = "output",
        pipe_covers = invisible_pipecoverpictures(),
        pipe_connections = {
          { type="output", position = {1.5, -2.4} }, --output
        },
      },
      {
        production_type = "output",
        pipe_covers = invisible_pipecoverpictures(),
        pipe_connections = {
          { type="output", position = {0.5, -2.4} }, --output
        },
      },
      {
        production_type = "output",
        pipe_covers = invisible_pipecoverpictures(),
        pipe_connections = {
          { type="output", position = {-0.5, -2.4} }, --output
        },
      },
      {
        production_type = "output",
        pipe_covers = invisible_pipecoverpictures(),
        pipe_connections = {
          { type="output", position = {-1.5, -2.4} }, --output
        },
      },
      --secondary_draw_orders = { north = -1 }
      off_when_no_fluid_recipe = false
    },
    crafting_speed = 1,
    energy_source =
    {
      type = "electric",
      usage_priority = "secondary-input",
      emissions = 0.0
    },
    energy_usage = "5kW",
    crafting_categories = {"crafting"},
    ingredient_count = 1,
  },

  {
    type = "container",
    name = "superbus-hidden-container",
    picture = {  -- invisible
      filename = "__SuperBus__/graphics/void.png",
      width = 1,
      height = 1,
    },
    minable = {hardness = 0, minable = false, mining_time = 0},
    destructable = false,
    inventory_size = 16,
  },
})