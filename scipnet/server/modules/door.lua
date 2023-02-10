local mon = peripheral.wrap("monitor_504")
-- Handles doors. Reads from `/data/doors.json`
-- {
--   "doors": {
--     "doorname": {
--       "bounds": [x1,y1,z1, x2,y2,z2],
--       "integrators": ["redstone_integrator_6969"],
--       "monitor": "monitor_1234",
--       "side": "top"
--     }
--   }
-- }
-- Monitor shows access logs

local bf = require("libraries.bigfont")

local function centerWrite(txt,y,t)
  t = t or term
  local ox,oy = t.getCursorPos()
  y = y or oy
  local width = t.getSize()
  t.setCursorPos(math.ceil((width/2)-(txt:len()/2)),y)
  t.write(txt)
  t.setCursorPos(ox,oy)
end

local w,h = mon.getSize()
local win = window.create(mon,1,1,w,h)
win.setBackgroundColour(colours.blue)
win.setTextColour(colours.white)
win.clear()
centerWrite("Door Access",1,win)
win.setCursorPos(1,2)
win.write(("-"):rep(w))

local f = fs.open("data/doors.json","r")
local data = textutils.unserialiseJSON(f.readAll())
f.close()

local function range(n, a, b)
  return n >= math.min(a,b) and n <= math.max(a,b)
end

local function within(v,c1,c2)
  -- Check if v is within c1 and c2
  return range(v.x, c1.x, c2.x) and range(v.y, c1.y, c2.y) and range(v.z, c1.z, c2.z)
end

local function open(door)
  door.open = true
  local doorMon = peripheral.wrap(door.monitor)
  local ris = {}
  for _,name in pairs(door.integrators) do
    ris[#ris+1] = peripheral.wrap(name)
  end

  -- Open the door
  for _,p in pairs(ris) do
    p.setOutput(door.side,true)
  end
  -- Display the countdown

  for i=3,1,-1 do
    bf.writeOn(doorMon,1,tostring(i),1,1)
    sleep(1)
  end
  doorMon.clear()
  for _,p in pairs(ris) do
    p.setOutput(door.side,false)
  end
  door.open = false
end
local accesses = {}

while true do
  local e = {os.pullEvent("network_message")}
  if e[2] == "gps" and scipnet.data.users_hashed[e[3]] then
    local eData = e[4]
    local pos = vector.new(eData.x,eData.y,eData.z)
    for name,d in pairs(data.doors) do
      if not d.open then
        local c1 = vector.new(d.bounds[1],d.bounds[2],d.bounds[3])
        local c2 = vector.new(d.bounds[4],d.bounds[5],d.bounds[6])
        if within(pos,c1,c2) then
          while #accesses > h-3 do
            table.remove(accesses,1)
          end
          table.insert(accesses,("%s @ %s: %s"):format(os.date(),name,scipnet.data.users_hashed_reversed[e[3]]))
          scipnet.coro.newCoro(function() open(d) end)
          break
        end
      end
    end
    win.setVisible(false)
    for i,v in ipairs(accesses) do
      win.setCursorPos(1,i+2)
      win.clearLine()
      win.write(v)
    end
    win.setVisible(true)
  end
end
