local a = "left"
local b = "right"
local output = "back"

local op = {
  ["and"] = function(a,b) return a and b end,
  ["or"] = function(a,b) return a or b end,
  ["nand"] = function(a,b) return not a and b end,
  ["nor"] = function(a,b) return not a or b end,
  ["xor"] = function(a,b) return bit.bxor(a and 1 or 0, b and 1 or 0) == 1 end,
  ["nxor"] = function(a,b) return bit.bxor(a and 1 or 0, b and 1 or 0) == 0 end,
}

local mode = ...

local function printUsage()
  local operations = "Usage: " .. shell.getRunningProgram() .. " <"
  for k in pairs(op) do
    operations = operations .. k .. "|"
  end
  operations = operations:sub(1,#operations-1)
  operations = operations .. ">"
  printError(operations)
  return
end

if not mode or not op[mode] then
  printUsage()
end

while true do
  os.pullEvent("redstone")
  local state = op[mode](rs.getInput(a),rs.getInput(b))
  rs.setOutput(output,state)
end