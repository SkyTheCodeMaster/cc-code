-- Pulls powder from top chest, places in front, mines, pushes to bottom chest.

local function dropComplete()
  for i=1,16 do
    local data = turtle.getItemDetail(i)
    if data and data.name:match("minecraft:%a+_concrete$") then
      turtle.select(i)
      turtle.dropDown(64)
    end
  end
  turtle.select(1)
end

local function suck()
  while turtle.suckUp(64) do end
  dropComplete()
  turtle.select(1)
  turtle.dropUp(64) -- Make sure we have space to pick up the completed concrete.
end

local function process()
  for i=1,16 do
    local data = turtle.getItemDetail(i)
    if data and data.name:match("minecraft:%a+_concrete_powder") then
      turtle.select(i)
      while turtle.getItemCount(i) ~= 0 do
        turtle.place()
        turtle.dig()
        turtle.suck()
      end
    end
  end
end

while true do
  suck()
  process()
  dropComplete()
end