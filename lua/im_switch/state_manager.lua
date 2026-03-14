local config = require("im_switch.config")
local lib = require("im_switch.lib")
local mode_util = require("im_switch.mode_util")

local M = {
  -- Layer 1: mode → imname
  prior = {
    norm = nil,
    ins = nil,
    cmd = nil,
    vis = nil,
    sel = nil,
    opr = nil,
    term = nil,
    lang = nil,
  },

  -- Layer 2: IM internal state (Rime ascii_mode)
  -- Key format: "mode+imname" e.g., "ins+rime"
  im_internal = {},

  -- Buffer-level state isolation
  -- buffer_state[bufnr] = { ins_im, ins_rime_ascii, ... }
  buffer_state = {},
}

---return the field name of im_switch.Imname based on mode
---@param mode_name string: mode name from mode_util.get_mode()
---@return string: field name of im_switch.Imname
local function get_mode_key(mode_name)
  local mode_map = {
    ["NORMAL"] = "norm",
    ["O-PENDING"] = "opr",
    ["VISUAL"] = "vis",
    ["V-LINE"] = "vis",
    ["V-BLOCK"] = "vis",
    ["SELECT"] = "sel",
    ["S-LINE"] = "sel",
    ["S-BLOCK"] = "sel",
    ["INSERT"] = "ins",
    ["REPLACE"] = "ins",
    ["V-REPLACE"] = "ins",
    ["COMMAND"] = "cmd",
    ["EX"] = "cmd",
    ["MORE"] = "norm",
    ["CONFIRM"] = "norm",
    ["SHELL"] = "term",
    ["TERMINAL"] = "term",
  }
  local mode_key = mode_map[mode_name]
  if mode_key == nil then
    lib.info(string.format("Unknown mode: `%s`. Fallback to norm", mode_name))
    mode_key = "norm"
  end
  return mode_key
end

---Get the mode key for a mode char
---@param mode_char? string: literal char result from vim.api.nvim_get_mode()
---@return string: field name of im_switch.Imname
M.get_mode_key = function(mode_char)
  return get_mode_key(mode_util.get_mode(mode_char))
end

---Get prior IM name for a mode
---@param mode string: mode key (norm, ins, cmd, etc.)
---@return string|nil: IM name
M.get_prior_im = function(mode)
  local imname = M.prior[mode]

  if config.remember_prior and imname ~= nil then
    lib.info(string.format("Prior IM for %s: %s (from memory)", mode, imname))
    return imname
  end

  imname = config.imname[mode]
  lib.info(string.format("Prior IM for %s: %s (from config)", mode, imname))
  return imname
end

---Set prior IM name for a mode
---@param mode string: mode key (norm, ins, cmd, etc.)
---@param imname string: IM name
M.set_prior_im = function(mode, imname)
  M.prior[mode] = imname
  lib.info(string.format("Set prior IM for %s: %s", mode, imname))
end

---Get all prior IM names
---@return table: mode → imname mapping
M.get_all_prior_im = function()
  local result = {}
  for key, _ in pairs(config.imname) do
    result[key] = M.get_prior_im(key)
  end
  return result
end

---Get saved Rime state for a mode and IM
---@param mode string: mode key (norm, ins, cmd, etc.)
---@param imname string: IM name
---@return boolean|nil: ascii_mode state
M.get_rime_state = function(mode, imname)
  local key = mode .. "+" .. imname
  local state = M.im_internal[key]

  if state then
    lib.info(string.format("Rime state for %s: ascii_mode=%s", key, tostring(state.ascii_mode)))
    return state.ascii_mode
  end

  lib.info(string.format("No saved Rime state for %s", key))
  return nil
end

---Set Rime state for a mode and IM
---@param mode string: mode key (norm, ins, cmd, etc.)
---@param imname string: IM name
---@param ascii_mode boolean|nil: ascii_mode state
M.set_rime_state = function(mode, imname, ascii_mode)
  local key = mode .. "+" .. imname

  if ascii_mode == nil then
    M.im_internal[key] = nil
    lib.info(string.format("Cleared Rime state for %s", key))
  else
    M.im_internal[key] = {
      ascii_mode = ascii_mode,
      last_update = vim.loop.now(),
    }
    lib.info(string.format("Saved Rime state for %s: ascii_mode=%s", key, tostring(ascii_mode)))
  end
end

---Restore Rime state via backend
---@param mode string: mode key (norm, ins, cmd, etc.)
---@param imname string: IM name
---@return boolean: true if successful
M.restore_rime_state = function(mode, imname)
  if not config.remember_rime_state then
    return false
  end

  local backend = require("im_switch.backend")
  local ascii_mode = M.get_rime_state(mode, imname)

  if ascii_mode ~= nil then
    lib.info(string.format("Restoring Rime state for %s: ascii_mode=%s", mode .. "+" .. imname, tostring(ascii_mode)))
    return backend.set_rime_ascii_mode(ascii_mode)
  end

  lib.info(string.format("No Rime state to restore for %s", mode .. "+" .. imname))
  return false
end

---Save buffer-level state
---@param bufnr integer: buffer number
---@param mode string: mode key
---@param imname string: IM name
---@param rime_ascii boolean|nil: Rime ascii_mode state
M.save_buffer_state = function(bufnr, mode, imname, rime_ascii)
  if M.buffer_state[bufnr] == nil then
    M.buffer_state[bufnr] = {}
  end

  M.buffer_state[bufnr][mode .. "_im"] = imname
  if rime_ascii ~= nil then
    M.buffer_state[bufnr][mode .. "_rime_ascii"] = rime_ascii
  end

  lib.info(string.format("Saved buffer %d state: %s=%s, rime_ascii=%s", bufnr, mode, imname, tostring(rime_ascii)))
end

---Get buffer-level state
---@param bufnr integer: buffer number
---@param mode string: mode key
---@return table|nil: buffer state {im, rime_ascii}
M.get_buffer_state = function(bufnr, mode)
  local state = M.buffer_state[bufnr]
  if state == nil then
    return nil
  end

  return {
    im = state[mode .. "_im"],
    rime_ascii = state[mode .. "_rime_ascii"],
  }
end

---Clean up buffer state
---@param bufnr integer: buffer number
M.cleanup_buffer = function(bufnr)
  M.buffer_state[bufnr] = nil
  lib.info(string.format("Cleaned up buffer %d state", bufnr))
end

return M
