-- uses a farm to funnel blazes ontop of the turtles
-- then they kill the blazes and hoppers suck out blaze rods.

term.setBackgroundColour(colours.blue)
term.setTextColour(colours.white)
term.clear()

local chest = peripheral.find("sc-goodies:diamond_chest")
local selfName = peripheral.wrap("bottom").getNameLocal()

local function centerWrite(txt,y,t)
  t = t or term
  local ox,oy = t.getCursorPos()
  y = y or oy
  local width = t.getSize()
  t.setCursorPos(math.ceil((width/2)-(txt:len()/2)),y)
  t.write(txt)
  t.setCursorPos(ox,oy)
end

centerWrite("Skynet Blaze Farm",1,term)
term.setCursorPos(1,2)
local w = term.getSize()
term.write(string.rep("-",w))

while true do
  turtle.attackUp()
  turtle.suckUp(64)
  for i=1,16 do
    if turtle.getItemDetail(i) then
      chest.pullItems(selfName,i)
    end
  end
  sleep()
end