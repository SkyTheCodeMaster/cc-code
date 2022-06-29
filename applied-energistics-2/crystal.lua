-- Sucks in 8 stacks from the top (of seeds, provided by M/E autocrafter, or hand fed)
-- Drops them down
-- Waits 30 seconds (24secs for 5 crystal growers, refer to https://appliedenergistics.github.io/features/crystals for other arrangements)
local WAIT_TIME = 30

-- Sucks everything back up, if it's still in seed form it will throw it back down, and throw everything else forward

-- NO TOUCHIE

local count = 0 -- A nice little count on the display.

-- Infinitely process materials.
local function process()
  while true do
    -- Attempt to pick up 1024 items (16 stacks) from below the turtle.
    local success = false
    for i=1,16 do
      if turtle.suckDown(64) then
        success = true
      end
    end

    -- If items were picked up, sort them.
    if success then
      -- Loop the inventory.
      for i=1,16 do
        -- Check if an item exists.
        local data = turtle.getItemDetail(i)
        -- If it does exist and has the word `seed` in it's name, drop it.
        if data and data.name:match("seed") then
          turtle.select(i)
          turtle.dropDown()
          -- Add the number of crystals thrown to the count.
          count = count + i.count

        -- Else, drop it back down for more time.
        else
          turtle.select(i)
          turtle.drop()
        end
      end

    -- If no items were picked up, pick up 512 items (8 stacks) from above the turtle.
    else
      for i=1,8 do
        turtle.suckDown(64)
      end

      -- Check if they were picked up.
      for i=1,16 do
        -- Loop the inventory, if there is an item in the slot then select it and drop everything.
        if turtle.getItemDetail(i) then
          turtle.select(i)
          turtle.dropDown(64)
        end
      end
    end
    -- Select the first slot.
    turtle.select(1)
    -- Sleep for (default) 30 seconds, waiting for crystals to grow.
    sleep(WAIT_TIME)
  end
end

-- Initialize a buffer window.
local win = window.create(term.current(),1,1,term.getSize())

local function display()
  while true do
    -- Set the visibility to false so that changes are buffered, not drawn.
    win.setVisible(false)
    
    win.setBackgroundColour(colours.blue)
    win.setTextColour(colours.white)
    win.clear()

    win.setCursorPos(1,1)
    win.write("Crystal Grower v1.0 - Skynet Systems")

    win.setCursorPos(1,2)
    win.write((" "):rep(39))

    win.setCursorPos(1,3)
    -- Write the count using string.format
    win.write(("Processed: %d"):format(count))

    -- Set the visibility to true so that buffered changes are drawn.
    win.setVisible(true)

    -- Now sleep for 10 seconds, this display doesn't need to eat system resources.
    sleep(10)
  end
end

parallel.waitForAny(process,display)