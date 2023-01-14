-- Displays all of the printer's stats on a monitor.
local pg = require("progressbar")


local monitor = peripheral.wrap("monitor_369") -- yes this is hardcoded.

monitor.setTextScale(0.5)
monitor.setBackgroundColour(colours.black)
monitor.setTextColour(colours.white)
monitor.clear()
local w,h = monitor.getSize()

local printers = {peripheral.find("3d_printer")}

-- Calculate and build windows
-- Each printer needs 15x8
local pstats = {}

local rowLength = 0
local row = 1
local column = 1
for i,printer in ipairs(printers) do
  if rowLength+14 > w then
    row = row + 1
    rowLength = 0
    column = 1
  end
  rowLength = rowLength + 14

  local win = window.create(monitor,row*14,column*8,14,8)
  local obj = {win=win,printer=printer,id=i,bars={}}
  pstats[#pstats+1] = obj
end

local function displayStats(obj)
  local win = obj.win
  local printer = obj.printer
  local id = obj.id
  if not obj.bars.status then obj.bars.status = pg.create(2,3,13,1,colours.lime,colours.red,0,win) end
  if not obj.bars.ink then obj.bars.ink = pg.create(2,5,13,1,colours.lime,colours.red,0,win) end
  if not obj.bars.chamelium then obj.bars.chamelium = pg.create(2,7,13,1,colours.lime,colours.red,0,win) end

  local c,cMax = printer.getChameliumLevel() -- chamelium, chamelium max
  local i,iMax = printer.getInkLevel() -- ink, ink max
  local status,progress = printer.status() -- Printer status and progress
  win.setVisible(false)

  win.setCursorPos(2,1)
  win.write("Printer #"..id)

  win.setCursorPos(2,2)
  win.write("Status: "..(status or "UNK"))

  win.setCursorPos(2,4)
  win.write("Ink:")

  win.setCursorPos(2,6)
  win.write("Chamelium:")

  obj.bars.status:update((progress or 0))
  obj.bars.ink:update((i/iMax)*100)
  obj.bars.chamelium:update((c/cMax)*100)

  win.setVisible(true)
end

while true do
  for _,p in pairs(pstats) do
    displayStats(p)
  end
  sleep(1)
end