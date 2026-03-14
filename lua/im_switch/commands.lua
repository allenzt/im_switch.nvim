local lib = require("im_switch.lib")
local config = require("im_switch.config")
local state_manager = require("im_switch.state_manager")
local backend = require("im_switch.backend")
local drivers = require("im_switch.drivers")

local M = {}

---Set input method to imname
---@param imname string: target input method name
M.ImSwitchSet = function(imname)
  lib.info(string.format("ImSwitchSet: %s", imname))

  local current_mode = state_manager.get_mode_key()

  if backend.switch_to_im(imname) then
    state_manager.save_buffer_state(vim.api.nvim_get_current_buf(), current_mode, imname, nil)
    lib.info(string.format("Switched to %s (mode: %s)", imname, current_mode))
  end
end

---Display current input method status
---@return string: status string
M.ImSwitchStatus = function()
  local current_mode = state_manager.get_mode_key()
  local current_im = backend.get_current_im()
  local bufnr = vim.api.nvim_get_current_buf()
  local buffer_state = state_manager.get_buffer_state(bufnr, current_mode)

  local parts = {
    "=== ImSwitch Status ===",
    string.format("Current Mode: %s", current_mode),
    string.format("Current IM: %s", current_im or "Unknown"),
  }

  -- 通过驱动显示子状态
  if config.enable_state_memory and current_im then
    local driver = drivers.get(current_im)
    if driver and driver.get_state then
      local state = driver.get_state()
      if state ~= nil then
        table.insert(parts, string.format("State: %s", state == true and "English" or "Chinese"))
      end
    end
  end

  if buffer_state then
    table.insert(parts, string.format("Buffer %d %s state: im=%s", bufnr, current_mode, buffer_state.im or "None"))
    if buffer_state.im_state ~= nil then
      table.insert(parts, string.format("  State: %s", buffer_state.im_state == true and "English" or "Chinese"))
    end
  end

  table.insert(parts, "Configured IMs:")
  for mode, im in pairs(config.imname) do
    if im then
      table.insert(parts, string.format("  %s: %s", mode, im))
    end
  end

  local status = table.concat(parts, "\n")
  lib.info(status)
  return status
end

return M
