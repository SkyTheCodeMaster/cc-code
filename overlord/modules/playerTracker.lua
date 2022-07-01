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

local win = window.create(mon,1,1,mon.getSize())

local function main()
  while true do
    win.setVisible(false)

    win.setTextColour(colours.white)
    win.setBackgroundColour(colours.blue)
    win.clear()

    centerWrite("Player Position",1,win)

    win.setCursorPos(1,2)
    win.write(("-"):rep(w))

    local players = pd.getOnlinePlayers()
    for i,v in ipairs(players) do
      local pos = pd.getPlayerPos(v)
      if pos then
        centerWrite(("%s: %d, %d, %d"):format(v,pos.x,pos.y,pos.z),3+i,win)
      end
    end

    win.setVisible(true)
    sleep(5)
  end
end

main()