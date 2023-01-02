-- Automatically harvest beans in a farm like this, then drop them below.
-- https://i.skystuff.games/IaSTOJnbZoxc.png

local height = 4

-- no touchie
local expect = require"cc.expect".expect

local function canHarvest()
  local _,data = turtle.inspect()
  return data and data.name == "minecraft:cocoa" and data.state.age == 2
end

local function harvestLayer()
  for i=1,4 do
    if canHarvest() then
      turtle.dig()
      turtle.place()
    end
    turtle.turnLeft()
  end
end

local function harvestFarm()
  for i=1,height-1 do
    harvestLayer()
    turtle.up()
  end
  harvestLayer()
  for i=1,height-1 do
    turtle.down()
  end
  for i=1,16 do
    local data = turtle.getItemDetail(i)
    if data and data.name == "minecraft:cocoa_beans" then
      turtle.select(i)
      turtle.dropDown(64)
    end
  end
  turtle.select(1)
end

local function harvestManager()
  while true do
    if canHarvest() then
      harvestFarm()
    else
      sleep(1)
    end
  end
end

local function centerWrite(txt,y,t)
  expect(1,txt,"string")
  expect(2,y,"number","nil")
  expect(3,term,"table","nil")

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
  local width,height = win.getSize()
  while true do
    win.setVisible(false)
    local fuel,max = turtle.getFuelLevel(),turtle.getFuelLimit()
    local percent = fuel/max*100
    local harvestsLeft = math.floor(fuel/(height-1)*2)

    if harvestsLeft > 20 then
      win.setBackgroundColour(colours.blue)
    else
      win.setBackgroundColour(colours.red)
    end
    win.setTextColour(colours.white)
    win.clear()

    win.setCursorPos(1,1)
    centerWrite("Skynet Bean Farmer",1,win)

    win.setCursorPos(1,2)
    win.write(("-"):rep(width))

    win.setCursorPos(1,3)
    win.write(("Fuel: %d/%d (%.2f%%)"):format(fuel,max,percent))

    win.setCursorPos(1,4)
    win.write(("Harvests left: %d"):format(harvestsLeft))

    win.setVisible(true)
    sleep(2)
  end
end

parallel.waitForAny(harvestManager,displayManager)