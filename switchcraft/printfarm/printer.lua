-- This queues and manages prints on the printer
local monitor = peripheral.wrap("monitor_368")

local printers = {peripheral.find("3d_printer")}


-- number lookup for selection box
local numbers = {["0"]=true,["1"]=true,["2"]=true,["3"]=true,["4"]=true,["5"]=true,["6"]=true,["7"]=true,["8"]=true,["9"]=true,}

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

local function calculateCosts(file)
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
      math.abs(shape.bounds[4] - shape.bounds[1]) *
      math.abs(shape.bounds[5] - shape.bounds[2]) *
      math.abs(shape.bounds[6] - shape.bounds[3])
    )
    surface = surface + 2*(
      math.abs(shape.bounds[4] - shape.bounds[1]) +
      math.abs(shape.bounds[5] - shape.bounds[2]) +
      math.abs(shape.bounds[6] - shape.bounds[3])
    )
  end
  for _,shape in pairs(data.shapesOn) do
    volume = volume + (
      math.abs(shape.bounds[4] - shape.bounds[1]) *
      math.abs(shape.bounds[5] - shape.bounds[2]) *
      math.abs(shape.bounds[6] - shape.bounds[3])
    )
    surface = surface + 2*(
      math.abs(shape.bounds[4] - shape.bounds[1]) +
      math.abs(shape.bounds[5] - shape.bounds[2]) +
      math.abs(shape.bounds[6] - shape.bounds[3])
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

  return {
    ink=ink,
    chamelium=chamelium,
    data=data,
  }
end

local function slice(tbl,start,final)
  local sublist = {}
  for i=start,final do
    sublist[#sublist+1] = tbl[i]
  end
  return sublist
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

local function confirm(file,win)
  local cost = calculateCosts(file)
  win.setVisible(false)
  win.clear()
  drawBox(1,1,20,6,"8",true,win)
  win.setCursorPos(2,2)
  win.setBackgroundColour(colours.lightGrey)
  win.write((cost.data.label or "unlabelled"):sub(1,18))
  win.setCursorPos(11,3)
  win.write("CHA:"..cost.chamelium)
  win.setCursorPos(11,4)
  win.write("INK:"..cost.ink)
  win.setCursorPos(4,3)
  win.blit("Quan","8888","7777")
  win.setCursorPos(2,5)
  win.blit("OK (E)","000000","dddddd")
  win.setCursorPos(12,5)
  win.blit("Exit (X)","00000000","eeeeeeee")
  win.setVisible(true)
  local quantity = ""
  while true do
    local e = {os.pullEvent("char")}
    if e[2] == "e" then
      -- Generate the table
      local job = {
        name=cost.data.label or "unlabelled",
        remaining = tonumber(quantity)or 1,
        startQuantity=tonumber(quantity)or 1,
        data = cost.data,
      }
      table.insert(queue,job)
    elseif e[2] == "x" then
      return
    elseif numbers[e[2]] then
      quantity = quantity..e[2]
    elseif e[2] == keys.backspace then
      quantity = quantity:sub(1,#quantity-1)
    end
  end
end

local function displayManager()
  local w,h = term.getSize()
  local win = window.create(term.current(),1,1,w,h-3)
  w,h = win.getSize()

  local files = fs.list("disk")
  local selected = 1
  local e = {}
  while true do
    files = fs.list("disk")
    if e[1] == "key" and e[2] == keys.up then
      if selected-1 == 0 then selected = #files
      else selected = selected - 1 end
    elseif e[1] == "key" and e[2] == keys.down then
      if selected+1 == #files+1 then selected = 1
      else selected = selected + 1 end
    elseif e[1] == "key" and e[2] == keys.enter then
      confirm(fs.combine("disk",files[selected]),win)
    end
    win.setVisible(false)
    
    drawBox(1,1,w,h,"b",false,win)

    win.setCursorPos(1,1)
    win.blit((" "):rep(w),("b"):rep(w),("b"):rep(w))

    local subfiles = slice(files,selected-6,selected+6)

    for i,val in ipairs(files) do
      win.setCursorPos(1,i+1)
      if i==selected then
        win.blit(" " .. (val .. (" "):rep(w-2-#val)) .. " ","b" .. ("f"):rep(w-2) .. "b", "b" .. ("0"):rep(w-2) .. "b")
      else
        win.blit(" " .. (val .. (" "):rep(w-2-#val)) .. " ","b" .. ("0"):rep(w-2) .. "b", "b" .. ("f"):rep(w-2) .. "b")
      end
    end
    win.setVisible(true)
    e = {os.pullEvent("key")}
  end
end

local function monitorManager()
  local bigfont = require("bigfont")
  local w,h = monitor.getSize()
  local win = window.create(monitor,1,1,w,h)
  w,h = win.getSize()
  while true do
    win.setVisible(false)
    for i,job in ipairs(queue) do
      local x = 1
      local y = i*6-5
      bigfont.blitOn(win,1,job.name:sub(1,10),("0"):rep(#job.name:sub(1,10)),("f"):rep(#job.name:sub(1,10)),x,y)
      win.setCursorPos(2,y+3)
      win.write("Remaining: "..job.remaining)
      local percent = math.floor((job.remaining/job.startQuantity)*100)
      win.setCursorPos(31,y+3)
      win.write(percent .. "% Done")
      win.setCursorPos(1,y+4)
      -- Make the text string, this will include the half character.
      local txt = ""
      local bg = ""
      if math.ceil(w*percent*2)/2 ~= math.floor(math.ceil(w*percent*2)/2) then
        txt = (" "):rep(math.ceil(w*percent*2)/2) .. "\149" .. (" "):rep(w-math.floor(math.ceil(w*percent*2)/2)-1)
        bg = ("d"):rep(math.ceil(w*percent*2)/2) .. "d" .. ("e"):rep(w-math.floor(math.ceil(w*percent*2)/2)-1)
      else
        txt = (" "):rep(w)
        bg = ("d"):rep(math.ceil(w*percent*2)/2) .. ("e"):rep(math.floor(math.ceil(w*percent*2)/2))
      end
      local fg = ("d"):rep(w)
      win.blit(txt,("d"):rep(w),bg)
    end
  end
end

parallel.waitForAll(
  printManager,
  displayManager
)