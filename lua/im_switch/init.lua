local lib = require("im_switch.lib")
local config = require("im_switch.config")
local commands = require("im_switch.commands")

local M = vim.tbl_deep_extend("force", {}, lib, config, commands)

local function setup_vim_commands()
  lib.info("Setting up vim commands.")

  vim.api.nvim_create_user_command("ImSwitch", function(_)
    require("im_switch").help()
  end, { desc = "[im_switch.nvim] ImSwitch help" })

  vim.api.nvim_create_user_command("ImSwitchSetName", function(opts)
    if #opts.fargs < 1 then
      require("im_switch").error("<Cmd>ImSwitchSetName requires one argument `imname`.")
      require("im_switch").help()
      return
    end
    local imname = opts.fargs[1]
    require("im_switch").ImSwitchSetName(imname)
  end, { desc = "[im_switch.nvim] ImSwitchSetName <imname>", nargs = 1 })

  vim.api.nvim_create_user_command("ImSwitchGeneious", function(_)
    require("im_switch").ImSwitchGeneious()
  end, { desc = "[im_switch.nvim] ImSwitchGeneious" })

  vim.api.nvim_create_user_command("ImSwitchOnModeChanged", function(_)
    require("im_switch").ImSwitchOnModeChanged()
  end, { desc = "[im_switch.nvim] ImSwitchOnModeChanged" })

  vim.api.nvim_create_user_command("ImSwitchSetPrior", function(opts)
    local mode, imname
    if #opts.fargs == 1 then
      mode, imname = nil, opts.fargs[1]
    elseif #opts.fargs == 2 then
      mode, imname = opts.fargs[2], opts.fargs[1]
    else
      require("im_switch").error("<Cmd>ImSwitchSetPrior requires one or two arguments `imname` `mode?`.")
      require("im_switch").help()
      return
    end
    require("im_switch").ImSwitchSetPrior(mode, imname)
  end, { desc = "[im_switch.nvim] ImSwitchSetPrior", nargs = "*" })

  vim.api.nvim_create_user_command("ImSwitchGetImname", function(opts)
    local mode = #opts.fargs >= 1 and opts.fargs[1] or nil
    local result = require("im_switch").ImSwitchGetImname(mode)
    print(result)
    return result
  end, { desc = "[im_switch.nvim] ImSwitchGetImname <mode>", nargs = "?" })

  vim.api.nvim_create_user_command("ImSwitchGetImnames", function(_)
    local result = require("im_switch").ImSwitchGetImnames()
    vim.pretty_print(result)
    return result
  end, { desc = "[im_switch.nvim] ImSwitchGetImnames" })
end

local function setup_vim_autocmds()
  lib.info("Setting vim autocommands.")
  local augroup = vim.api.nvim_create_augroup("ImSwitchGroup", { clear = true })
  vim.api.nvim_create_autocmd({ "ModeChanged" }, {
    group = augroup,
    pattern = "*:*",
    callback = function(_)
      require("im_switch").ImSwitchOnModeChanged()
    end
  })
end

local function check_valid_os()
  if vim.fn.executable('fcitx5-remote') == 1 then
    lib.info("fcitx5-remote found.")
    return true
  else
    lib.warn("`fcitx5-remote` not found. Abort.")
    return false
  end

  if os.getenv('SSH_TTY') ~= nil then
    lib.error("You are in a ssh session. This plugin does not work over ssh. Abort.")
    return false
  end

  local os_name = vim.loop.os_uname().sysname
  if (os_name == 'Linux' or os_name == 'Unix') and os.getenv('DISPLAY') == nil and os.getenv('WAYLAND_DISPLAY') == nil then
    lib.error("Cannot detect your display. Abort.")
    return false
  end

  return false
end

---setup function, call on setup
---@param opts im_switch.Config look config for details
M.setup = function(opts)
  config.set_options(opts)

  if not check_valid_os() then
    lib.info("check_valid_os failed. Returning without doing anything.")
    return
  end

  -- Initialize backend
  local backend = require("im_switch.backend")
  if not backend.init() then
    lib.error("Failed to initialize backend. Plugin will not function properly.")
    return
  end

  setup_vim_commands()

  if config.define_autocmd then
    setup_vim_autocmds()
  end

  -- Initial mode setup
  if vim.v.event.new_mode ~= nil then
    commands.ImSwitchOnModeChanged()
  else
    commands.ImSwitchGeneious()
  end

  if config.msg ~= nil then
    lib.echo(config.msg)
  end

  lib.info("im_switch.nvim setup complete")
end

return M
