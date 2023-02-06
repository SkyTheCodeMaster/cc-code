-- Takes a recipe, and items from a chest, crafts them, and repeats.

local INPUT_CHESTS = {peripheral.wrap("sc-goodies:diamond_chest_1660")} -- Can search through multiple chests.
local OUTPUT_CHEST = peripheral.wrap("sc-goodies:diamond_chest_1661") -- For intermediary step crafters, they output to a middle chest.

local S = "minecraft:stick"
local H = "minecraft:string"
local E = "" -- A blank string is an empty slot.
local recipe = { -- Craft a bow.
  {E,S,H},
  {S,E,H},
  {E,S,H},
}
local result = "minecraft:bow" -- This is used for the capacity
local capacity = 16 -- We try to keep this many items in the output

-- No touchie

local selfname = peripheral.find("modem").getNameLocal()

-- Calculate cost of recipe in total
local cost = {} -- name: item requirement
for _,row in pairs(recipe) do
  for _,item in pairs(row) do
    if item ~= E then
      if cost[item] then
        cost[item] = cost[item] + 1
      else
        cost[item] = 1
      end
    end
  end
end

-- {
--   ["minecraft:stick"] = {
--     count=63,
--     get = function(count) -> grabs X items from any available chests
--     }
--   }
-- }

local function buildMaterialsList()
  -- Take all of our input chests and build a giant list of items, where they are, and what slots.
  local list = {}
  local funcs = {}
  for _,chest in pairs(INPUT_CHESTS) do
    -- We want to make our count variable, so the turtle will know whether to craft or not.
    local function func()
      for _,data in pairs(chest.list()) do
        if data and cost[data.name] then
          if not list[data.name] then
            list[data.name] = {count=data.count}
          else
            list[data.name].count = list[data.name].count + data.count
          end
        end
      end
    end
    funcs[#funcs+1] = func
  end
  -- Execute
  parallel.waitForAll(table.unpack(funcs))
  -- Now add get functions
  for name,data in pairs(list) do
    function data.get(count,target)
      local finished = false
      for _,chest in pairs(INPUT_CHESTS) do
        if finished then break end
        for slot,data in pairs(chest.list()) do
          if finished then break end
          if data.name == name then
            if data.count > count then
              chest.pushItems(selfname,slot,count,target)
              finished = true
            else
              chest.pushItems(selfname,slot,data.count,target)
              count = count - data.count
            end
          end
        end
      end
    end
  end
  return list
end

local function collectRequiredMaterials(sources)
  local lut = {1,2,3,5,6,7,9,10,11}
  -- Go through our sources and pull only the required materials.
  local funcs = {}
  for i,row in pairs(recipe) do
    for o,item in pairs(row) do
      if item ~= E then
        local slot = lut[(3*i-3)+o]
        local function func()
          sources[item].get(1,slot)
        end
        funcs[#funcs+1] = func
      end
    end
  end
  parallel.waitForAll(table.unpack(funcs))
end

local function craft()
  local sources = buildMaterialsList()
  for name,count in pairs(cost) do
    if not sources[name] or sources[name].count < count then
      sleep(1) -- Wait a bit
      return false
    end
  end
  collectRequiredMaterials(sources)
  turtle.select(1)
  turtle.craft()
  -- Now ship it out to the output chest
  OUTPUT_CHEST.pullItems(selfname,1)
  -- Now clear out the turtle back into the last input chest
  local endpoint = INPUT_CHESTS[#INPUT_CHESTS]
  local funcs = {}
  for i=1,16 do
    if turtle.getItemDetail(i) then
      funcs[#funcs+1] = function()
        endpoint.pullItems(selfname,i)
      end
    end
  end
  parallel.waitForAll(table.unpack(funcs))
  return true
end

local stock = 0
local produced = 0

local function craftManager()
  while true do
    -- Get the count of our output item in the output chest
    local count = 0
    for _,item in pairs(OUTPUT_CHEST.list()) do
      if item.name == result then
        count = count + item.count
      end
    end
    stock = count -- This will prevent the display from displaying 0 in race
    if stock < capacity then
      if craft() then
        produced = produced + 1
      end
    end
  end
end

local function centerWrite(txt,y,t)
  t = t or term
  local ox,oy = t.getCursorPos()
  y = y or oy
  local width = t.getSize()
  t.setCursorPos(math.ceil((width/2)-(txt:len()/2)),y)
  t.write(txt)
  t.setCursorPos(ox,oy)
end

local function displayManager()
  local win = window.create(term.current(),1,1,term.getSize())
  local width = win.getSize()
  while true do
    win.setVisible(false)

    win.setBackgroundColour(colours.blue)
    win.setTextColour(colours.white)
    win.clear()

    win.setCursorPos(1,1)
    centerWrite("Skynet Crafting Core",1,win)

    win.setCursorPos(1,2)
    win.write(("-"):rep(width))

    win.setCursorPos(1,3)
    win.write("Crafting: "..result)

    win.setCursorPos(1,5)
    win.write("Target Quantity: "..capacity)

    win.setCursorPos(1,6)
    win.write("Stock: "..stock)

    win.setCursorPos(1,7)
    win.write(("Items produced: %d"):format(produced))

    win.setVisible(true)
    sleep(2)
  end
end

parallel.waitForAll(craftManager,displayManager)