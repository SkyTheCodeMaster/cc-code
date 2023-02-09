local coro = require("libraries.coro")

-- Load main modules
local _modules = fs.list("modules")
local modules = {}
-- Get proper filepath
for _,fileName in ipairs(_modules) do
  table.insert(modules,fs.combine("modules",fileName))
end

-- Load startup files too
local _startup = fs.list("startup")
for _,fileName in pairs(_startup) do
  table.insert(modules,fs.combine("startup",fileName))
end

local funcs = {}
for _,file in pairs(modules) do
  ---@diagnostic disable-next-line: redefined-local
  local f = fs.open(file,"r")
  local content = f.readAll()
  f.close()
  local code = load(content,"="..file,"t",_ENV)
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
centerWrite("SCiPNet Client",1)
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