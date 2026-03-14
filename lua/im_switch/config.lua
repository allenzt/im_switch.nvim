---@class im_switch.Config
---@field imname im_switch.Imname: IM names for each mode (norm, ins, cmd)
---@field enable_state_memory boolean: Enable input method state memory (default: true)
---@field log_level string: Log level (default: "warn")

---@type im_switch.Config
local DEFAULT_OPTS = {
  imname = {
    norm = nil,
    ins = nil,
    cmd = nil,
  },
  enable_state_memory = true,
  log_level = "warn",
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
  opts = opts or {}
  -- 向后兼容：旧配置名 enable_rime_memory 映射到新名称
  if opts.enable_rime_memory ~= nil and opts.enable_state_memory == nil then
    opts.enable_state_memory = opts.enable_rime_memory
  end
  for key, value in pairs(merge_options(opts, DEFAULT_OPTS)) do
    M[key] = value
  end
end

return M
