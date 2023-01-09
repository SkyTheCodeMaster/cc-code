--- SkyOS coroutine manager without the SkyOS, and active coroutines.

-- Localize coroutine library, because it gets used quite a bit, surprisingly.
local coroutine = coroutine
--- Currently running coroutines. This is stored in `SkyOS.coro.coros`
local coros = {}

--- The amount of processes that have been created.
local pids = 0

local running = true

--- Make a new coroutine and add it to the currently running list.
-- @tparam function func Function to run forever.
-- @tparam[opt] string name Name of the coroutine, defaults to `coro`.
-- @tparam[opt] number parent Parent PID, mirrors it's active state.
-- @tparam[opt] table env Custom environment to use for coroutine, defaults to `_ENV`.
-- @tparam[opt] boolean forceActive Whether or not this coroutine will always have user events.
-- @treturn number PID of the coroutine. This shouldn't change.
local function newCoro(func,name,parent)
  local pid = pids + 1
  pids = pid
  table.insert(coros,{coro=type(func) == "thread" and func or coroutine.create(func),filter=nil,name=name or "coro",pid = pid,parent=parent})
  return pid
end 

--- Kill a coroutine, and remove it from the coroutine table.
-- @param coro Coroutine to kill, accepts a number (index in table) or a string (name of coroutine).
local function killCoro(coro)
  if type(coro) == "number" then
    if coros[coro] then coros[coro] = nil end
  elseif type(coro) == "string" then
    for i=1,#coros do
      if coros[i].name == coro then
        coros[i] = nil
        break
      end
    end
  end
end

--- Run the coroutines. This doesn't take any parameters nor does it return any.
local function runCoros()
  local e = {n = 0}
  while running do
    for k,v in pairs(coros) do
      if coroutine.status(v.coro) == "dead" then
        coros[k] = nil
      else
        if not v.filter or v.filter == e[1] or e[1] == "terminate" then -- If unfiltered, pass all events, if filtered, pass only filter
          -- Check for active coroutine
            ---@diagnostic disable-next-line: deprecated
            local ok,filter = coroutine.resume(v.coro,table.unpack(e))
            if ok then
              v.filter = filter -- okie dokie
            else
              error(filter)
            end
        end
      end
    end
    ---@diagnostic disable-next-line: deprecated
    e = table.pack(coroutine.yield())
  end
  running = true
end

--- Resume a coroutine with a custom event, with error handling and such.
-- @tparam number pid Process ID of coroutine to resume.
-- @param ... Event details to resume with.
local function resume(pid,...)
  if coros[pid] then
    local ok,filter = coroutine.resume(coros[pid].coro,...)
    if ok then
      coros[pid].filter = filter
    else
      error(filter)
    end
  end
end

--- Stop the coroutine manager, halting all threads after current loop. Note that this will not stop it immediately.
local function stop()
  running = false
end

return {
  coros = coros,
  newCoro = newCoro,
  killCoro = killCoro,
  runCoros = runCoros,
  stop = stop,
  resume = resume,
}