local itemPipe = require("lupus590.item_pipe")
 
local f = assert(fs.open("config.lson","r"))
local data = textutils.unserialize(f.readAll())
 
local function filterFactory(item)
  return function(i)
    return i.name == item
  end
end
 
local pipes = {}
 
for src,dst in pairs(data) do
  local pipe = itemPipe.newPipe(src)
  for dest,filter in pairs(dst) do
    pipe.addDestination(dest).setFilter(filterFactory(filter))
  end
  table.insert(pipes,pipe.build())
end
 
local function tick()
  for _,pipe in pairs(pipes) do
    pipe.tick()
  end
end
 
while true do
  tick()
  sleep()
end