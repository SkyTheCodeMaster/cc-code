-- Sits atop a flower farm, sucks and sorts items.

local COMPOST = peripheral.wrap("ender_storage_6082")
local ALLIUMS = peripheral.wrap("sc-goodies:diamond_chest_1573")
local DANDELS = peripheral.wrap("sc-goodies:diamond_chest_1574")
local CORNFLR = peripheral.wrap("sc-goodies:diamond_chest_1575")
local OXDAISY = peripheral.wrap("sc-goodies:diamond_chest_1576")
local POPPIES = peripheral.wrap("sc-goodies:diamond_chest_1577")

local selfName = peripheral.wrap("top").getNameLocal()

local endpoints = {
  ["minecraft:allium"] = ALLIUMS,
  ["minecraft:dandelion"] = DANDELS,
  ["minecraft:cornflower"] = CORNFLR,
  ["minecraft:oxeye_daisy"] = OXDAISY,
  ["minecraft:poppy"] = POPPIES, 
}

local function centerWrite(txt,y,t)
  t = t or term
  local ox,oy = t.getCursorPos()
  y = y or oy
  local width = t.getSize()
  t.setCursorPos(math.ceil((width/2)-(txt:len()/2)),y)
  t.write(txt)
  t.setCursorPos(ox,oy)
end

local function percent(chest)
  local list = chest.list()
  local size = chest.size()
  local itemCount = 0
  local maxItems = 64*size
  for i=1,size do
    if list[i] then
      itemCount = itemCount + list[i].count
    end
  end
  return math.floor((itemCount/maxItems)*100)
end

term.setBackgroundColour(colours.blue)
term.setTextColour(colours.white)
term.clear()
centerWrite("Skynet Flower Farm",1,term)
term.setCursorPos(1,2)
local w = term.getSize()
term.write(string.rep("-",w))

while true do
  if turtle.suckDown(64) then
    for i=1,16 do
      local data = turtle.getItemDetail(i)
      if data then
        if endpoints[data.name] then
          local endpoint = endpoints[data.name]
          if percent(endpoint) >= 98 then
            endpoint = COMPOST
          end
          endpoint.pullItems(selfName,i)
        else
          local endpoint = COMPOST
          endpoint.pullItems(selfName,i)
        end
      end
    end
  end
end