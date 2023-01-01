-- run a function every TIME seconds.
-- and also smack the monitor to interrupt the countdown and trigger it manually
local TIME = 300
local runFirst = true -- Whether or not to run the function first before start ticking down

-- Monitor stuff
local monitor = peripheral.find("monitor")
monitor.setTextScale(2.5)
monitor.setBackgroundColour(colours.green)
monitor.setTextColour(colours.white)
monitor.clear()

-- function to run
local function tick()
  rs.setOutput("bottom",true)
  sleep(0.05)
  rs.setOutput("bottom",false)
end

-- no touchie
local stop = false

local function countdown()
  while true do
    -- run first wackiness
    if runFirst then
      tick()
    end
    runFirst = false

    for i=TIME,0,-1 do
      if stop then break end
      if i<=10 then
        monitor.setBackgroundColour(colours.red)
      else
        monitor.setBackgroundColour(colours.green)
      end
      monitor.setTextColour(colours.white)
      monitor.setCursorPos(1,1)
      monitor.clear()
      monitor.write(i)
      sleep(1)
    end
    tick()
    stop = false
  end
end

local function interrupt()
  while true do
    local _,name = os.pullEvent("monitor_touch") 
    if name == peripheral.getName(monitor) then
      stop = true
    end
  end
end

parallel.waitForAny(countdown,interrupt)