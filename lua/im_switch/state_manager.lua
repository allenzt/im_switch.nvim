local config = require("im_switch.config")
local mode_util = require("im_switch.mode_util")

local M = {
  -- Buffer-level state storage
  -- buffer_state[bufnr] = {
  --   ins = { im = "rime", im_state = false },
  -- }
  buffer_state = {},
}

local mode_map = {
  ["NORMAL"]     = "norm",
  ["O-PENDING"]  = "norm",
  ["VISUAL"]     = "norm",
  ["V-LINE"]     = "norm",
  ["V-BLOCK"]    = "norm",
  ["SELECT"]     = "norm",
  ["S-LINE"]     = "norm",
  ["S-BLOCK"]    = "norm",
  ["INSERT"]     = "ins",
  ["REPLACE"]    = "ins",
  ["V-REPLACE"]  = "ins",
  ["COMMAND"]    = "cmd",
  ["EX"]         = "cmd",
  ["MORE"]       = "norm",
  ["CONFIRM"]    = "norm",
  ["SHELL"]      = "norm",
  ["TERMINAL"]   = "norm",
}

---Get the mode key for a mode char
---@param mode_char? string: literal char result from vim.api.nvim_get_mode()
---@return string: field name of im_switch.Imname
M.get_mode_key = function(mode_char)
  local mode_name = mode_util.get_mode(mode_char)
  return mode_map[mode_name] or "norm"
end

---Get target IM name for a mode
---@param mode string: mode key (norm, ins, cmd)
---@return string|nil: IM name
M.get_prior_im = function(mode)
  -- 只有 Insert 模式会从 buffer state 读取优先级记忆
  if mode == "ins" then
    local bufnr = vim.api.nvim_get_current_buf()
    local st = M.buffer_state[bufnr]
    if st and st[mode] and st[mode].im then
      return st[mode].im
    end
  end
  return config.imname[mode]
end

---Save buffer-level state
---@param bufnr integer: buffer number
---@param mode string: mode key
---@param im string|nil: IM name
---@param im_state any|nil: input method sub-state (e.g. ascii_mode for Rime)
M.save_buffer_state = function(bufnr, mode, im, im_state)
  if M.buffer_state[bufnr] == nil then
    M.buffer_state[bufnr] = {}
  end
  if M.buffer_state[bufnr][mode] == nil then
    M.buffer_state[bufnr][mode] = {}
  end
  M.buffer_state[bufnr][mode].im = im
  M.buffer_state[bufnr][mode].im_state = im_state
end

---Get buffer-level state
---@param bufnr integer: buffer number
---@param mode string: mode key
---@return table|nil: buffer state {im, im_state}
M.get_buffer_state = function(bufnr, mode)
  local st = M.buffer_state[bufnr]
  if st == nil or st[mode] == nil then
    return nil
  end
  return st[mode]
end

---Clean up buffer state
---@param bufnr integer: buffer number
M.cleanup_buffer = function(bufnr)
  M.buffer_state[bufnr] = nil
end

return M
