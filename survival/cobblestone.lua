-- Detects cobblestone beneath it, mines it, and drops it up if there is room.
local chest = peripheral.wrap("top")
local dug = 0
local size = chest.size()

-- Determine if digging is an option.
local function dig()
  local maxItems = size*64
  local count = 0
  for k,v in pairs(chest.list()) do
    count = count + v.count
  end
  if count < maxItems then
    turtle.digDown()
    turtle.dropUp()
  end
  local newCount = 0
  for k,v in pairs(chest.list()) do
    newCount = newCount + v.count
  end
  if newCount > count then dug = dug + 1 end
end

-- Setup fancy smancy screen.
term.setBackgroundColour(colours.blue)
term.setTextColour(colours.white)
term.clear()
term.setCursorPos(1,1)

term.write("Sky's Cobblestone Miner v1.0")
term.setCursorPos(1,2)
term.write("---------------------------------------")
term.setCursorPos(1,3)
term.write("Total cobblestone dug: (This session)")
term.setCursorPos(1,4)
term.write(tostring(dug))

while true do
  dig()
  term.clearLine(4)
  term.setCursorPos(1,4)
  term.write(tostring(dug))
  sleep()
end