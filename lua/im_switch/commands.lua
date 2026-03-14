local lib = require("im_switch.lib")
local config = require("im_switch.config")
local mode_util = require("im_switch.mode_util")
local state_manager = require("im_switch.state_manager")
local backend = require("im_switch.backend")

local M = {}

---Check if fcitx5 is running
---@return boolean
M.is_fcitx5_running = function()
  return string.len(vim.fn.system("command ps -A | command grep fcitx5")) > 0
end

---Set input method to imname
---@param imname string: target input method name
M.ImSwitchSetName = function(imname)
  lib.info(string.format("ImSwitchSetName: %s", imname))

  if not config.autostart_fcitx5 and not M.is_fcitx5_running() then
    lib.warn("fcitx5 is not running and autostart is disabled")
    return
  end

  local current_mode = state_manager.get_mode_key()
  local previous_im = backend.get_current_im()

  if backend.switch_to_im(imname) then
    if previous_im then
      state_manager.set_prior_im(current_mode, previous_im)
    end
    state_manager.set_prior_im(current_mode, imname)
    lib.info(string.format("Switched to %s (mode: %s)", imname, current_mode))
  end
end

---Intelligent mode: switch to appropriate IM for current mode
M.ImSwitchGeneious = function()
  lib.info("ImSwitchGeneious called")

  if not config.autostart_fcitx5 and not M.is_fcitx5_running() then
    lib.warn("fcitx5 is not running and autostart is disabled")
    return
  end

  local current_mode = state_manager.get_mode_key()
  local target_im = state_manager.get_prior_im(current_mode)

  if target_im then
    backend.switch_to_im(target_im)
    lib.info(string.format("Switched to %s for mode %s", target_im, current_mode))
  else
    lib.info(string.format("No target IM for mode %s", current_mode))
  end
end

---Handler for ModeChanged autocmd
M.ImSwitchOnModeChanged = function()
  return require("im_switch.autocmds").on_mode_changed()
end

---Manually set prior IM for a mode
---@param mode string|nil: mode key (uses current mode if nil)
---@param imname string: IM name
M.ImSwitchSetPrior = function(mode, imname)
  local target_mode = mode or state_manager.get_mode_key()
  state_manager.set_prior_im(target_mode, imname)
  lib.info(string.format("Set prior IM for %s: %s", target_mode, imname))
end

---Get IM name for a mode
---@param mode string|nil: mode key (uses current mode if nil)
---@return string|nil: IM name
M.ImSwitchGetImname = function(mode)
  local target_mode = mode or state_manager.get_mode_key()
  return state_manager.get_prior_im(target_mode)
end

---Get all IM names for all modes
---@return table: mode → imname mapping
M.ImSwitchGetImnames = function()
  return state_manager.get_all_prior_im()
end

return M
