-- Receives events from advanced-peripherals/tracker.lua

local modem = peripheral.find("modem",function(_,v)return v.isWireless()end)
local mon = peripheral.find("monitor_5")

modem.open(1354)

local win = window.create(mon,1,1,mon.getSize())

local function slice(tbl,first,last)
  first = first or 1
  last = last or #tbl
  local out = {}
  for i=first,last do
    table.insert(out,tbl[i])
  end
  return out
end

local function centerWrite(txt,y,t)
  t = t or term
  local width = t.getSize()

  t.setCursorPos(math.ceil((width / 2) - (txt:len() / 2)), y)
  t.write(txt)
end

local w,h = win.getSize()

local log = {}

local function main()
  while true do
    local _,_,_,_,msg = os.pullEvent("modem_message")
    table.insert(log,msg)

    win.setVisible(false)

    win.setTextColour(colours.white)
    win.setBackgroundColour(colours.blue)
    win.clear()

    centerWrite("Reports",1,win)
    
    win.setCursorPos(1,2)
    win.write(("-"):rep(w))

    local s = slice(log,h-3)

    for i,v in ipairs(s) do 
      win.setCursorPos(1,i+3)
      win.write(v)
    end

    win.setVisible(true)
  end
end

main()