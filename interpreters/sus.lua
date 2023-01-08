local f = fs.open(({...})[1],"r")
local contents = f.readAll()
f.close()

local memory = setmetatable({},{__index = function(self,k) rawset(self,k,0) return rawget(self,k) end})
local pointer = 0

local lastjmp = 0
local skip = false
local spot = 1
local funcs = {
  [">"] = function() pointer = pointer + 1 end,
  ["<"] = function() pointer = pointer - 1 end,
  ["+"] = function() memory[pointer] = memory[pointer] + 1 end,
  ["-"] = function() memory[pointer] = memory[pointer] -1 end,
  ["$"] = function() lastjmp = spot skip = false if memory[pointer] == 0 then skip = true end end,
  ["!"] = function() if not skip then spot = lastjmp end skip = false end,
  ["|"] = function() write(string.char(memory[pointer])) end
}

local function split(inputstr)
  local t={}
  for str in inputstr:gmatch(".") do
    t[#t+1] = str
  end
  return t
end

local program = split(contents)

for i=1,#program do
  spot = i
  funcs[program[i]]()
  if spot ~= i then i = spot end
end