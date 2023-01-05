-- First of all, read the helper and main script into memory, and error if either of them don't exist.
local fHelper = assert(fs.open("/helper.lua","r"))
local helperCode = fHelper.readAll()
fHelper.close()

local fScript = assert(fs.open("/script.lua"))
local scriptCode = fScript.readAll()
fScript.close()

-- load required libraries
local coro = require("libraries.coro")
local req = require("cc.require")

local function deepcopy(t)
  local out = {}
  for k,v in pairs(t) do
    if type(v) == "table" then
      out[k] = deepcopy(v)
    else
      out[k] = v
    end
  end
  return out
end

local function makeEnvironment(additives)
  local env = additives and deepcopy(additives) or {}
  env.shell = shell
  env.multishell = multishell
  env.require,env.package = req.make(env,"/")
  return env
end

local function getLocals(coro)
  -- We want to return a proxy table of local names.
  -- This will upon indexing it, use `debug.getupvalue` to get the current state of the local variable.
  
  local function getState()
    local map = {}
    local i = 0
    local func = debug.getinfo(coro, 1, "f").func
    while true do
      i = i + 1
      local name,value = debug.getupvalue(func,i)
      if not name then break end
      map[name] = value
    end
    return map
  end

  local function setVariable(name,value)
    local i = 0
    local func = debug.getinfo(coro, 1, "f").func
    while true do
      i = i + 1
      local nam = debug.getupvalue(func,i)
      if nam == name then
        debug.setupvalue(coro,i,value)
        return true
      elseif not nam then
        return false
      end
    end
    return false
  end

  local locals = setmetatable({},{
    __index = function(self,k)
      local map = getState()
      return map[k]
    end,
    __newindex = function(self,k,v)
      setVariable(k,v)
    end
  })

  return locals
end

local scriptCoro

local scriptEnv = makeEnvironment()
local scriptFunc = load(scriptCode,"@hv-script","t",scriptEnv)

local helperEnv = makeEnvironment({getLocals = function() return getLocals(scriptCoro) end})
local helperFunc = load(helperCode,"@hv-helper","t",helperEnv)

---@diagnostic disable-next-line: param-type-mismatch
scriptCoro = coroutine.create(scriptFunc)
---@diagnostic disable-next-line: param-type-mismatch
local helperCoro = coroutine.create(helperFunc)

coro.newCoro(scriptCoro,"script")
coro.newCoro(helperCoro,"helper")

coro.runCoros()