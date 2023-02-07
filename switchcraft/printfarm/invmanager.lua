-- Balance materials from a pair of input diamond chests across all connected iron chests.
local INKINPUT = peripheral.wrap("sc-goodies:diamond_chest_1741")
local CHAINPUT = peripheral.wrap("sc-goodies:diamond_chest_1740")

local OUTPUTS = {peripheral.find("sc-goodies:iron_chest")}

local function balancer()
  while true do
    local funcs = {}
    for _,chest in pairs(OUTPUTS) do
      local function func()
        local list = chest.list()
        local cha = 0
        local ink = false
        for slot,data in pairs(list) do
          if data.name == "sc-peripherals:chamelium" then
            cha = 64-data.count
          elseif data.name == "sc-peripherals:ink_cartridge" then
            ink = true
          end
        end
        if cha ~= 0 then
          for slot in pairs(CHAINPUT.list()) do
            chest.pullItems(peripheral.getName(CHAINPUT),slot,cha)
            break
          end
        end
        if not ink then
          for slot in pairs(INKINPUT.list()) do
            chest.pullItems(peripheral.getName(INKINPUT),slot)
          end
        end
      end
      funcs[#funcs+1] = func
    end
    if next(funcs) then
      funcs[#funcs+1] = function()
        -- blink the funny light to show activity
        rs.setOutput("right",true)
        sleep(0.1)
        rs.setOutput("right",false)
      end
      parallel.waitForAll(table.unpack(funcs))
    end
  end
end

balancer()