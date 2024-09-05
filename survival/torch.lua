-- Place torches in an area
-- Needs https://github.com/Fatboychummy-CC/Libraries/blob/main/simple_argparse.lua at "argparse.lua"

local argparse = require "argparse"

local parser = argparse.new_parser("Torch Placer","A program to adequately light spaces")
parser.add_flag("a","auto","Automatically determine the size of the room. Pass X and Y otherwise")
parser.add_flag("c","circle","Runs mapping to determine the size of a non-rectangular room.")
parser.add_flag("h","help", "Print this help message.")
parser.add_option("grid","The amount of space in between torches.",5)
parser.add_option("maxsize","The farthest the rangefinder will go for automatically determining the room's size",128)
parser.add_option("torch","The id of the light source.","minecraft:torch")
parser.add_argument("x", "The X size of the room.", false)
parser.add_argument("y", "The Y size of the room.", false)

local parsed = parser.parse({...})

-- set defaults
if not parsed.options.grid then
  parsed.options.grid = 5
end
if not parsed.options.maxsize then
  parsed.options.maxsize = 128
end
if not parsed.options.torch then
  parsed.options.torch = "minecraft:torch"
end

if parsed.flags.help then
  error(parser.usage(), 0)
end

if not parsed.flags.auto and (not parsed.arguments.x or not parsed.arguments.y) then
  error("Specify X and Y, or use --auto mode.", 0)
end

if parsed.flags.auto and parsed.flags.circle then
  error("Circular mode not implemented.", 0)
end

local auto_mode
if parsed.flags.auto and not parsed.flags.circle then
  auto_mode = "rectangle"
elseif parsed.flags.auto and parsed.flags.circle then
  auto_mode = "circle"
else
  auto_mode = "none"
end

local function rangefinder(max)
  max = max or 100
  
  local distance = 0
  while not turtle.detect() do
    distance = distance + 1
    turtle.forward()
  end
  
  for i=1,distance do
    turtle.back()
  end

  print("[RANGE] " .. distance)

  return distance
end

local function get_room_size(max)
  max = max or 100

  local x = rangefinder(max)
  turtle.turnRight()
  local y = rangefinder(max)
  turtle.turnLeft()
  print("Discovered room of X"..x..",Y"..y)
  return x,y
end

local torches_placed = 0
local function place_torch()
  if turtle.detectDown() then
    -- Something is already here!
    return
  end

  -- Shortcut: check current slot first
  local item = turtle.getItemDetail()
  if item and item.name == parsed.options.torch then
    turtle.placeDown()
    torches_placed = torches_placed + 1
    return
  end

  for i=1,16 do
    local item = turtle.getItemDetail(i)
    if item and item.name == parsed.options.torch then
      turtle.select(i)
      turtle.placeDown()
      torches_placed = torches_placed + 1
      break
    end
  end
end

local function get_total_torches()
  local torches = 0
  for i=1,16 do
    local item = turtle.getItemDetail(i)
    if item and item.name == parsed.options.torch then
      torches = torches + item.count
    end
  end
  return torches
end

local room_x,room_y
if auto_mode == "rectangle" then
  room_x,room_y = get_room_size(parsed.options.maxsize)
elseif auto_mode == "circle" then
  error("circle mode not implemented",0)
else
  room_x,room_y = parsed.arguments.x,parsed.arguments.y
end





-- Now we should simply travel along the room and place some torches
if not parsed.options.grid then
  parsed.options.grid = 5
end
local gridsize = parsed.options.grid+1

-- Check number of torches
local total_torches = get_total_torches()
local torches_required = (room_x / gridsize) * (room_y / gridsize)

local function print_progress()
  local fuel = turtle.getFuelLevel()
  local message = "Fuel:"..fuel..";"..torches_placed.."/"..torches_required
  print(message)
end

if total_torches < torches_required then
  print("Missing " .. torches_required - total_torches .. " torches! Will continue, but will run out eventually!")
end


if auto_mode == "rectangle" then
  -- start at the corner, place a torch
  place_torch()
  print_progress()
  turtle.turnRight()
  for _y=0,room_y do
    -- move forward and place torches
    if _y % gridsize == 0 then
      turtle.turnLeft()
      for _x=0,room_x do
        turtle.forward()
        if _x % gridsize == 0 then
          place_torch()
          print_progress()
        end
      end
      -- This is terrible for fuel efficiency, but whatever
      for _=1,room_x do
        turtle.back()
      end
      turtle.turnRight()
    end
    turtle.forward()
  end
end