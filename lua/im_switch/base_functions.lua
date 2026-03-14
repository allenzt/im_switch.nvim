local config = require("im_switch.config")

local M = {}

M.log_level_int = function(level)
  if type(level) == "number" then
    return level
  end
  return vim.log.levels[string.upper(level or "info")] or vim.log.levels.INFO
end

---echos `msg` as a vim.notify
---@param msg string: message to notify
---@param level integer | string | nil: ("info", "warn", "error"), if nil, "info" is used
---@param opts table?: Any options to pass to vim.notify
M.echo = function(msg, level, opts)
  local level_int = M.log_level_int(level)
  if M.log_level_int(config.log_level) <= level_int then
    vim.notify(msg, level_int, opts or {})
  end
end

return M
