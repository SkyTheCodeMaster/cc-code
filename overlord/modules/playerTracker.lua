-- Locates every player in the map and displays their location.
local mon = peripheral.wrap("monitor_4")
local pd = peripheral.find("playerDetector")

local w,h = mon.getSize()

local function centerWrite(txt,y,t)
  t = t or term
  local width, height = t.getSize()

  t.setCursorPos(math.ceil((width / 2) - (txt:len() / 2)), y)
  t.write(txt)
end

local function main()
  while true do
    mon.setTextColour(colours.white)
    mon.setBackgroundColour(colours.blue)
    mon.clear()

    centerWrite("Player Position",1,mon)

    mon.setCursorPos(1,2)
    mon.write(("-"):rep(w))

    local players = pd.getOnlinePlayers()
    for i,v in ipairs(players) do
      local pos = pd.getPlayerPos(v)
      centerWrite(("%s: %d, %d, %d"):format(v,pos.x,pos.y,pos.z),3+i,mon)
    end

    sleep(5)
  end
end

main()