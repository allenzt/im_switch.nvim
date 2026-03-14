local state_manager = require("im_switch.state_manager")
local config = require("im_switch.config")
local backend = require("im_switch.backend")
local drivers = require("im_switch.drivers")

local M = {}

-- 无意义的子模式变化，不需要切换输入法
local skip = {
  i  = { niI = true, niR = true, niV = true },
  n  = { niI = true, nt = true, nv = true, no = true },
  c  = { cv = true, ce = true },
  niI = { i = true, n = true },
  niR = { i = true },
  niV = { i = true },
  nt  = { n = true },
  nv  = { n = true },
  no  = { n = true },
  cv  = { c = true },
  ce  = { c = true },
}

---Apply IM and driver state for the given mode (shared by ModeChanged and BufEnter)
---@param mode string: mode key (norm, ins, cmd)
---@param bufnr integer: buffer number
---@param old_mode? string: previous mode key (for skip optimization)
local function apply_im_for_mode(mode, bufnr, old_mode)
  -- Phase 2: Determine target IM
  local target_im = state_manager.get_prior_im(mode)
  if not target_im then
    return
  end

  -- Phase 3: Switch IM
  backend.switch_to_im(target_im)

  -- Phase 4: Handle input method state via driver
  if not config.enable_state_memory then
    return
  end

  local driver = drivers.get(target_im)
  if not driver then
    return
  end

  -- Normal/Command mode: force English
  if mode == "norm" or mode == "cmd" then
    local skip_force = false
    -- 如果刚从 Insert 退出，且保存状态的输入法就是目标输入法，且状态已经是英文，跳过
    if old_mode == "ins" then
      local just_saved = state_manager.get_buffer_state(bufnr, "ins")
      if just_saved and just_saved.im == target_im and just_saved.im_state == true then
        skip_force = true
      end
    end
    if not skip_force and driver.force_english then
      driver.force_english()
    end
    return
  end

  -- Insert mode: restore saved state only if saved IM matches target IM
  if mode == "ins" then
    local buffer_state = state_manager.get_buffer_state(bufnr, "ins")
    if buffer_state and buffer_state.im == target_im and buffer_state.im_state ~= nil then
      if driver.set_state then
        driver.set_state(buffer_state.im_state)
      end
    end
  end
end

---Handler for ModeChanged event
M.on_mode_changed = function()
  if vim.fn.reg_executing() ~= "" then
    return
  end

  local old_mode_raw = vim.v.event.old_mode
  local new_mode_raw = vim.v.event.new_mode

  if skip[old_mode_raw] and skip[old_mode_raw][new_mode_raw] then
    return
  end

  local old_mode = state_manager.get_mode_key(old_mode_raw)
  local new_mode = state_manager.get_mode_key(new_mode_raw)
  local bufnr = vim.api.nvim_get_current_buf()

  -- ========================================================================
  -- Phase 1: Save state (only when leaving Insert mode)
  -- ========================================================================
  if old_mode == "ins" then
    local current_im = backend.get_current_im()
    local current_state = nil
    -- 通过驱动获取当前输入法的子状态（不硬编码输入法名称）
    if config.enable_state_memory and current_im then
      local driver = drivers.get(current_im)
      if driver and driver.get_state then
        current_state = driver.get_state()
      end
    end
    if current_im then
      state_manager.save_buffer_state(bufnr, "ins", current_im, current_state)
    end
  end

  apply_im_for_mode(new_mode, bufnr, old_mode)
end

---Handler for BufEnter event
---Ensures correct IM when entering a buffer (e.g. after `nvim file.txt`)
M.on_buf_enter = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local mode = state_manager.get_mode_key(vim.api.nvim_get_mode().mode)
  apply_im_for_mode(mode, bufnr)
end

return M
