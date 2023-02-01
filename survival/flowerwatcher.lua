local COMPOST = peripheral.wrap("sc-goodies:diamond_chest_1579")
local ALLIUMS = peripheral.wrap("sc-goodies:diamond_chest_1573")
local DANDELS = peripheral.wrap("sc-goodies:diamond_chest_1574")
local CORNFLR = peripheral.wrap("sc-goodies:diamond_chest_1575")
local OXDAISY = peripheral.wrap("sc-goodies:diamond_chest_1576")
local POPPIES = peripheral.wrap("sc-goodies:diamond_chest_1577")

local mon = peripheral.wrap("monitor_479")
mon.setTextScale(0.5)

local function centerWrite(txt,y,t)
  t = t or term
  local ox,oy = t.getCursorPos()
  y = y or oy
  local width = t.getSize()
  t.setCursorPos(math.ceil((width/2)-(txt:len()/2)),y)
  t.write(txt)
  t.setCursorPos(ox,oy)
end

local win = window.create(mon,1,1,mon.getSize())

win.setBackgroundColour(colours.blue)
win.setTextColour(colours.white)
win.clear()
centerWrite("Skynet Flower Watcher",1,win)
win.setCursorPos(1,2)
local w = win.getSize()
win.write(string.rep("-",w))

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
  repeat 
    win.setVisible(false)
    win.setBackgroundColour(colours.blue)
    win.setTextColour(colours.white)
    win.clear()
    centerWrite("Skynet Flower Watcher",1,win)
    win.setCursorPos(1,2)
    local w = win.getSize()
    win.write(string.rep("-",w))
  
    -- First, print out the % full of each chest
    local i = 5
    for name,chest in pairs(chests) do
      win.setCursorPos(1,i)
      win.clearLine()
      local full = percent(chest)
      win.write(name .. ": " .. full .. "%")
      i = i + 1
    end
    win.setCursorPos(1,i)
    win.clearLine()
    local full = percent(COMPOST)
    win.write("COMPOST: " .. full .. "%")
    win.setVisible(true)
    sleep(1)
  until percent(chest) <= fullness
end

while true do
  win.setVisible(false)
  win.setBackgroundColour(colours.blue)
  win.setTextColour(colours.white)
  win.clear()
  centerWrite("Skynet Flower Watcher",1,win)
  win.setCursorPos(1,2)
  local w = win.getSize()
  win.write(string.rep("-",w))
  win.setCursorPos(1,3)
  win.write("RUNNING")

  -- First, print out the % full of each chest
  local i = 5
  for name,chest in pairs(chests) do
    win.setCursorPos(1,i)
    win.clearLine()
    local full = percent(chest)
    win.write(name .. ": " .. full .. "%")
    i = i + 1
  end
  win.setCursorPos(1,i)
  win.clearLine()
  local full = percent(COMPOST)
  win.write("COMPOST: " .. full .. "%")
  win.setVisible(true)
  -- first check the composter chest
  if percent(COMPOST) > 95 then
    win.setCursorPos(1,3)
    win.clearLine()
    win.write("PAUSED - Compost chest full.")

    -- Now we wait for the chest to go down to like 75% full
    rs.setOutput("right",true)

    wait(COMPOST,75)

    rs.setOutput("right",false)

    win.setCursorPos(1,3)
    win.clearLine()
    win.write("RUNNING")
  end
  for name,chest in pairs(chests) do
    if percent(chest) >= 99 then
      win.setCursorPos(1,3)
      win.clearLine()
      win.write("PAUSED - " .. name .. " chest full.")

      rs.setOutput("right",true)

      wait(chest,95)

      rs.setOutput("right",false)

      win.setCursorPos(1,3)
      win.clearLine()
      win.write("RUNNING")
    end
  end
  sleep(1)
end