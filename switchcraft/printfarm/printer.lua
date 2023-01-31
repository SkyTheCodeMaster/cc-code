-- This queues and manages prints on the printer
local pg = require("progressbar")

local monitor = peripheral.wrap("monitor_368")

local printers = {peripheral.find("3d_printer")}

local queue = {}

-- queue = { 
--  {
--    name="name of prints here",
--    remaining=number of remaining prints in this job.
--    data = print_data here (Loaded 3DJ file)
--  }
--  
--
--
-- }

local function getJob()
  local currentJob = queue[1]
  local data = currentJob.data
  if currentJob.remaining == 1 then
    table.remove(queue,1)
  else
    currentJob.remaining = currentJob.remaining-1
  end
  return data
end

local function startPrinter(printer)
  local job = getJob()
  local shapes = {}
  -- Most of this parser is from the inbuilt print3d program.
  local function addShape(shape,state)
    table.insert(shapes, {
      shape.bounds[1], shape.bounds[2], shape.bounds[3], shape.bounds[4], shape.bounds[5], shape.bounds[6],
      state = state,
      texture = shape.texture,
      tint = type(shape.tint) == "string" and tonumber(shape.tint,16) or type(shape.tint) == "number" and shape.tint or 0xFFFFFF
    })
  end

  if job.label then printer.setLabel(job.label) end
  if job.tooltip then printer.setTooltip(job.tooltip) end
  printer.setButtonMode(job.isButton or false)
  printer.setCollidable(job.collideWhenOff ~= false, job.collideWhenOn ~= false)
  printer.setRedstoneLevel(job.redstoneLevel or 0)
  printer.setLightLevel(job.lightLevel or 0)

  for _,shape in ipairs(job.shapesOff) do
    addShape(shape,false)
  end
  for _,shape in ipairs(job.shapesOn) do
    addShape(shape,true)
  end

  printer.addShapes(shapes)
  printer.commit(1)
end

local function printManager()
  while true do
    for _,printer in pairs(printers) do
      if printer.status() == "idle" then
        startPrinter(printer)
      end
    end
    sleep()
  end
end

local function selectionManager()
  -- Here we prompt the user to actually figure out what we're printing.
  local win = window.create(term.current(),1,1,term.getSize())
  local w,h = win.getSize()
  while true do
    win.setVisible(false)
    win.setBackgroundColour(colours.black)
    win.setTextColour(colours.white)

    -- Draw a nice little box around the file selection window.
    for y = 1, h-3 do
      if y == 1 or y == h-3 then
        term.setCursorPos(1, y)
        term.blit((" "):rep(w), ("b"):rep(w), ("b"):rep(w))
      else
        term.setCursorPos(1, y)
        term.blit(" ", "b", "b")
        term.setCursorPos(w, y)
        term.blit(" ", "b", "b")
      end
    end
  end
end

parallel.waitForAny(printManager,selectionManager)