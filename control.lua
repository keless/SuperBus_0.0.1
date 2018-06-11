-- Code heavily modified but started from Slipstream_2.0.0 by Degraine / James Brooker (MIT License 2014)
require "util"

function math_round(x)
  return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

function tableToString(t) 
  local str = "{ "
  for i,v in pairs(t) do
    str = str .. tostring(i) .. ":" .. tostring(v) .. ","
  end
  str  = str .. " }"
  return str
end

script.on_event(defines.events.on_player_created, function(e)
  local player = game.players[e.player_index]
  --xxx HACK: for testing purposes only
  player.insert({name="superbus-1", count=10})
  player.insert({name="transport-belt", count=100})
  player.insert({name="iron-gear-wheel", count=100})
  player.insert({name="iron-plate", count=200})
  player.insert({name="coal", count=50})
  player.insert({name="assembling-machine-2", count=5})
  player.insert({name="oil-refinery", count=5})
  player.insert({name="offshore-pump", count=5})
  player.insert({name="small-electric-pole", count=5})
end)


local next = next
local north = defines.direction.north
local east = defines.direction.east
local south = defines.direction.south
local west = defines.direction.west
local transport_line = defines.transport_line


script.on_init(function()
	onLoad()
end)

script.on_load(function()
	onLoad()
end)

function onLoad()
	if not global.all_superbusses then
    global.all_superbusses = {}
    -- not sure why we'd want to reset all tech/rec every time the user loads a game!?
		--game.forces.player.reset_technologies()
		--game.forces.player.reset_recipes()
	end
end



-- we want to keep track of all superbusses, so we listen for all
-- build and destroy tracking events and keep our own list up to date

-- pattern for matching superbus entity names (eg: superbus-1, superbus-2)
local superbusNamePattern = "^superbus%-%d+$"

-- buses placed by player or robots
script.on_event(defines.events.on_built_entity, function(event)
	if string.find(event.created_entity.name, superbusNamePattern) then
		superbusBuilt(event.created_entity)
	end
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
	if string.find(event.created_entity.name, superbusNamePattern) then
		superbusBuilt(event.created_entity)
	end
end)

-- buses removed by player, robots, or violence
script.on_event(defines.events.on_player_mined_item, function(event)
	if string.find(event.item_stack.name, superbusNamePattern) then
		superbusRemoved()
	end
end)

script.on_event(defines.events.on_robot_mined, function(event)
	if string.find(event.item_stack.name, superbusNamePattern) then
		superbusRemoved()
	end
end)

script.on_event(defines.events.on_entity_died, function(event)
	if string.find(event.entity.name, superbusNamePattern) then
		superbusRemoved()
	end
end)

-- insert/remove utilities
function superbusBuilt(entity) -- Construct the data table for each chest as it's built.
  local busId = string.format("%d_%d", entity.position.x, entity.position.y)
  local surface = entity.surface

  entity.operable = false --dont let user click on this (would have opened recipe window)

  local bounds = entity.selection_box --selection box is more accurate to what we want than bounding_box
  local size = bounds.right_bottom.x - bounds.left_top.x
  log("create superbus of size " .. tostring(size) .. " at " .. tostring(entity.position.x) .. "," .. tostring(entity.position.y))
  local wo = 0
  if (size > 1) then
    wo = ((size-1)/2)
  end

  -- create hidden entities
  local containers = {}
  local xoff = 0
  local xStart = entity.position.x - wo
  for i = 1,size,1 do
    local pos = { x = xStart + xoff, y = entity.position.y }
    containers[i] = surface.create_entity{name="superbus-hidden-container", position = pos, force = entity.force}
    xoff = xoff + 1
  end 
  --container.destructible = false --test: doing this in prototype, make sure its okay
  local superBusObject = { entity = entity, size = size, startIdx = 0, containers = containers, inventory = function(self, idx)
    --log("get inv " .. tostring(idx) .. " of " .. #(self.containers))
    return self.containers[idx].get_inventory(defines.inventory.chest)
  end}

  global.all_superbusses[busId] = superBusObject
end

function superbusRemoved()
  -- find which bus was removed :/
  for busId,superBusObject in pairs(global.all_superbusses) do
		if not superBusObject.entity.valid then
        --clean up hidden entities
        for i,v in ipairs(superBusObject.containers) do
          v.destroy()
        end

        global.all_superbusses[busId] = nil
		end
	end
end

-- returns dictionary of { str:input/output , belt line } pairs
function getSuperbusTransferInstructions(superBus) -- Find the input and output belts for a superBus.
  local busDirection = superBus.entity.direction
  local pos = {x = superBus.entity.position.x, y = superBus.entity.position.y} --center of bus entity (in tiles)
  local eps = 0.1 --epsilon: small change of distance
  local size = superBus.size
  local wo = 0
  local ro = 1
  if (size > 1) then -- avoid divide by zero
    wo = ((size-1)/2)      --width offset (dist from center of entity to center of adjacent outer tile)
    ro = ((size-1)/2) + 1  --radial offset (distance from center of entity to center of adjacent outer tile tangent)
  end

  -- origin top-left
  local beltscan_coords = { -- rectangles to search for transport belts.
    [north] = {{pos.x - (wo + eps), pos.y - (ro - eps)},{pos.x + (wo + eps), pos.y - (ro + eps)}},
    [east] = {{pos.x + (ro - eps), pos.y - (wo + eps)},{pos.x + (ro + eps), pos.y + (wo + eps)}},
    [south] = {{pos.x - (wo + eps), pos.y + (ro - eps)},{pos.x + (wo + eps), pos.y + (ro + eps)}},
    [west] = {{pos.x - (ro - eps), pos.y - (wo + eps)},{pos.x - (ro + eps), pos.y + (wo + eps)}}
  }
  
  local directions = {north, east, south, west} -- For the for loop.
  local away_directions = {[north] = north, [east] = east, [south] = south, [west] = west}
  local facing_directions = {[north] = south, [east] = west, [south] = north, [west] = east}
  --  local side_clockwise_directions = {[north] = east, [east] = south, [south] = west, [west] = north}
  --  local side_anticlockwise_directions = {[north] = west, [east] = north, [south] = east, [west] = south}
  local instructions = {} -- dictionary of { str:input/output , belt line } pairs


  for i,v in ipairs(directions) do
    local isOutputSide = (away_directions[v] == busDirection)

    -- Search for transport belts
    -- todo: test if we can add underground belt support here for free? (if the API is the same)
    local belts = superBus.entity.surface.find_entities_filtered({area = beltscan_coords[v], type = "transport-belt"}) 
    for bidx,belt in ipairs(belts) do
      if belt ~= nil then -- If belt is found.
        --determine "laneIndex" of belt found
        local busIdx = 1
        local beltXOffset = belt.position.x - (superBus.entity.position.x - wo)
        local beltYOffset = belt.position.y - (superBus.entity.position.y - wo)
        if v == north then
          busIdx = 1 + math_round(beltXOffset)
        elseif v == east then
          busIdx = 1 + math_round(beltYOffset)
        elseif v == south then
          busIdx = superBus.size - math_round(beltXOffset)
        else
          busIdx = superBus.size - math_round(beltYOffset)
        end

        if belt.direction == away_directions[v] then
          --flip output belt bus idx (ex: top left input from west side should be top right output on east side)
          busIdx = superBus.size - (busIdx - 1)
          table.insert(instructions,{"output", busIdx, belt.get_transport_line(transport_line.left_line)})
          table.insert(instructions,{"output", busIdx, belt.get_transport_line(transport_line.right_line)})
  -- Unlike Slipstream, I dont want belts that are curved to interact with SuperBus at all
  --      elseif belt.direction == side_clockwise_directions[v] then -- Just one lane.
  --        table.insert(instructions,{"output", belt.get_transport_line(transport_line.right_line)})
  --      elseif belt.direction == side_anticlockwise_directions[v] then -- Or the other lane.
  --        table.insert(instructions,{"output", belt.get_transport_line(transport_line.left_line)})
        elseif belt.direction == facing_directions[v] then
          table.insert(instructions,1,{"input", busIdx, belt.get_transport_line(transport_line.right_line)})
          table.insert(instructions,1,{"input", busIdx, belt.get_transport_line(transport_line.left_line)})
        end
      end
    end --for each belt found adjacent to superbus

    -- search fluid boxes
    for fluidIdx,fluid in ipairs(superBus.entity.fluidbox) do
      local connections = fluid.connections
      if #connections > 1 then --need two pipes connected to transfer anything
        table.insert(instructions,1,{"fluid", fluidIdx})
      end
    end

    --search for other superbusses to transfer INTO
    if isOutputSide then
      -- only transfer to other busses of EXACT SAME TYPE (todo: support multi-type as long as size is same?)
      local superBusType = superBus.entity.type 
      local buses = superBus.entity.surface.find_entities_filtered({area = beltscan_coords[v], type = superBusType})
      local validBusses = {}
      for bidx,outbusEntity in ipairs(buses) do
        local outbusId = string.format("%d_%d", outbusEntity.position.x, outbusEntity.position.y)
        --log("found adjacent sb at " .. outbusId)
        local outbusObject = global.all_superbusses[outbusId]
        if outbusObject ~= nil then
          --log("attempt transfer between busses")
          validBusses[#validBusses+1] = outbusObject
        end
      end
      --group all busses into one transfer command
      if superBus.startIdx > #validBusses then
        superBus.startIdx = 0
      end
      table.insert(instructions, {"transfer", validBusses})
    end --if isOutputSide
  end --for each direction

  return instructions
end


function transferStack( invOut, invIn, stack )
  if stack.count == 0 then return false end

  if invIn.can_insert(stack) then
    invIn.insert(stack)
    invOut.remove(stack)
    return true
  end
  return false
end

function transferInventory( invOut, invIn )
  if invOut.is_empty() then return end
  local outContents = invOut.get_contents()
  for itemName,itemCount in pairs(outContents) do
    local easyStack = {name=itemName, count=itemCount}
    transferStack(invOut, invIn, easyStack)
  end
end

-- return nil or array of stacks
--  divides by numSplits, but ensures integers, and remainders are handled
--  if division is uneven, last stacks are always shortest (by 0 or 1)
--     eg:  split 5,  count 7, result:  {2, 2, 1, 1, 1}
-- note: ignores health/durability/ammo -- so technically this could result in a free repairing bug?
function splitInventoryIntoStacks(inventory, numSplits)
  if inv_contents == nil then return nil end
  if type(inv_contents) ~= "table" then return nil end
  if numSplits <= 1 then return nil end

  local stacks = {}
  log("attempt to split " .. tableToString(inv_contents))

  for itemName,itemCount in pairs(inv_contents) do
    local chunkSize = math.max(math.floor(itemCount / numSplits), 1)
    for i=1,numSplits,1 do
      if itemCount > 0 then
        local chip = math.min(itemCount, chunkSize)
        log(" split"..tostring(i).." - "..itemName.." : "..tostring(chip))
        stacks[i] = {name = itemName, count = chip}
        itemCount = itemCount - chip
      end 
    end
  end

  return stacks
end

function equalizeFluids(fluidBox, fluidIdx) 
  local connections = fluidBox.get_connections(fluidIdx)

  -- its possible for connections to not all have the same type of fluid
  for i,v in ipairs(connections) do
    
  end
end

-- returns true if any items were transferred
function runSuperbusTransferInstructions(superBus, instructions)
	local action_count = 0

  for i,v in pairs(instructions) do
--xxx TODO: implement electricity requirement
--		if superBus.battery.energy < energy_per_action then
--			break
--		elseif v[2].valid == false then
--			return true, false
--		end
    local instruction = v[1]
		
    if instruction == "output" then
      --xxx TODO: figure out how to filter what it is we're sending out
      local busIdx = v[2]
      local outbelt = v[3]
      local busInventory = superBus:inventory(busIdx)

			if not busInventory.is_empty() and outbelt.can_insert_at_back() then
        local inv_contents = next(busInventory.get_contents())
			  local stack = {name = inv_contents, count = 1}
				outbelt.insert_at_back(stack)
        busInventory.remove(stack)
--xxx TODO: chest.battery.energy = chest.battery.energy - energy_per_action
				action_count = action_count + 1
			end
    elseif instruction == "input" then
      local busIdx = v[2]
      local inbelt = v[3]
			local line_contents = next(inbelt.get_contents())
      local busInventory = superBus:inventory(busIdx)
			
			if line_contents ~= nil then
				local stack = {name = line_contents, count = 1}
				
				if busInventory.can_insert(stack) then
					busInventory.insert(stack)
          inbelt.remove_item(stack)
--xxx TODO: chest.battery.energy = chest.battery.energy - energy_per_action
					action_count = action_count + 1
				end
      end
    elseif instruction == "fluid" then
      local fluidIdx = v[2]
      equalizeFluids(superBus.entity.fluidbox)
    elseif instruction == "transfer" then
      local outbusObjectArray = v[2]
      local transferCount = #outbusObjectArray
      if transferCount > 0 then
        --log("transfer from bus to bus")
        for busIdx=1,superBus.size,1 do
          --log("transfer bus idx " .. tostring(busIdx))
          local busInventory = superBus:inventory(busIdx)
          if not busInventory.is_empty() then
            --split contents between all outbusses
            local inv_contents = busInventory.get_contents()

            if transferCount == 1 then
              local outbusObject = outbusObjectArray[1]
              local outBusInventory = outbusObject:inventory( busIdx )
              transferInventory(busInventory, outBusInventory)
            else
              local splitStacks = splitInventoryIntoStacks(inv_contents, transferCount)

              --for i,outbusObject in ipairs(outbusObjectArray) do
              for i=1,#outbusObjectArray,1 do
                local offsetIdx = 1 + (i + superBus.startIdx) % transferCount
                local outbusObject = outbusObjectArray[offsetIdx]
                local outBusInventory = outbusObject:inventory( busIdx )
                --log(" ssi " .. tostring(splitStacks[i]) .. " count " .. tostring(#splitStacks) )
                if transferStack(busInventory, outBusInventory, splitStacks[i]) then
                  action_count = action_count + 1
                end
              end
            end -- if-else: bus transfer 1:1 or 1:many
          end
        end -- for each inventory lane
        superBus.startIdx = superBus.startIdx + 1 --offset into outbusObjectArray alternating left/right
      end -- if bus-to-bus transfer
		end -- if-else: instruction type
	end
  
  return (action_count == 0)
end


script.on_event(defines.events.on_tick, function(e)
    -- for each superbus
    for index,superBus in pairs(global.all_superbusses) do
      local instructions = getSuperbusTransferInstructions(superBus)
      runSuperbusTransferInstructions(superBus, instructions)
    end
  end)