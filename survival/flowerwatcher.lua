local COMPOST = peripheral.wrap("sc-goodies:diamond_chest_1579")
local ALLIUMS = peripheral.wrap("sc-goodies:diamond_chest_1573")
local DANDELS = peripheral.wrap("sc-goodies:diamond_chest_1574")
local CORNFLR = peripheral.wrap("sc-goodies:diamond_chest_1575")
local OXDAISY = peripheral.wrap("sc-goodies:diamond_chest_1576")
local POPPIES = peripheral.wrap("sc-goodies:diamond_chest_1577")

local mon = peripheral.wrap("monitor_479")

local function centerWrite(txt,y,t)
  t = t or term
  local ox,oy = t.getCursorPos()
  y = y or oy
  local width = t.getSize()
  t.setCursorPos(math.ceil((width/2)-(txt:len()/2)),y)
  t.write(txt)
  t.setCursorPos(ox,oy)
end

mon.setBackgroundColour(colours.blue)
mon.setTextColour(colours.white)
mon.clear()
centerWrite("Skynet Flower Watcher",1,mon)
mon.setCursorPos(1,2)
local w = mon.getSize()
mon.write(string.rep("-",w))

local chests = {
  ALLIUMS=ALLIUMS,
  DANDELS=DANDELS,
  CORNFLR=CORNFLR,
  OXDAISY=OXDAISY,
  POPPIES=POPPIES
}

local function percent(chest)
  local list = chest.list()
  local size = chest.size()
  local itemCount = 0
  local maxItems = 64*size
  for i=1,size do
    if list[i] then
      itemCount = itemCount + list[i].count
    end
  end
  return math.floor((itemCount/maxItems)*100)
end

local function wait(chest,fullness)
  -- Wait until a chest drops below `fullness` percent full
  repeat sleep(1)
  until percent(chest) <= fullness
end

while true do
  -- First, print out the % full of each chest
  local i = 5
  for name,chest in pairs(chests) do
    mon.clearLine(i)
    mon.setCursorPos(1,i)
    local full = percent(chest)
    mon.write(name .. ": " .. full .. "%")
    i = i + 1
  end
  mon.clearLine(i)
  mon.setCursorPos(1,i)
  local full = percent(COMPOST)
  mon.write("COMPOST: " .. full .. "%")
  -- first check the composter chest
  if percent(COMPOST) > 95 then
    mon.clearLine(3)
    mon.setCursorPos(1,3)
    mon.write("PAUSED - Compost chest full.")

    -- Now we wait for the chest to go down to like 75% full
    rs.setOutput("right",true)

    wait(COMPOST,75)

    rs.setOutput("right",false)

    mon.clearLine(3)
    mon.setCursorPos(1,3)
    mon.write("RUNNING")
  end
  for name,chest in pairs(chests) do
    if percent(chest) >= 99 then
      mon.clearLine(3)
      mon.setCursorPos(1,3)
      mon.write("PAUSED - " .. name .. " chest full.")

      rs.setOutput("right",true)

      wait(chest,95)

      rs.setOutput("right",false)

      mon.clearLine(3)
      mon.setCursorPos(1,3)
      mon.write("RUNNING")
    end
  end
  sleep(1)
end