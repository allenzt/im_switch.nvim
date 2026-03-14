---State driver registry for input method sub-state memory
---Each driver binds to a specific IM's D-Bus interface (e.g. Rime's IsAsciiMode)
local M = {
  drivers = {},
}

---Register a state driver for an input method
---@param imname string: input method name (e.g. "rime")
---@param driver table: driver with optional functions:
---   get_state() -> any|nil    : get current sub-state
---   set_state(state) -> bool  : restore sub-state
---   force_english() -> bool   : force English mode (for Normal/Command)
M.register = function(imname, driver)
  M.drivers[imname] = driver
end

---Get driver for an input method
---@param imname string: input method name
---@return table|nil: driver or nil if not registered
M.get = function(imname)
  return M.drivers[imname]
end

---Check if a driver exists
---@param imname string: input method name
---@return boolean
M.has = function(imname)
  return M.drivers[imname] ~= nil
end

return M
