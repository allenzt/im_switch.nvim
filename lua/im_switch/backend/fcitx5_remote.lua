local lib = require("im_switch.lib")

local M = {
  name = "fcitx5_remote",
  initialized = false,
}

---Initialize the fcitx5-remote backend
---@return boolean: true if successful
M.init = function()
  if vim.fn.executable("fcitx5-remote") == 1 then
    M.initialized = true
    lib.info("fcitx5-remote backend initialized")
    return true
  end
  lib.warn("fcitx5-remote not found")
  return false
end

---Get current input method name
---@return string|nil: current IM name or nil if failed
M.get_current_im = function()
  if not M.initialized then
    return nil
  end

  local result = vim.fn.system("fcitx5-remote -n")
  local success = vim.v.shell_error == 0

  if success then
    local imname = vim.trim(result)
    lib.info(string.format("Current IM: %s", imname))
    return imname
  end

  lib.error("Failed to get current IM")
  return nil
end

---Switch to a specific input method
---@param imname string: target input method name
---@return boolean: true if successful
M.switch_to_im = function(imname)
  if not M.initialized then
    return false
  end

  local cmd = string.format("fcitx5-remote -s %s", imname)
  local result = vim.fn.system(cmd)
  local success = vim.v.shell_error == 0

  if success then
    lib.info(string.format("Switched to IM: %s", imname))
    return true
  end

  lib.error(string.format("Failed to switch to IM: %s. Error: %s", imname, result))
  return false
end

return M
