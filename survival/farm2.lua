-- This is like the normal farm.lua, however this does not require skyrtle (defines farm function locally), and supports far more user functions.
-- USER DEFINED PARAMETERS
local length = 11 -- How long your farm is
local width = 25 -- How wide your farm is
local cropName = "immersiveengineering:hemp"

-- This determines if the turtle will begin harvesting the field, and is ran in a while loop. This function does not need to yield.
local function loop()
  return turtle.detect() -- this function harvests 2 tall plants, such as immersive engineering hemp
end

-- This determines how the turtle harvests the crops.
local function harvest()
  turtle.dig()
  turtle.suckDown()
  turtle.suck()
end

-- This determines what the turtle does before it starts the farm. By this point the turtle has already decided it will harvest the farm.
local function before()
end

-- This determines what the turtle does after it finishes the farm.
local function after()
  turtle.back()
  for i=1,16 do
    turtle.select(i)
    turtle.dropDown()
  end
  turtle.select(1)
  turtle.forward()
end

-- no touchie from here >:(
local expect = require("cc.expect").expect

--- Split a string by it's separator.
-- @tparam string inputstr String to split.
-- @tparam string sep Separator to split the string by.
-- @treturn table Table containing the split string.
local function split(inputstr, sep)
  expect(1,inputstr,"string")
  expect(1,sep,"string","nil")
  sep = sep or ","
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

--- Cut or pad a string to length.
-- @tparam string str String to cut or pad.
-- @tparam number len Length to cut or pad to.
-- @tparam[opt] string pad Padding to extend the string if necessary. Defaults to " ".
-- @treturn string Cut or padded string.
local function cut(str,len,pad)
  pad = pad or " "
  return str:sub(1,len) .. pad:rep(len - #str)
end

term.setBackgroundColour(colours.blue)
term.setTextColour(colours.white)
term.clear()
local function drawScreen()
  term.setCursorPos(1,1)
  term.write("SkyNet Farming Program v2.0")
  term.setCursorPos(1,2)
  term.write("---------------------------------------")
  term.setCursorPos(1,3)
  term.write("Harvesting: "..cut(split(cropName,":")[2]:gsub("^$l",string.upper),27))
  term.setCursorPos(1,4)
  term.write("---------------------------------------")
  term.setCursorPos(1,5)
  term.write("Fuel: "..turtle.getFuelLevel())
  term.setCursorPos(1,6)
  term.write("Needed: "..length*width+length+width+100)
end
drawScreen()

--- A standard farm function, runs the check function and if it passes it will dig down, and place down the seed.
-- @tparam number length How far the turtle should go.
-- @tparam number width How many blocks to the right the turtle should go.
-- @tparam function check Whether or not the turtle should dig, and if it does, what item it should place down as a seed. The default check checks for a wheat growth state of 7. The returns should be a boolean, and a string for the item name. The default check function is @{skyrtle.farm.check}
local function farm(length,width)
  expect(1,length,"number")
  expect(1,width,"number")

  for y=1,width do
    for x=1,length do
      if x ~= length then
        turtle.forward()
      end
      harvest()
    end

    if y ~= width then
      if y%2==0 then -- even, turn left
        turtle.turnLeft()
        turtle.forward()
        harvest()
        turtle.turnLeft()
      else -- odd, turn right
        turtle.turnRight()
        turtle.forward()
        harvest()
        turtle.turnRight()
      end
    end
  end
  -- If width is even, we're facing the way we need to go.
  -- If width is odd, we need to turn around.
  if width%2==1 then
    turtle.turnLeft()
    turtle.turnLeft()
  end
  -- If the width is even, then we've already travelled this distance.
  if width%2==1 then
    for _=1,length-1 do
      turtle.forward()
    end
  end
  turtle.turnRight()
  for _=1,width-1 do
    turtle.forward()
  end
  turtle.turnRight()
  turtle.select(1)
  -- We are now at our beginning position :)
end

-- Main loop
while true do
  if turtle.getFuelLevel() < length*width+length+width+30 then
    term.setBackgroundColour(colours.red)
    term.setTextColour(colours.white)
    term.clear()
    write("no fuel bruh")
    error("",0)
  end
  if loop() then
    before()
    farm(length,width)
    after()
    turtle.select(1)
    term.setBackgroundColour(colours.blue)
    term.setTextColour(colours.white)
    term.clear()
    drawScreen()
  end
  sleep()
end
