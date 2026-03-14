local lib = require("im_switch.lib")
local config = require("im_switch.config")
local commands = require("im_switch.commands")

local M = {}

-- 暴露命令函数供 user command 回调使用
M.ImSwitchSet = commands.ImSwitchSet
M.ImSwitchStatus = commands.ImSwitchStatus
M.help = lib.help

local function setup_vim_commands()
  vim.api.nvim_create_user_command("ImSwitch", function(_)
    require("im_switch").help()
  end, { desc = "[im_switch.nvim] ImSwitch help" })

  vim.api.nvim_create_user_command("ImSwitchSet", function(opts)
    if #opts.fargs < 1 then
      require("im_switch").error("<Cmd>ImSwitchSet requires one argument `imname`.")
      require("im_switch").help()
      return
    end
    local imname = opts.fargs[1]
    require("im_switch").ImSwitchSet(imname)
  end, { desc = "[im_switch.nvim] ImSwitchSet <imname>", nargs = 1 })

  vim.api.nvim_create_user_command("ImSwitchStatus", function(_)
    require("im_switch").ImSwitchStatus()
  end, { desc = "[im_switch.nvim] ImSwitchStatus" })
end

local function setup_vim_autocmds()
  local augroup = vim.api.nvim_create_augroup("ImSwitchGroup", { clear = true })
  vim.api.nvim_create_autocmd({ "ModeChanged" }, {
    group = augroup,
    pattern = "*:*",
    callback = function(_)
      require("im_switch.autocmds").on_mode_changed()
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = augroup,
    pattern = "*",
    callback = function(_)
      require("im_switch.autocmds").on_buf_enter()
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = augroup,
    callback = function(event)
      require("im_switch.state_manager").cleanup_buffer(event.buf)
    end,
  })
end

local function check_valid_os()
  if os.getenv("SSH_TTY") ~= nil then
    lib.error("You are in a ssh session. This plugin does not work over ssh. Abort.")
    return false
  end

  local os_name = vim.loop.os_uname().sysname
  if os_name ~= "Linux" and os_name ~= "Unix" then
    lib.error(string.format("Unsupported OS: %s. This plugin only works on Linux/Unix.", os_name))
    return false
  end

  if os.getenv("DISPLAY") == nil and os.getenv("WAYLAND_DISPLAY") == nil then
    lib.error("Cannot detect your display (DISPLAY or WAYLAND_DISPLAY). Abort.")
    return false
  end

  return true
end

---setup function, call on setup
---@param opts im_switch.Config look config for details
M.setup = function(opts)
  config.set_options(opts)

  if not check_valid_os() then
    return
  end

  local backend = require("im_switch.backend")
  if not backend.init() then
    lib.error("Failed to initialize backend. Plugin will not function properly.")
    return
  end

  setup_vim_commands()
  setup_vim_autocmds()

  lib.info("im_switch.nvim setup complete")
end

return M
