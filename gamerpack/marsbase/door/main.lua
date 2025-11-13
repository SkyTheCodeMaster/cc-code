--[[
Manages opening and closing of doors, also organizes doors into rooms.
Will have ability to seal rooms if an oxygen leak is detected.
  ^ Ad Astra has weirdly implemented oxygen, this may not be implemented unless a miracle happens and it is fixed.

Makes the doors available on the websocket relay.
Packets are in the form of:
{
  "command": "xyz",
  "data": {
  
  },
  "nonce": "abc123"
}
Responses have the `command` key replaced with `response`.

The following commands are available:
list - no data - Returns a list of doors, and rooms.
door/open - {"door":"door_id"} - Opens a specified door.
door/close - {"door":"door_id"} - Closes a specified door.
room/open - {"room":"room_id"} - Opens all doors of a specified room.
room/close - {"room":"room_id"} - Closes all doors of a specified room.
]]

local expect = require("cc.expect").expect
local field = require("cc.expect").field

local Door = {}

--[[-Create a new door object.
---
--- A positive distance (or true redstone output) should be considered closing the door.
---
---@param opts table 
---@param opts.type string The type of door. Valid options are "create" and "piston". On a create door, it will use a motor as the peripheral, and has an optional end-stop.
---                        On a piston door, it uses a redstone relay and does not require an end-stop.
---@param opts.peripheral string The peripheral to use for controlling the door. If it's a redstone piston door, it must be in the form of `redstone_relay_id:side`. If it needs to be inverted, do `!side`.
---                              If the door is a create door, it must be `electric_motor_id`.
---@param opts.distance number If the type is `create`, this specifies the distance of the door. If the door needs to be inverted, invert the distance.
---@param opts.speed number If the type is `create`, this specifies a default speed.
---@param opts.endstop string The peripheral to use for reading the position of the door. By default, any redstone value is considered closed. Refer to `opts.peripheral` for the value.
---@param opts.id string The ID of the door, for referencing in other objects.
]]
function Door.new(opts)
  expect(1, opts, "table")
  field(opts, "type", "string")
  field(opts, "peripheral", "string")

  if opts.type == "create" then
    field(opts, "endstop", "string")
    field(opts, "distance", "number")
    field(opts, "speed", "number", "nil")
  end

  field(opts, "id", "string")

  local door = {
    type = opts.type,
    peripheral = opts.peripheral,
    distance = opts.distance,
    endstop = opts.endstop,
    speed = opts.speed,
    id = opts.id
  }

  return setmetatable(door, {__index=Door})
end

--- Split a string by it's separator.
-- @tparam string inputstr String to split.
-- @tparam string sep Separator to split the string by.
-- @treturn table Table containing the split string.
local function split(inputstr, sep)
  expect(1,inputstr,"string")
  expect(1,sep,"string","nil")
  sep = sep or ","
  local t={}
  for str in inputstr:gmatch("([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

-- Returns a table like:
-- {
--   peripheral=table - Peripheral object itself, usually a redstone relay.
--   side=string - The side to toggle.
--   inverted=bool - Whether or not the input or output should be inverted.
-- }
local function parse_redstone_relay(peripheral_name)
  -- First, split the actual peripheral and side.
  local parts = split(peripheral_name, ":")
  if #parts ~= 2 then
    error("attempting to split " .. peripheral_name .. ", but it has more than 2 parts.")
  end

  local dev = parts[1]
  local side = parts[2]
  local periph = peripheral.wrap(dev)
  if not periph then
    error(peripheral_name .. " has no peripheral on the network")
  end

  -- Check if the side is inverted
  local inverted = false
  if side:sub(0,1) == "!" then
    inverted = true
    side = side:sub(2)
  end

  return {
    peripheral = periph,
    side = side,
    inverted = inverted
  }
end

local function xor(a, b)
  return (a and not b) or (not a and b)
end

--- Actuate the door.
--- If the door is a create door, this is a blocking function, if it's a redstone door, it isn't.
--- @tparam open boolean If true, open the door. If false, close the door.
--- @tparam speed number|nil If the door is a create door, the speed to open it at.
function Door:actuate(open, speed)
  speed = speed or self.speed
  if self.type == "piston" then
    -- Parse the peripheral, and side, then send the correct command.
    local device = parse_redstone_relay(self.peripheral)

    device.peripheral.setOutput(device.side, xor(open, device.inverted))
  elseif self.type == "create" then
    -- Wrap the motor, do the math, and send the command.
    expect(speed, 2, "number")
    if open then
      local motor = peripheral.wrap(self.peripheral)

      if not motor then
        local err = "door " .. self.id .. " missing peripheral"
        error(err)
      end

      local dist
      if open then
        dist = self.distance
      else
        dist = -self.distance
      end

      local time = motor.translate(dist, speed)
      motor.setSpeed(speed)
      sleep(time)
      motor.stop()
    end
  end
end

--- Check the position of the door. In a create door this will check the endstop relay, in a redstone door this will check the output of the relay.
--- @treturn bool True if the door is open (endstop is triggered, or output is false), false if the door is closed.
function Door:is_open()
  if self.type == "create" then
    local device = parse_redstone_relay(self.endstop)
    return xor(device.peripheral.getInput(device.side), device.inverted)
  else
    local device = parse_redstone_relay(self.peripheral)
    return xor(not device.peripheral.getOutput(device.side), device.inverted)
  end
end

local OxygenSensor = {}

--[[-Create a O2 Sensor object.
---
---@param opts table 
---@param opts.peripheral string The peripheral to use for reading the sensor, it must be in the form of `redstone_relay_id:side`.
---@param opts.id string The ID of the door, for referencing in other objects.
]]
function OxygenSensor.new(opts)
  expect(1, opts, "table")
  field(opts, "peripheral", "string")

  field(opts, "id", "string")

  local o2sensor = {
    peripheral = opts.peripheral,
    id = opts.id
  }

  return setmetatable(o2sensor, {__index=OxygenSensor})
end

--- Check the status of the O2 Sensor.
--- @treturn bool True if oxygen is present.
function OxygenSensor:status()
  local device = parse_redstone_relay(self.peripheral)
  return xor(device.peripheral.getInput(device.side), device.inverted)
end

local Room = {}

--[[- Create a room object.
--- Has functions for checking whether or not oxygen is leaking, and can control the doors.
---@tparam opts table
---@tparam opts.id string The ID of the room.
---@tparam opts.doors table List of Door objects for the room.
---@tparam opts.oxygen_sensors table List of O2 Sensors for the room.
]]
function Room.new(opts)
  expect(1, opts, "table")
  field(opts, "id", "string")
  field(opts, "doors", "table")
  field(opts, "oxygen_sensors", "table")

  local room = {
    id = opts.id,
    doors = opts.doors,
    oxygen_sensors = opts.oxygen_sensors
  }

  return setmetatable(room, {__index=Room})
end

--- Actuate all doors in the room.
--- @tparam speed number If any doors are create doors, use this speed for them.
function Room:actuate(open, speed)
  for _,v in pairs(self.doors) do
    v:actuate(open, speed)
  end
end

-- Set up the config
local DEFAULT_CONFIG = [[{
  "websocket": "wss://ws.skystuff.cc/net",
  "ws_topic": "mars_doormanager",
  doors: [
    {
      "id": "airlock_inner",
      "type": "create",
      "peripheral": "electric_motor_0",
      "endstop": "redstone_relay_0:up",
      "speed": 128
    }
  ],
  rooms: [
    {
      "id": "airlock",
      "doors": [
        "airlock_inner"
      ],
      "oxygen_sensors": []
    }
  ]
}]]

if not fs.exists("dmconfig.json") then
  local f = fs.open("dmconfig.json", "w")
  f.write(DEFAULT_CONFIG)
  f.close()
end

local warnings = {}
local rooms = {}
local doors = {}
--local o2sensors = {}

local rawconfig = fs.open("dmconfig.json", "r")
local config = textutils.unserialiseJSON(rawconfig)
-- Just ignore oxygen sensors for now
for _,v in pairs(config.doors) do
  local door = Door.new(v)
  doors[door.id] = door
  -- do peripheral check
end

for _,v in pairs(config.rooms) do
  local room_id = v.id
  local room_doors = {}
  for i,door_id in ipairs(v.doors) do
    if doors[door_id] then
      room_doors[#room_doors+1] = doors[door_id]
    else
      warnings[#warnings+1] = "Room " .. room_id .. " missing door: " .. door_id
    end
  end
  local room_o2sensors = {}

  local room = Room.new({
    id = room_id,
    doors = room_doors,
    oxygen_sensors = room_o2sensors
  })
  rooms[room.id] = room
end

local function main()
  -- Setup the websocket
  local ws,err = http.websocket(config.websocket)
  if not ws then error(err) end

  -- Setup the listening channel
  local subscribe_packet = {
    t = "subscribe",
    c = config.ws_topic
  }

  -- Pregenerate the list packet, since this will never change.
  local list_doors = {}
  local list_rooms = {}

  for k,_ in pairs(doors) do
    list_doors[#list_doors+1] = k
  end
  for k,_ in pairs(rooms) do
    list_rooms[#list_rooms+1] = k
  end

  local list_packet = {
    t = "post",
    c = {
      topic = config.ws_topic,
      content = {
        doors = list_doors,
        rooms = list_rooms
      }
    }
  }

  ws.send(textutils.serialiseJSON(subscribe_packet))

  while true do
    local message = ws.receive()

    local received_packet = textutils.unserialiseJSON(message)

    if received_packet.t == "post" then
      local data = received_packet.c.data
      local nonce = data.nonce
      local ok = true
      local send_response = true
      if data.command == "door/open" then
        local door_id = data.data.door
        if doors[door_id] then
          doors[door_id]:actuate(true)
        else
          ok = false
        end
      elseif data.command == "door/close" then
        local door_id = data.data.door
        if doors[door_id] then
          doors[door_id]:actuate(false)
        else
          ok = false
        end
      elseif data.command == "room/open" then
        local room_id = data.data.room
        if rooms[room_id] then
          rooms[room_id]:actuate(true)
        else
          ok = false
        end
      elseif data.command == "room/open" then
        local room_id = data.data.room
        if rooms[room_id] then
          rooms[room_id]:actuate(false)
        else
          ok = false
        end
      elseif data.command == "list" then
        local send_packet = {
          response = nonce,
          ["nonce"] = nonce,
          data = list_packet
        }
        ws.send(textutils.serialiseJSON(send_packet))
        send_response = false
      end

      if send_response then
        local send_packet = {
          response = nonce,
          ["nonce"] = nonce,
          data = {success=ok}
        }
        ws.send(textutils.serialiseJSON(send_packet))
      end
    end
  end
end

term.setBackgroundColour(colours.black)
term.setTextColour(colours.white)
term.setCursorPos(1,1)
term.clear()
for _,v in ipairs(warnings) do
  print("W:", v)
end
print("Starting door manager...")
main()