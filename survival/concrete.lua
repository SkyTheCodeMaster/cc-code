-- Pulls powder from top chest, places in front, mines, pushes to bottom chest.

local chest = peripheral.wrap("top")
local processed = 0
local expect = require"cc.expect".expect

local function isEmpty()
  for _,slot in pairs(chest.list()) do
    if slot then return false end
  end
  return true
end

local function dropComplete()
  for i=1,16 do
    local data = turtle.getItemDetail(i)
    if data and data.name:match("minecraft:%a+_concrete$") then
      turtle.select(i)
      turtle.dropDown(64)
    end
  end
  turtle.select(1)
end

local function suck()
  if isEmpty() then return end
  turtle.select(2)
  while turtle.suckUp(64) do end
  dropComplete()
  turtle.select(1)
  turtle.dropUp(64) -- Make sure we have space to pick up the completed concrete.
end

local function process()
  for i=1,16 do
    local data = turtle.getItemDetail(i)
    if data and data.name:match("minecraft:%a+_concrete_powder") then
      turtle.select(i)
      while turtle.getItemCount(i) ~= 0 do
        local data = turtle.getItemDetail(i)
        if data and data.name:match("minecraft:%a+_concrete$") then
          break
        end
        turtle.place()
        turtle.dig()
        turtle.suck()
        processed = processed + 1
      end
    end
  end
end

local function concreteManager()
  while true do
    suck()
    process()
    dropComplete()
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
  local width = win.getSize()
  while true do
    win.setVisible(false)

    win.setBackgroundColour(colours.red)
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

parallel.waitForAny(concreteManager,displayManager)