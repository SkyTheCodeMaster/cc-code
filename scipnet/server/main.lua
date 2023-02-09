local coro = require("libraries.coro")

-- Load main modules
local _modules = fs.list("modules")
local modules = {}
-- Get proper filepath
for _,fileName in ipairs(_modules) do
  table.insert(modules,fs.combine("modules",fileName))
end

-- Load disk modules, these can be swapped as they are on a disk. Each site can have it's own set of extra modules.
local diskModules = {}
pcall(function()
  diskModules = fs.list("disk/modules")
end)
-- Now combine the disk modules into the main table
for _,fileName in ipairs(diskModules) do
  table.insert(modules,fs.combine("disk/modules",fileName))
end

-- Load the global data
local f = fs.open("data.json","r")
local data = textutils.unserializeJSON(f.readAll())
f.close()

local sha = require("libraries.sha256")

-- Load the data into _G
_G.scipnet = {data=data,coro=coro}
-- Now we also need to generate hashes of these.
_G.scipnet.data.users_hashed = {}
_G.scipnet.data.users_hashed_reversed = {}

local tmp = {}
for k,uuid in pairs(scipnet.data.users) do
  tmp[k] = {hash=sha.digest(uuid),uuid=uuid}
end
-- Now set numerical keys and reverse keys in table
for k,tbl in pairs(tmp) do
  scipnet.data.users_hashed[k] = tbl.hash
  scipnet.data.users_hashed[tbl.hash] = true
  scipnet.data.users_hashed_reversed[tbl.hash] = scipnet.data.users_reversed[tbl.uuid]
end

local funcs = {}
for _,file in pairs(modules) do
  ---@diagnostic disable-next-line: redefined-local
  local f = fs.open(file,"r")
  local content = f.readAll()
  f.close()
  local code = load(content,"="..file,"t",_ENV) --TODO: Manufacture a separate environment for each module.
  if code then
    table.insert(funcs,function()
      code()
    end)
  end
end

for _,func in pairs(funcs) do
  coro.newCoro(func)
end

term.setBackgroundColour(colours.blue)
term.setTextColour(colours.white)
term.clear()
local function centerWrite(txt,y,t)
  t = t or term
  local ox,oy = t.getCursorPos()
  y = y or oy
  local width = t.getSize()
  t.setCursorPos(math.ceil((width/2)-(txt:len()/2)),y)
  t.write(txt)
  t.setCursorPos(ox,oy)
end
centerWrite("SCiPNet Main Server",1)
term.setCursorPos(1,2)
local w = term.getSize()
term.write(("-"):rep(w))
term.setCursorPos(1,3)
term.write("Loaded modules:")
for i,file in ipairs(modules) do
  term.setCursorPos(1,i+3)
  term.write(fs.getName(file))
end

coro.runCoros()