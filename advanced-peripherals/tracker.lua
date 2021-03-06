-- Tracks players entering a configurable radius and writes their name down in a file.

local RANGE = 10 -- Scanner range.
local PATH = "log.csv" -- Path for the log.
local DATEFMT = "%F %T" -- The date format to use in the log.
local WAIT_TIME = 1 -- How many seconds in between each scan.
local MODEM_CHANNEL = 1354 -- Modem channel to send updates on in format of "LABEL: DATEFMT, Player"
local WHITELIST = { -- Who to not report
  ["SkyCrafter0"]=true,
}

-- NO TOUCHIE
local pd = peripheral.find("playerDetector")

local modem = peripheral.find("modem")

local function file(path)
  if not fs.exists(path) then
    local f = fs.open(path,"w")
    f.write("time,name\n")
    f.close()
  end
  local f = fs.open(path,"a")
  local function fwrite(time,name)
    f.write(("%s,%s\n"):format(time,name))
    f.flush()
  end
  return setmetatable({},{
    __call=function(self,...) return fwrite(...) end,
    __index=f,
  })
end

local last = {} -- This is the last players here, along with timestamp, like {Sky=utc_long_here}, so that players are only logged once every minute (aka time+60000)
local log = {} -- This is the full log, a tabular form of the file. aka {time_string_here,name}.

local f = file(PATH)

local makeTime = function()return os.date(DATEFMT)end

local function slice(tbl,first,last)
  first = first or 1
  last = last or #tbl
  local out = {}
  for i=first,last do
    table.insert(out,tbl[i])
  end
  return out
end

local function process()
  local lastIndex = 0
  while true do
    local players = pd.getPlayersInRange(RANGE)
    local updated = false
    for k,v in pairs(players) do
      if not WHITELIST[v] then
        local time = os.epoch("utc")
        if (not last[v]) or (last[v] and last[v]+60000<time) then -- If we have seen them before and if they are last spotted more than 60s ago then log them.
          last[v] = time
          table.insert(log,{makeTime(),v})
          updated = true
        end
      end
    end
    if updated then
      for i=lastIndex+1,#log do
        local entry = log[i]
        if entry then 
          f(entry[1],entry[2])
          lastIndex = i
          -- Send the log over the modem.
          if modem then
            modem.transmit(MODEM_CHANNEL,1,string.format("%s: %s, %s",os.getComputerLabel(),entry[1],entry[2]))
          end
        end
      end
    end
    sleep(WAIT_TIME)
  end
end

local win = window.create(term.current(),1,1,term.getSize())

local function display()
  while true do
    win.setVisible(false)
    
    win.setBackgroundColour(colours.blue)
    win.setTextColour(colours.white)
    win.clear()

    win.setCursorPos(1,1)
    win.write("     Tracker v1.0 - Skynet Systems     ")

    win.setCursorPos(1,2)
    win.write(("-"):rep(39))

    local selection = slice(log,#log-10)
    for i=1,#selection do
      local entry = selection[i]
      if entry then
        win.setCursorPos(1,3+i)
        win.write(("%s,%s"):format(entry[1],entry[2]))
      end
    end

    win.setVisible(true)

    sleep(1)
  end
end

parallel.waitForAny(process,display)