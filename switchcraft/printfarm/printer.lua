-- This queues and manages prints on the printer
local pg = require("progressbar")
local button = require("button")

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

local function drawBox(x,y,w,h,colour,filled,t)
  t = t or term
  for i = y, y+h-1 do
    if i == y or i == y+h-1 then
      t.setCursorPos(1,i)
      t.blit((" "):rep(w),colour:rep(w),colour:rep(w))
    else
      if not filled then
        t.setCursorPos(1,i)
        t.blit(" ",colour,colour)
        t.setCursorPos(x+w-1,i)
        t.blit(" ",colour,colour)
      else
        t.setCursorPos(1,i)
        t.blit((" "):rep(w),colour:rep(w),colour:rep(w))
      end
    end
  end
end

local function buttonCallback(file,win)
  local w,h = win.getSize()

  -- Collect information from the file.
  -- Load the file
  local f = assert(fs.open(file,"r"))
  -- deserialize it
  local data = textutils.unserializeJSON(f.readAll())
  -- Now close the file.
  f.close()

  -- We can extract the label.
  local label = data.label or "unlabelled print"
  -- We can start going through and calculating volume of the print for ink and chamelium costs.
  local volume = 0
  local surface = 0
  for _,shape in pairs(data.shapesOff) do
    volume = volume + (
      shape[4] - shape[1] *
      shape[5] - shape[2] *
      shape[6] - shape[3]
    )
    surface = surface + 2*(
      shape[4] - shape[1] +
      shape[5] - shape[2] +
      shape[6] - shape[3]
    )
  end
  for _,shape in pairs(data.shapesOn) do
    volume = volume + (
      shape[4] - shape[1] *
      shape[5] - shape[2] *
      shape[6] - shape[3]
    )
    surface = surface + 2*(
      shape[4] - shape[1] +
      shape[5] - shape[2] +
      shape[6] - shape[3]
    )
  end

  local redstoneCost = 300
  local noclipMultiplier = 2


  local chamelium = math.floor(
      (
        (volume/2) + 
        (data.redstoneLevel > 0 and redstoneCost or 0)
      ) * 
      (
        (data.collideWhenOff or data.collideWhenOn) and noclipMultiplier or 1
      )
    )
  local ink = math.floor((surface/6))

  -- Now we can overlay a box
  drawBox(1,1,18,5,"8",true,win)
  -- Print the label
  win.setCursorPos(2,2)
  win.write(label:sub(1,16))
  -- Now draw a box for the quantity. We're gonna have a sanity max of 9999,
  -- which would take 13 minutes on a 64 printer array. It also overflows a
  -- diamond chest, so realistically the max is 6912
  drawBox(2,3,4,1,"7",true,win)
  win.setCursorPos(7,3)
  win.write("CHA: "..chamelium)
  win.setCursorPos(7,4)
  win.write("INK: "..ink)
end

local buttons = {}

local function selectionManager()
  -- Here we prompt the user to actually figure out what we're printing.
  local win = window.create(term.current(),1,1,term.getSize())
  local w,h = win.getSize()
  while true do
    win.setVisible(false)
    win.setBackgroundColour(colours.black)
    win.setTextColour(colours.white)

    -- Draw a nice little box around the file selection window.
    drawBox(1,1,w,h-3,"b",false,win)

    -- Draw a nice little box around the file selection window.
    drawBox(1,h-3,w,h,"b",false,win)
    win.setCursorPos(1,h-1)
    win.blit((" "):rep(w),("b"):rep(w),("b"):rep(w))

    -- Void the buttons table.
    for _,id in pairs(buttons) do
      button.delete(id)
    end
    buttons = {}

    local files = fs.list("disk")
    for i=1,#files do
      win.setCursorPos(2,1+i)
      win.write(files[i])
      -- Now we have to go and rebuild the buttons if anything has changed.
      local btn = button.new(2,1+i,w-2,1,function() buttonCallback(files[i],win) end)
      buttons[#buttons+1] = btn
    end

    win.setVisible(true)
    sleep()
  end
end

parallel.waitForAny(
  printManager,
  selectionManager
)