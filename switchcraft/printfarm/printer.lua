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
    if next(queue) ~= nil then
      for _,printer in pairs(printers) do
        if printer.status() == "idle" and next(queue) ~= nil then
          startPrinter(printer)
        end
      end
    end
    sleep()
  end
end

local function displayManager()
  local files = fs.list("disk")
  local selected = 1
  local w,h = term.getSize()
  local win = window.create(term.current(),1,1,w,h)
  while true do
    win.setVisible(false)

    win.setCursorPos(1,1)
    win.blit((" "):rep(w),("b"):rep(w),("b"):rep(w))

    local subfiles = slice(files,1,1)

    for i,val in ipairs(files) do
      win.setCursorPos(1,i+1)
      if not i==selected then
        win.blit(" " .. (val .. (" "):rep(w-2)) .. " ","b" .. ("0"):rep(w-2) .. "b", "b" .. ("f"):rep(w-2) .. "b")
      else
        win.blit(" " .. (val .. (" "):rep(w-2)) .. " ","b" .. ("f"):rep(w-2) .. "b", "b" .. ("0"):rep(w-2) .. "b")
      end
    end
  end
end

parallel.waitForAny(
  printManager,
  displayManager
)