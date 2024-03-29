-- Displays all of the printer's stats on a monitor.
local pg = require("progressbar")


local monitor = peripheral.wrap("monitor_369") -- yes this is hardcoded.

monitor.setTextScale(0.5)
monitor.setBackgroundColour(colours.black)
monitor.setTextColour(colours.white)
monitor.clear()
local w,h = monitor.getSize()
local superWin = window.create(monitor,1,1,w,h)

local printers = {peripheral.find("3d_printer")}

-- Calculate and build windows
-- Each printer needs 15x8
local pstats = {}

local rowLength = 0
local row = 0
local column = 0
for i,printer in ipairs(printers) do
  if rowLength+14 > w then
    row = row + 1
    rowLength = 0
    column = 0
  end
  rowLength = rowLength + 14

  local win = window.create(superWin,column*14+1,row*8+1,14,8)
  local obj = {win=win,printer=printer,id=i,bars={
    status = pg.create(2,3,13,1,colours.lime,colours.red,0,win),
    ink = pg.create(2,5,13,1,colours.lime,colours.red,0,win),
    chamelium = pg.create(2,7,13,1,colours.lime,colours.red,0,win),
  }}
  pstats[#pstats+1] = obj
  column = column + 1
end

local function getStats(objs)
  local stats = {}
  local funcs = {}
  for _,obj in pairs(objs) do
    funcs[#funcs+1] = function()
      local stat = {}
      local printer = obj.printer
      local c,cMax = printer.getChameliumLevel() -- chamelium, chamelium max
      local i,iMax = printer.getInkLevel() -- ink, ink max
      local status,progress = printer.status() -- Printer status and progress
      stat.c,stat.cMax = c,cMax
      stat.i,stat.iMax = i,iMax
      stat.status,stat.progress = status,progress
      stat.win = obj.win
      stat.id = obj.id
      stat.bars = obj.bars
      stats[#stats+1] = stat
    end
  end

  local temp = {}
  for i,func in ipairs(funcs) do
    temp[#temp+1] = func
    if i%8 == 0 then
      parallel.waitForAll(table.unpack(temp))
      temp = {}
    end
  end
  return stats
end

local function drawStats(stats)
  for _,stat in pairs(stats) do
    local win = stat.win

    win.setVisible(false)

    win.setCursorPos(2,1)
    win.write("Printer #"..stat.id)

    win.setCursorPos(2,2)
    win.write("Status: "..(stat.status or "UNK"))

    win.setCursorPos(2,4)
    win.write("Ink:")

    win.setCursorPos(2,6)
    win.write("Chamelium:")

    stat.bars.status:update((stat.progress or 0))
    stat.bars.ink:update((stat.i/stat.iMax)*100)
    stat.bars.chamelium:update((stat.c/stat.cMax)*100)

    win.setVisible(true)
  end
end

while true do
  superWin.setVisible(false)
  drawStats(getStats(pstats))
  superWin.setVisible(true)
  ---@diagnostic disable-next-line: undefined-field
  print("cycle", os.epoch("local") / 1000)
  rs.setOutput("right",true)
  sleep(0.25)
  rs.setOutput("right",false)
  sleep(0.75)
end