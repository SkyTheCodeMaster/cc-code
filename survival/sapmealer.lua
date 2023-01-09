-- Places and bonemeals saplings.
local kinetic = peripheral.find("plethora:kinetic")
if not kinetic then error("Kinetic augment required!") end

local saplings = 0
local bonemeals = 0

local function plant()
  while true do
    if turtle.getItemCount(1) == 0 then
      turtle.turnLeft()
      turtle.suck(64)
      turtle.turnRight()
    end
    if turtle.getItemCount(2) == 0 then
      turtle.suckDown(64)
    end
    if not turtle.detect() then
      turtle.select(1)
      turtle.place()
      turtle.select(2)
      saplings = saplings + 1
    end
    if kinetic.use() then
      bonemeals = bonemeals + 1
    end
    os.queueEvent("yield")
    os.pullEvent()
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
    centerWrite("Skynet Tree Grower",1,win)

    win.setCursorPos(1,2)
    win.write(("-"):rep(width))

    win.setCursorPos(1,3)
    win.write(("Saplings planted: %d"):format(saplings))

    win.setCursorPos(1,4)
    win.write(("Bonemeal used: %d"):format(bonemeals))

    win.setVisible(true)
    sleep(2)
  end
end

parallel.waitForAny(plant,displayManager)