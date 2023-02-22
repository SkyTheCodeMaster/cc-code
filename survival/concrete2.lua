local INPUT = peripheral.wrap("sc-goodies:diamond_chest_6969")
local OUTPUT = peripheral.wrap("sc-goodies:diamond_chest_696969")
local modem = peripheral.find("modem")
local selfName = modem.getNameLocal()

local function getConcrete()
  local found = false
  for slot,item in pairs(INPUT.list()) do
    if item.name:match("minecraft:[%a_]+_concrete_powder") then
      INPUT.pushItems(selfName,slot,1,1)
      found = true
      break
    end
  end
  return found
end

local function processConcrete()
  turtle.select(1)
  turtle.place()
  turtle.dig()
end

local function returnConcrete()
  OUTPUT.pullItems(selfName,1)
end

local processed = 0

local function main()
  while true do
    if getConcrete() then
      processConcrete()
      processed = processed + 1
      returnConcrete()
    else
      sleep()
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
    centerWrite("Skynet Concrete Producer",1,win)

    win.setCursorPos(1,2)
    win.write(("-"):rep(width))

    win.setCursorPos(1,3)
    win.write(("Concrete Produced: %d"):format(processed))

    win.setVisible(true)
    sleep(2)
  end
end

parallel.waitForAny(main,displayManager)