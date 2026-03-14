local backend = require("im_switch.backend")
local drivers = require("im_switch.drivers")

local M = {}

---Get Rime ascii_mode state
---@return boolean|nil: true=English, false=Chinese, nil=not available
M.get_state = function()
  return backend.get_rime_ascii_mode()
end

---Set Rime ascii_mode state
---@param state boolean: true=English, false=Chinese
---@return boolean
M.set_state = function(state)
  return backend.set_rime_ascii_mode(state)
end

---Force Rime to English mode
---@return boolean
M.force_english = function()
  return backend.set_rime_ascii_mode(true)
end

-- Auto-register on load
drivers.register("rime", M)

return M
