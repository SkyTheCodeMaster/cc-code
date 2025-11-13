-- Displays induction matrix stats on a 2x3 screen.
-- has progress bar showing the stored energy, input, and output.
-- has text box at the bottom showing time to empty / full

-- configuration
local MONITOR = "top"
local MATRIX = "back"
local BACKGROUND = colours.blue

-- hz
local UPDATE_RATE = 10

local TEXT = colours.white
local ENERGY_COL = colours.purple
local ENERGY_IN_COL = colours.green
local ENERGY_OUT_COL = colours.red

-- peripheral wrapping
local mon = peripheral.wrap(MONITOR)
if not mon then error("Monitor not found") end
local matrix = peripheral.wrap(MATRIX)
if not matrix then error("Matrix not found") end

-- find or download graphics library
if not fs.exists("graphics.lua") then
  local h,err = http.get("https://raw.githubusercontent.com/SkyTheCodeMaster/SkyDocs/refs/heads/main/src/main/misc/graphics.lua")
  if not h then error("graphics: " .. err) end
  local response = h.readAll()
  h.close()
  local f = fs.open("graphics.lua", "w")
  f.write(response)
  f.close()
end

-- Load the graphics library.
local graphics = require("graphics")

-- Set up the monitor
mon.setBackgroundColour(BACKGROUND)
mon.setTextColour(TEXT)
mon.setTextScale(0.5)
mon.setCursorPos(1,1)
mon.clear()
local mon_width,mon_height = mon.getSize()

local function get_induction_stats()
  local energy = matrix.getEnergy()
  local energy_max = matrix.getMaxEnergy()

  local input = matrix.getLastInput()
  local output = matrix.getLastOutput()

  local transfer_limit = matrix.getTransferCap()

  return {
    energy = energy,
    energy_max = energy_max,
    input = input,
    output = output,
    transfer_limit = transfer_limit
  }
end

-- Calculates the time to either fill or empty
-- Takes stats from get_induction_stats, returns a postive or negative number. Positive is seconds until full, negative is seconds until empty.
local function calculate_time(stats)
  local difference = stats.input - stats.output
  if difference == 0 then return 0 end -- Case for if energy is balanced, or IM is already empty/full.
  local buffer = 0<difference and (stats.energy_max - stats.energy) or stats.energy
  return buffer / (difference*20)
end

-- Calculate time string out to days
local function time_string(seconds)
  local s = math.floor(seconds % 60)
  local minutes = math.floor(seconds / 60)
  local m = minutes % 60
  local hours = math.floor(minutes / 60)
  local h = hours % 60
  local days = math.floor(hours / 60)

  local out = ""
  if s > 0 then
    out = tostring(s) .. "s"
  end
  if m > 0 then
    out = tostring(m) .. "m" .. out
  end
  if h > 0 then
    out = tostring(h) .. "h" .. out
  end
  if days > 0 then
    out = tostring(days) .. "d" .. out
  end

  return out
end

local function humanize_energy(energy)
  local suffixes = {[0] = "FE", "KFE", "MFE", "GFE", "TFE", "PFE", "EFE"}
  if energy < 1000 then
    return tostring(energy) .. "FE"
  end

  local exponent = math.floor(math.min(math.log(energy, 1000), #suffixes))
  return ("%.1f"):format(tostring(energy / (1000^exponent))) .. suffixes[exponent]
end

-- Set up the graphics library
-- The parent element for everything, provides a background for the monitor.
local parent_rectangle = graphics.new("rectangle", {
  origin = {1,1},
  size = {mon_width,mon_height},
  border = TEXT,
  fill = BACKGROUND,
  pixel = true
})

-- Title at the top of the program.
local label = graphics.new("textbox", {
  origin = {0,2},
  size = {mon_width, 1}, -- Sneaky trick for easy centering.
  text = "Induction Matrix",
  colour = TEXT,
  background = false,
  background_fill = BACKGROUND,
  wordwrap = "none"
})


-- Create a progress bar for the charge of the induction matrix, from Y=4 to about halfway down the monitor.
local epg_height = math.floor((mon_height/2)-4)
local energy_pg = graphics.new("progress", {
  origin = {1,4},
  size = {mon_width-2, epg_height},
  colour = ENERGY_COL,
  background = BACKGROUND,
  border = true,
  border_pixel = true,
  mode = "full",
  direction = "right"
})


-- Create a textbox right under for time to full/empty and the actual numbers

local energy_tb = graphics.new("textbox", {
  origin = {1, epg_height + 5},
  size = {mon_width-2, 2},
  text = "energy tb placeholder",
  colour = TEXT,
  background = false,
  background_fill = BACKGROUND
})


-- Create progress bars half the width of the screen, for input and output.

local energy_flow_width = math.floor((mon_width-3)/2)
local energy_in_pg = graphics.new("progress", {
  origin = {1, epg_height + 8},
  size = {energy_flow_width, 4},
  colour = ENERGY_IN_COL,
  background = BACKGROUND,
  border = true,
  border_pixel = true,
  mode = "full",
  direction = "right"
})


local energy_in_tb = graphics.new("textbox", {
  origin = {1, epg_height + 13},
  size = {energy_flow_width, 1},
  colour = TEXT,
  background_fill = BACKGROUND,
  background = false,
  text = "placeholder",
})

local energy_out_pg = graphics.new("progress", {
  origin = {energy_flow_width+2, epg_height + 8},
  size = {energy_flow_width, 4},
  colour = ENERGY_OUT_COL,
  background = BACKGROUND,
  border = true,
  border_pixel = true,
  mode = "full",
  direction = "right",
  value = 1
})

local energy_out_tb = graphics.new("textbox", {
  origin = {energy_flow_width + 2, epg_height + 13},
  size = {energy_flow_width, 1},
  colour = TEXT,
  background_fill = BACKGROUND,
  background = false,
  text = "PLACEHOLDER"
})

parent_rectangle:append_child(label)

parent_rectangle:append_child(energy_pg)
parent_rectangle:append_child(energy_tb)

parent_rectangle:append_child(energy_in_pg)
parent_rectangle:append_child(energy_in_tb)

parent_rectangle:append_child(energy_out_pg)
parent_rectangle:append_child(energy_out_tb)

local function update_objects()
  local stats = get_induction_stats()
  local fill_time = calculate_time(stats)

  local energy_percent = (stats.energy / stats.energy_max)
  local out_percent = (stats.output / stats.transfer_limit)
  local in_percent = (stats.input / stats.transfer_limit)

  energy_pg.value = energy_percent
  energy_in_pg.value = in_percent
  energy_out_pg.value = out_percent

  -- calculate the proper 0h0m0s for the time to full/empty
  local seconds = calculate_time(stats)
  local filling = 0<seconds
  local abs_seconds = math.abs(seconds)
  local timestring = time_string(abs_seconds)
  local time_until = timestring .. (filling and " until full" or " until empty")

  local storage_text = humanize_energy(stats.energy / 2.5) .. " / " .. humanize_energy(stats.energy_max / 2.5) .. "\n" .. time_until
  energy_tb.text = storage_text

  local in_text = humanize_energy(stats.input) .. " / " .. humanize_energy(stats.transfer_limit)
  local out_text = humanize_energy(stats.output) .. " / " .. humanize_energy(stats.transfer_limit)
  energy_in_tb.text = in_text
  energy_out_tb.text = out_text
end

while true do
  update_objects()
  parent_rectangle:draw(mon)
  sleep(0.1)
end