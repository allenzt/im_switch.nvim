-- ==========================================
-- im_switch.nvim Installation Test Script
-- ==========================================
-- Run this script in Neovim to verify your installation:
-- :luafile /path/to/im_switch.nvim/examples/test_installation.lua

local M = {}

-- Colors for output
local colors = {
  reset = "",
  red = "",
  green = "",
  yellow = "",
  blue = "",
}

-- Try to use ANSI colors if in terminal
if vim.fn.exists("&termguicolors") == 1 then
  colors = {
    reset = "\27[0m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
  }
end

-- Print a test result
local function print_result(test_name, success, message)
  local status = success and (colors.green .. "✓ PASS" .. colors.reset) or (colors.red .. "✗ FAIL" .. colors.reset)
  local msg = message and (" - " .. message) or ""
  print(string.format("%s: %s%s", test_name, status, msg))
end

-- Test 1: Check if plugin loads
M.test_plugin_load = function()
  local ok, plugin = pcall(require, "im_switch")
  print_result("Plugin Load", ok, ok and "im_switch.nvim loaded successfully" or tostring(plugin))
  return ok
end

-- Test 2: Check config
M.test_config = function()
  local ok, config = pcall(require, "im_switch.config")
  if not ok then
    print_result("Config Module", false, tostring(config))
    return false
  end

  print_result("Config Module", true, "config.lua loaded")
  print("  • remember_rime_state: " .. tostring(config.remember_rime_state))
  print("  • rime_state_method: " .. tostring(config.rime_state_method))
  print("  • rime_state_cache_ttl: " .. tostring(config.rime_state_cache_ttl))
  return true
end

-- Test 3: Check state manager
M.test_state_manager = function()
  local ok, state_manager = pcall(require, "im_switch.state_manager")
  if not ok then
    print_result("State Manager", false, tostring(state_manager))
    return false
  end

  print_result("State Manager", true, "state_manager.lua loaded")
  return true
end

-- Test 4: Check backend system
M.test_backend = function()
  local ok, backend = pcall(require, "im_switch.backend")
  if not ok then
    print_result("Backend System", false, tostring(backend))
    return false
  end

  print_result("Backend System", true, "backend/init.lua loaded")

  -- Test backend initialization
  local init_ok = backend.init()
  print_result("Backend Init", init_ok, init_ok and "Backend initialized successfully" or "No suitable backend found")

  if init_ok then
    local current_backend = backend.get_backend()
    if current_backend then
      print("  • Backend name: " .. tostring(current_backend.name or "unknown"))
    end
  end

  return init_ok
end

-- Test 5: Check fcitx5-remote
M.test_fcitx5_remote = function()
  local has_fcitx5_remote = vim.fn.executable("fcitx5-remote") == 1
  print_result("fcitx5-remote", has_fcitx5_remote,
    has_fcitx5_remote and "fcitx5-remote found" or "fcitx5-remote not found")
  return has_fcitx5_remote
end

-- Test 6: Check ldbus
M.test_ldbus = function()
  local ok, _ = pcall(require, "dbus.shared")
  print_result("ldbus", ok, ok and "ldbus available" or "ldbus not available")
  return ok
end

-- Test 7: Check lgi
M.test_lgi = function()
  local ok, _ = pcall(require, "lgi")
  print_result("lgi", ok, ok and "lgi available" or "lgi not available")
  return ok
end

-- Test 8: Check D-Bus backends
M.test_dbus_backends = function()
  print(colors.blue .. "D-Bus Backend Tests:" .. colors.reset)

  local ldbus_ok = M.test_ldbus()
  local lgi_ok = M.test_lgi()

  if ldbus_ok or lgi_ok then
    print_result("D-Bus Support", true, "At least one D-Bus backend available")
  else
    print_result("D-Bus Support", false, "No D-Bus backend available (Rime state memory disabled)")
  end
end

-- Test 9: Mode switching simulation
M.test_mode_switching = function()
  print(colors.blue .. "Mode Switching Tests:" .. colors.reset)

  local ok, state_manager = pcall(require, "im_switch.state_manager")
  if not ok then
    print_result("Mode Switching", false, "State manager not available")
    return false
  end

  -- Test mode key mapping
  local tests = {
    {char = "n", expected = "norm"},
    {char = "i", expected = "ins"},
    {char = "v", expected = "vis"},
    {char = "c", expected = "cmd"},
  }

  local all_ok = true
  for _, test in ipairs(tests) do
    local result = state_manager.get_mode_key(test.char)
    local test_ok = result == test.expected
    if not test_ok then
      all_ok = false
      print_result("Mode " .. test.char .. " → " .. test.expected, false, "Got: " .. tostring(result))
    end
  end

  if all_ok then
    print_result("Mode Mapping", true, "All mode mappings correct")
  end

  return all_ok
end

-- Run all tests
M.run_all = function()
  print(colors.blue .. "========================================" .. colors.reset)
  print(colors.blue .. "im_switch.nvim Installation Test" .. colors.reset)
  print(colors.blue .. "========================================" .. colors.reset)
  print()

  print(colors.blue .. "Basic Module Tests:" .. colors.reset)
  M.test_plugin_load()
  M.test_config()
  M.test_state_manager()

  print()
  print(colors.blue .. "Backend Tests:" .. colors.reset)
  M.test_fcitx5_remote()
  M.test_backend()

  print()
  M.test_dbus_backends()

  print()
  M.test_mode_switching()

  print()
  print(colors.blue .. "========================================" .. colors.reset)
  print(colors.blue .. "Test Complete!" .. colors.reset)
  print(colors.blue .. "========================================" .. colors.reset)
  print()

  -- Summary
  print(colors.yellow .. "Next Steps:" .. colors.reset)
  print("1. If all tests pass, the plugin is ready to use!")
  print("2. Add your configuration to init.lua")
  print("3. Restart Neovim")
  print("4. Try pressing 'i' to enter insert mode")
  print()

  return true
end

-- Run tests if executed directly
if vim.fn.expand("%:t") == "test_installation.lua" then
  M.run_all()
end

return M
