-- USER DEFINED PARAMETERS
local length = 9 -- How long your farm is
local width = 9 -- How wide your farm is
local cropName = "minecraft:wheat"
local seedName = "minecraft:wheat_seeds"

-- This determines if the turtle digs the crop, and what it replaces it with.
local function check()
  local _,data = turtle.inspectDown()
  if data and data.name == cropName and data.state.age == 7 then
    return true,seedName
  end
end

-- This determines what the turtle does after it finishes the farm.
local function after()
  turtle.back()
  for i=1,16 do
    local data = turtle.getItemDetail(i)
    if data and data.name == cropName then
      turtle.select(i)
      turtle.dropDown()
    elseif data and data.name == seedName then
      turtle.select(i)
      turtle.dropUp()
    end
  end
  turtle.forward()
end
-- no touchie from here >:(
local skyrtle = require("skyrtle")
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
  term.write("SkyNet Farming Program v1.0")
  term.setCursorPos(1,2)
  term.write("---------------------------------------")
  term.setCursorPos(1,3)
  term.write("Harvesting: "..cut(split(cropName,":")[2]:gsub("^$l",string.upper),27))
  term.setCursorPos(1,4)
  term.write("---------------------------------------")
  term.setCursorPos(1,5)
  term.write("Fuel: "..turtle.getFuelLevel())
  term.setCursorPos(1,6)
  term.write("Needed: "..length*width+length+width+30)
end
drawScreen()

-- Main loop
while true do
  if turtle.getFuelLevel() < length*width+length+width+30 then
    term.setBackgroundColour(colours.red)
    term.setTextColour(colours.white)
    term.clear()
    drawScreen()
    os.pullEvent("key")
  end
  local _,data = turtle.inspectDown()
  if data and data.name == cropName and data.state.age == 7 then
    skyrtle.farm.farm(length,width,check)
    after()
    turtle.select(1)
    term.setBackgroundColour(colours.blue)
    term.setTextColour(colours.white)
    term.clear()
    drawScreen()
  end
end