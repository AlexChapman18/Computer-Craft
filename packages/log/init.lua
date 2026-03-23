---@diagnostic disable: need-check-nil, assign-type-mismatch
--
-- log.lua
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local log = { _version = "0.1.0" }

log.outfile = "console.log"
log.level = "trace"


local modes = {
  { name = "trace", color = "\27[34m", },
  { name = "debug", color = "\27[36m", },
  { name = "info",  color = "\27[32m", },
  { name = "warn",  color = "\27[33m", },
  { name = "error", color = "\27[31m", },
  { name = "fatal", color = "\27[35m", },
}


local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end


local round = function(x, increment)
  increment = increment or 1
  x = x / increment
  return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end


local _tostring = tostring

local tostring = function(...)
  local t = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = round(x, .01)
    end
    t[#t + 1] = _tostring(x)
  end
  return table.concat(t, " ")
end

local function init()
  for i, x in ipairs(modes) do
    local nameupper = x.name:upper()
    log[x.name] = function(...)

      -- Return early if we're below the log level
      if i < levels[log.level] then
        return
      end

      local msg = tostring(...)
      local info = debug.getinfo(2, "Sl")
      local lineinfo = info.short_src .. ":" .. info.currentline

      -- Output to console
      print(string.format("[%s][%s] %s",
                          os.date("%H:%M:%S"), lineinfo, msg))

      -- Output to log file
      if log.outfile then
        local fp = io.open(log.outfile, "a")
        local str = string.format("[%s][%s] %s\n",
                                  os.date("%H:%M:%S"), lineinfo, msg)
        fp:write(str)
        fp:close()
      end

    end
  end
end

function log.disable()
  for _, m in ipairs(modes) do
    log[m.name] = function() end
  end
end

function log.enable()
  init()
end


-- Initialize by default
init()

return log