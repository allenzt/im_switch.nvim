local lib = require("im_switch.lib")
local state_manager = require("im_switch.state_manager")
local config = require("im_switch.config")
local backend = require("im_switch.backend")

local M = {}

---Handler for ModeChanged event
M.on_mode_changed = function()
  -- Skip macro execution
  if vim.fn.reg_executing() ~= "" then
    lib.info("Skipping mode change during macro execution")
    return
  end

  local old_mode = state_manager.get_mode_key(vim.v.event.old_mode)
  local new_mode = state_manager.get_mode_key(vim.v.event.new_mode)

  lib.info(string.format("Mode changed: %s -> %s", old_mode, new_mode))

  local bufnr = vim.api.nvim_get_current_buf()

  -- Save old mode state
  if old_mode == "ins" or old_mode == "cmd" then
    local current_im = backend.get_current_im()

    if current_im then
      state_manager.set_prior_im(old_mode, current_im)

      -- Save Rime state (Layer 2) - Phase 4 will enhance this
      if current_im == "rime" and config.remember_rime_state then
        local ascii_mode = backend.get_rime_ascii_mode()
        if ascii_mode ~= nil then
          state_manager.set_rime_state(old_mode, current_im, ascii_mode)
          state_manager.save_buffer_state(bufnr, old_mode, current_im, ascii_mode)
          lib.info(string.format("Saved Rime state: ascii_mode=%s", tostring(ascii_mode)))
        end
      end
    end
  end

  -- Switch to new mode's IM
  local target_im = state_manager.get_prior_im(new_mode)

  if target_im then
    local switched = backend.switch_to_im(target_im)

    if switched then
      -- Restore Rime state (Layer 2) - Phase 4 will enhance this
      if target_im == "rime" and config.remember_rime_state then
        local restored = state_manager.restore_rime_state(new_mode, target_im)
        if restored then
          lib.info("Restored Rime state successfully")
        end
      end
    end
  end
end

return M
