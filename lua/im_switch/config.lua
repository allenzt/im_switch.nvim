---@class im_switch.Config
---@field msg string | nil: printed when startup is completed
---@field imname im_switch.Imname | nil: imnames on each mode set as prior. See `:h map-table` for more in-depth information.
---@field remember_prior boolean: if true, load the mode from last time. if false, use what was set in setup.
---@field define_autocmd boolean: if true, defines autocmd at `ModeChanged` to switch fcitx5 mode.
---@field autostart_fcitx5 boolean: if true, autostarts `fcitx5` when it is not running.
---@field log string: log level (default: warn)
---@field remember_rime_state boolean: Enable Rime state memory (Layer 2)
---@field rime_state_method string: Rime state method: "auto"/"dbus"/"lgi"/"remote"
---@field rime_state_cache_ttl integer: Cache duration in ms for Rime state

---@type im_switch.Config
local DEFAULT_OPTS = {
  msg = nil,
  imname = {
    norm = nil,
    ins = nil,
    cmd = nil,
    vis = nil,
    sel = nil,
    opr = nil,
    term = nil,
    lang = nil,
  },
  remember_prior = true,
  define_autocmd = true,
  autostart_fcitx5 = true,
  log = "warn",
  remember_rime_state = true,
  rime_state_method = "auto",
  rime_state_cache_ttl = 5000,
}

---@type im_switch.Config
local M = {}

local merge_options = function(opts, default)
  return vim.tbl_deep_extend("force", default, opts or {})
end

---load_opts
-- Merge user opts to DEFAULT_OPTS
---@param opts im_switch.Config | nil: Options from user setup
M.set_options = function(opts)
  for key, value in pairs(merge_options(opts, DEFAULT_OPTS)) do
    M[key] = value
  end
end

return M
