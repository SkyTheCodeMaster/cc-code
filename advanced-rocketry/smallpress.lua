-- This function will be a part of my turtle function library.
--- Check for items infront of the turtle. This will be replaced by `turtle.suck(0)` when the bug on it is fixed.
-- @treturn boolean Whether or not an item is infront of the turtle.
local function checkItem()
  if turtle.suck() then
    turtle.drop()
    return true
  else
    return false
  end
end

while true do
  if checkItem() then
    rs.setOutput("top",true) 
    sleep(0.05)
    rs.setOutput("true",false)
    turtle.suck()
    turtle.dropDown()
  end
  sleep()
end