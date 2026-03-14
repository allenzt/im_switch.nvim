-- ============================================================================
-- im_switch.nvim test runner
-- Run: cd /path/to/im_switch.nvim && nvim --headless -u NONE -c 'luafile tests/run.lua' -c 'qa!'
-- ============================================================================

local plugin_root = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":p:h:h")
package.path = plugin_root .. "/lua/?.lua;" .. plugin_root .. "/lua/?/init.lua;" .. package.path

-- ============================================================================
-- Test framework
-- ============================================================================
local results = { passed = 0, failed = 0, errors = {} }

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s\n  expected: %s\n  actual:   %s",
      msg or "assert_eq failed",
      vim.inspect(expected),
      vim.inspect(actual)))
  end
end

local function assert_true(value, msg)
  if value ~= true then
    error(string.format("%s\n  expected true, got: %s",
      msg or "assert_true failed",
      vim.inspect(value)))
  end
end

local function assert_false(value, msg)
  if value ~= false then
    error(string.format("%s\n  expected false, got: %s",
      msg or "assert_false failed",
      vim.inspect(value)))
  end
end

local function assert_nil(value, msg)
  if value ~= nil then
    error(string.format("%s\n  expected nil, got: %s",
      msg or "assert_nil failed",
      vim.inspect(value)))
  end
end

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    results.passed = results.passed + 1
    print("  PASS  " .. name)
  else
    results.failed = results.failed + 1
    table.insert(results.errors, { name = name, err = err })
    print("  FAIL  " .. name)
    for line in err:gmatch("[^\n]+") do
      print("        " .. line)
    end
  end
end

-- ============================================================================
-- Mock vim APIs
-- ============================================================================
local _test_bufnr = 1
local _test_time = 1000
local _test_mode = "n"
local _event = {}

vim.api.nvim_get_current_buf = function() return _test_bufnr end
vim.api.nvim_get_mode = function() return { mode = _test_mode, blocking = false } end
vim.fn.reg_executing = function() return "" end
vim.loop.now = function() return _test_time end

setmetatable(vim.v, {
  __index = function(t, k)
    if k == "event" then return _event end
    return rawget(t, k)
  end,
  __newindex = function(t, k, v)
    if k == "event" then _event = v return end
    rawset(t, k, v)
  end,
})

-- ============================================================================
-- Mock backend (pre-declare local to allow self-reference in closures)
-- ============================================================================
local mock_backend
mock_backend = {
  name = "mock",
  current_im = "rime",
  ascii_mode = false,
  switch_calls = {},
  set_ascii_calls = {},
  get_im_calls = 0,
  get_ascii_calls = 0,
}

function mock_backend.reset()
  mock_backend.current_im = "rime"
  mock_backend.ascii_mode = false
  mock_backend.switch_calls = {}
  mock_backend.set_ascii_calls = {}
  mock_backend.get_im_calls = 0
  mock_backend.get_ascii_calls = 0
end

function mock_backend.get_current_im()
  mock_backend.get_im_calls = mock_backend.get_im_calls + 1
  return mock_backend.current_im
end

function mock_backend.get_rime_ascii_mode()
  mock_backend.get_ascii_calls = mock_backend.get_ascii_calls + 1
  return mock_backend.ascii_mode
end

function mock_backend.switch_to_im(name)
  table.insert(mock_backend.switch_calls, name)
  mock_backend.current_im = name
  return true
end

function mock_backend.set_rime_ascii_mode(ascii)
  if mock_backend.ascii_mode == ascii then
    return true
  end
  table.insert(mock_backend.set_ascii_calls, ascii)
  mock_backend.ascii_mode = ascii
  return true
end

-- ============================================================================
-- Mock config & lib
-- ============================================================================
local mock_config = {
  imname = { norm = "rime", ins = "rime", cmd = "rime" },
  enable_state_memory = true,
  log_level = "warn",
  rime_state_cache_ttl = 5000,
}

local mock_lib = {
  info = function() end,
  warn = function() end,
  error = function(msg) error(msg) end,
  plugin_name = "test",
  plugin_icon = "",
  plugin_commands = {},
  help = function() end,
  echo = function() end,
  safe_cmd = function(cmd, err) return pcall(vim.cmd, cmd) end,
}

package.loaded["im_switch.config"] = mock_config
package.loaded["im_switch.lib"] = mock_lib
package.loaded["im_switch.backend"] = nil

-- ============================================================================
-- Mock drivers registry
-- ============================================================================
local mock_drivers = { drivers = {} }
function mock_drivers.register(imname, driver)
  mock_drivers.drivers[imname] = driver
end
function mock_drivers.get(imname)
  return mock_drivers.drivers[imname]
end
function mock_drivers.has(imname)
  return mock_drivers.drivers[imname] ~= nil
end

-- Register mock rime driver wrapping mock_backend
mock_drivers.register("rime", {
  get_state = function()
    return mock_backend.get_rime_ascii_mode()
  end,
  set_state = function(state)
    return mock_backend.set_rime_ascii_mode(state)
  end,
  force_english = function()
    return mock_backend.set_rime_ascii_mode(true)
  end,
})

package.loaded["im_switch.drivers"] = mock_drivers
package.loaded["im_switch.drivers.rime"] = true

-- ============================================================================
-- Helper: reload modules under test
-- ============================================================================
local function reload(module_name)
  package.loaded[module_name] = nil
  return require(module_name)
end

local function reset_state()
  mock_backend.reset()
  _test_time = 1000
  _test_bufnr = 1
  _test_mode = "n"
  _event = {}
end

-- ============================================================================
-- Tests: state_manager
-- ============================================================================
print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("State Manager")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

local state_manager

test("get_mode_key maps i to ins", function()
  state_manager = reload("im_switch.state_manager")
  assert_eq(state_manager.get_mode_key("i"), "ins")
end)

test("get_mode_key maps n to norm", function()
  state_manager = reload("im_switch.state_manager")
  assert_eq(state_manager.get_mode_key("n"), "norm")
end)

test("get_mode_key maps c to cmd", function()
  state_manager = reload("im_switch.state_manager")
  assert_eq(state_manager.get_mode_key("c"), "cmd")
end)

test("save and get buffer state", function()
  state_manager = reload("im_switch.state_manager")
  state_manager.save_buffer_state(1, "ins", "rime", false)
  local st = state_manager.get_buffer_state(1, "ins")
  assert_eq(st.im, "rime")
  assert_false(st.im_state)
end)

test("get_prior_im prefers buffer state over config", function()
  state_manager = reload("im_switch.state_manager")
  state_manager.save_buffer_state(1, "ins", "keyboard-us", nil)
  local im = state_manager.get_prior_im("ins")
  assert_eq(im, "keyboard-us")
end)

test("get_prior_im falls back to config", function()
  state_manager = reload("im_switch.state_manager")
  state_manager.buffer_state = {}
  local im = state_manager.get_prior_im("ins")
  assert_eq(im, "rime")
end)

test("cleanup_buffer removes state", function()
  state_manager = reload("im_switch.state_manager")
  state_manager.save_buffer_state(1, "ins", "rime", false)
  state_manager.cleanup_buffer(1)
  assert_nil(state_manager.get_buffer_state(1, "ins"))
end)

-- ============================================================================
-- Tests: backend/init.lua (cache logic)
-- ============================================================================
print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("Backend (cache & short-circuit)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

local backend

test("switch_to_im skips when cache matches", function()
  package.loaded["im_switch.backend"] = nil
  backend = reload("im_switch.backend")
  backend.current_backend = mock_backend
  mock_backend.current_im = "rime"
  backend.switch_to_im("rime")
  assert_eq(#mock_backend.switch_calls, 0, "should not call backend.switch_to_im when cache matches")
end)

test("switch_to_im calls backend when cache expired", function()
  mock_backend.reset()
  package.loaded["im_switch.backend"] = nil
  backend = reload("im_switch.backend")
  backend.current_backend = mock_backend
  mock_backend.current_im = "rime"
  backend.switch_to_im("rime")  -- sets cache, queries backend once
  _test_time = 10000  -- cache expired (ttl=1000)
  backend.switch_to_im("rime")  -- queries backend again
  -- cache expired, queries backend, backend says current is "rime", still skips
  assert_eq(#mock_backend.switch_calls, 0, "backend query shows already rime")
  assert_eq(mock_backend.get_im_calls, 2, "should query backend twice (initial + expired)")
end)

test("switch_to_im calls backend when IM differs", function()
  package.loaded["im_switch.backend"] = nil
  backend = reload("im_switch.backend")
  backend.current_backend = mock_backend
  mock_backend.current_im = "keyboard-us"
  backend.switch_to_im("rime")
  assert_eq(#mock_backend.switch_calls, 1)
  assert_eq(mock_backend.switch_calls[1], "rime")
end)

test("set_rime_ascii_mode skips when current matches", function()
  package.loaded["im_switch.backend"] = nil
  backend = reload("im_switch.backend")
  backend.current_backend = mock_backend
  mock_backend.ascii_mode = true
  backend.set_rime_ascii_mode(true)
  assert_eq(#mock_backend.set_ascii_calls, 0, "should skip when already true")
end)

test("set_rime_ascii_mode calls backend when current differs", function()
  package.loaded["im_switch.backend"] = nil
  backend = reload("im_switch.backend")
  backend.current_backend = mock_backend
  mock_backend.ascii_mode = false
  backend.set_rime_ascii_mode(true)
  assert_eq(#mock_backend.set_ascii_calls, 1)
  assert_true(mock_backend.set_ascii_calls[1])
end)

-- ============================================================================
-- Tests: autocmds
-- ============================================================================
print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("Autocmds")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

local autocmds

test("skip niI->i sub-mode transition", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")
  _event = { old_mode = "niI", new_mode = "i" }
  autocmds.on_mode_changed()
  assert_eq(#mock_backend.switch_calls, 0, "sub-mode transition should be skipped")
end)

test("Insert English -> Normal skips set_rime_ascii_mode", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")

  mock_backend.current_im = "rime"
  mock_backend.ascii_mode = true

  _event = { old_mode = "i", new_mode = "n" }
  autocmds.on_mode_changed()

  -- Phase 1 saves: im="rime", ascii=true
  local st = state_manager.get_buffer_state(1, "ins")
  assert_eq(st.im, "rime")
  assert_true(st.im_state)

  -- Phase 4: should skip because Insert was English
  assert_eq(#mock_backend.set_ascii_calls, 0, "should skip forcing English when Insert was already English")
end)

test("Insert Chinese -> Normal forces English", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")

  mock_backend.current_im = "rime"
  mock_backend.ascii_mode = false

  _event = { old_mode = "i", new_mode = "n" }
  autocmds.on_mode_changed()

  local st = state_manager.get_buffer_state(1, "ins")
  assert_eq(st.im, "rime")
  assert_false(st.im_state)

  assert_eq(#mock_backend.set_ascii_calls, 1, "should force English when Insert was Chinese")
  assert_true(mock_backend.set_ascii_calls[1])
end)

test("Visual -> Normal forces English when not English", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")

  mock_backend.current_im = "rime"
  mock_backend.ascii_mode = false  -- simulate Chinese state

  _event = { old_mode = "v", new_mode = "n" }
  autocmds.on_mode_changed()

  -- old_mode is not "ins", we don't know current state -> backend queries and sets
  assert_eq(#mock_backend.set_ascii_calls, 1, "Visual->Normal should force English when current is Chinese")
  assert_true(mock_backend.set_ascii_calls[1])
end)

test("Normal -> Insert restores Chinese state", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")

  -- First: Insert Chinese -> Normal (saves Chinese state)
  mock_backend.current_im = "rime"
  mock_backend.ascii_mode = false
  _event = { old_mode = "i", new_mode = "n" }
  autocmds.on_mode_changed()
  assert_eq(#mock_backend.set_ascii_calls, 1)

  -- Then: Normal -> Insert (should restore Chinese)
  mock_backend.set_ascii_calls = {}  -- reset
  _event = { old_mode = "n", new_mode = "i" }
  autocmds.on_mode_changed()

  assert_eq(#mock_backend.set_ascii_calls, 1, "should restore Chinese state")
  assert_false(mock_backend.set_ascii_calls[1])
end)

test("Normal -> Insert restores English state (skip set)", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")

  -- First: Insert English -> Normal (saves English state)
  mock_backend.current_im = "rime"
  mock_backend.ascii_mode = true
  _event = { old_mode = "i", new_mode = "n" }
  autocmds.on_mode_changed()
  assert_eq(#mock_backend.set_ascii_calls, 0, "skip because Insert was English")

  -- Then: Normal -> Insert (should restore English)
  _event = { old_mode = "n", new_mode = "i" }
  autocmds.on_mode_changed()

  assert_eq(#mock_backend.set_ascii_calls, 0, "should skip restoring English (backend short-circuit)")
end)

test("multi-buffer isolation", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")

  -- Buffer 1: Insert Chinese -> Normal
  _test_bufnr = 1
  mock_backend.current_im = "rime"
  mock_backend.ascii_mode = false
  _event = { old_mode = "i", new_mode = "n" }
  autocmds.on_mode_changed()
  assert_eq(#mock_backend.set_ascii_calls, 1)

  -- Switch to buffer 2: Insert English -> Normal
  mock_backend.set_ascii_calls = {}
  _test_bufnr = 2
  mock_backend.ascii_mode = true
  _event = { old_mode = "i", new_mode = "n" }
  autocmds.on_mode_changed()
  assert_eq(#mock_backend.set_ascii_calls, 0, "buffer 2 Insert was English, should skip")

  -- Switch back to buffer 1: Normal -> Insert (should restore Chinese)
  mock_backend.set_ascii_calls = {}
  _test_bufnr = 1
  _event = { old_mode = "n", new_mode = "i" }
  autocmds.on_mode_changed()
  assert_eq(#mock_backend.set_ascii_calls, 1, "buffer 1 should restore Chinese")
  assert_false(mock_backend.set_ascii_calls[1])
end)

test("multi-buffer BufDelete cleanup", function()
  reset_state()
  state_manager = reload("im_switch.state_manager")

  -- Save state for buffers 1, 2, 3
  state_manager.save_buffer_state(1, "ins", "rime", false)
  state_manager.save_buffer_state(2, "ins", "rime", true)
  state_manager.save_buffer_state(3, "ins", "keyboard-us", nil)

  assert_true(state_manager.get_buffer_state(1, "ins") ~= nil)
  assert_true(state_manager.get_buffer_state(2, "ins") ~= nil)
  assert_true(state_manager.get_buffer_state(3, "ins") ~= nil)

  -- Delete buffer 2
  state_manager.cleanup_buffer(2)
  assert_nil(state_manager.get_buffer_state(2, "ins"))
  -- Others should remain
  assert_true(state_manager.get_buffer_state(1, "ins") ~= nil)
  assert_true(state_manager.get_buffer_state(3, "ins") ~= nil)

  -- Delete buffer 1
  state_manager.cleanup_buffer(1)
  assert_nil(state_manager.get_buffer_state(1, "ins"))
  assert_true(state_manager.get_buffer_state(3, "ins") ~= nil)
end)

test("multi-buffer new buffer has no prior state", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")

  -- Buffer 1: Insert Chinese -> Normal (saves state)
  _test_bufnr = 1
  mock_backend.current_im = "rime"
  mock_backend.ascii_mode = false
  _event = { old_mode = "i", new_mode = "n" }
  autocmds.on_mode_changed()
  assert_eq(#mock_backend.set_ascii_calls, 1)

  -- Switch to brand new buffer 99: Normal -> Insert
  -- No prior state, should just switch IM without restoring Rime state
  mock_backend.set_ascii_calls = {}
  _test_bufnr = 99
  _event = { old_mode = "n", new_mode = "i" }
  autocmds.on_mode_changed()
  assert_eq(#mock_backend.set_ascii_calls, 0, "new buffer has no saved Rime state to restore")
end)

test("multi-buffer different IMs per buffer", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")

  -- Buffer 1: user manually set to keyboard-us in Insert
  state_manager.save_buffer_state(1, "ins", "keyboard-us", nil)
  -- Buffer 2: user manually set to rime in Insert
  state_manager.save_buffer_state(2, "ins", "rime", false)

  -- Buffer 1 Normal -> Insert: should use keyboard-us (from buffer state)
  _test_bufnr = 1
  mock_backend.switch_calls = {}
  _event = { old_mode = "n", new_mode = "i" }
  autocmds.on_mode_changed()
  assert_eq(#mock_backend.switch_calls, 1, "buffer 1 should call switch_to_im once")
  assert_eq(mock_backend.switch_calls[1], "keyboard-us", "buffer 1 should restore keyboard-us")

  -- Buffer 2 Normal -> Insert: should use rime (from buffer state)
  -- 模拟 Normal 强制英文后的状态（ascii_mode=true），这样恢复中文才会触发 set
  mock_backend.ascii_mode = true
  _test_bufnr = 2
  mock_backend.switch_calls = {}
  mock_backend.set_ascii_calls = {}
  _event = { old_mode = "n", new_mode = "i" }
  autocmds.on_mode_changed()
  assert_eq(#mock_backend.switch_calls, 1, "buffer 2 should call switch_to_im once")
  assert_eq(mock_backend.switch_calls[1], "rime", "buffer 2 should restore rime")
  -- Rime should also restore Chinese state
  assert_eq(#mock_backend.set_ascii_calls, 1)
  assert_false(mock_backend.set_ascii_calls[1])
end)

test("non-rime IM switching with state memory", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")

  -- 配置为 pinyin/keyboard-us，都没有注册 driver
  mock_config.imname = { norm = "keyboard-us", ins = "pinyin", cmd = "keyboard-us" }

  -- Insert (pinyin) -> Normal: switch to keyboard-us, no driver for state memory
  mock_backend.current_im = "pinyin"
  mock_backend.ascii_mode = false
  _event = { old_mode = "i", new_mode = "n" }
  autocmds.on_mode_changed()

  assert_eq(#mock_backend.switch_calls, 1)
  assert_eq(mock_backend.switch_calls[1], "keyboard-us")
  -- No driver registered for keyboard-us, so no state operation
  assert_eq(#mock_backend.set_ascii_calls, 0)

  -- Normal (keyboard-us) -> Insert: switch to pinyin, no driver for state memory
  mock_backend.switch_calls = {}
  mock_backend.set_ascii_calls = {}
  _event = { old_mode = "n", new_mode = "i" }
  autocmds.on_mode_changed()

  assert_eq(#mock_backend.switch_calls, 1)
  assert_eq(mock_backend.switch_calls[1], "pinyin")
  -- No driver registered for pinyin, so no state operation
  assert_eq(#mock_backend.set_ascii_calls, 0)

  -- Restore config
  mock_config.imname = { norm = "rime", ins = "rime", cmd = "rime" }
end)

-- ============================================================================
-- Tests: BufEnter
-- ============================================================================
print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("BufEnter")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

test("BufEnter in Normal mode switches to norm IM and forces English", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")

  -- Simulate `nvim file.txt`: Normal mode, Rime in Chinese
  _test_mode = "n"
  mock_backend.current_im = "keyboard-us"
  mock_backend.ascii_mode = false

  autocmds.on_buf_enter()

  -- Should switch to config.imname.norm = "rime"
  assert_eq(#mock_backend.switch_calls, 1, "should switch to norm IM on BufEnter")
  assert_eq(mock_backend.switch_calls[1], "rime")
  -- Should force English via driver
  assert_eq(#mock_backend.set_ascii_calls, 1, "should force English on BufEnter in Normal")
  assert_true(mock_backend.set_ascii_calls[1])
end)

test("BufEnter in Insert mode restores saved state", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")

  -- Pre-save Chinese state for buffer 1
  state_manager.save_buffer_state(1, "ins", "rime", false)

  _test_mode = "i"
  mock_backend.current_im = "rime"
  mock_backend.ascii_mode = true

  autocmds.on_buf_enter()

  assert_eq(#mock_backend.switch_calls, 1, "should switch to ins IM on BufEnter")
  assert_eq(mock_backend.switch_calls[1], "rime")
  -- Should restore Chinese state
  assert_eq(#mock_backend.set_ascii_calls, 1, "should restore Chinese state on BufEnter in Insert")
  assert_false(mock_backend.set_ascii_calls[1])
end)

test("BufEnter with non-rime IM skips driver state", function()
  reset_state()
  package.loaded["im_switch.backend"] = mock_backend
  state_manager = reload("im_switch.state_manager")
  autocmds = reload("im_switch.autocmds")

  mock_config.imname = { norm = "keyboard-us", ins = "keyboard-us", cmd = "keyboard-us" }

  _test_mode = "n"
  mock_backend.current_im = "rime"
  mock_backend.ascii_mode = false

  autocmds.on_buf_enter()

  assert_eq(#mock_backend.switch_calls, 1)
  assert_eq(mock_backend.switch_calls[1], "keyboard-us")
  -- No driver for keyboard-us, no state operation
  assert_eq(#mock_backend.set_ascii_calls, 0)

  mock_config.imname = { norm = "rime", ins = "rime", cmd = "rime" }
end)

-- ============================================================================
-- Summary
-- ============================================================================
print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(string.format("Results: %d passed, %d failed", results.passed, results.failed))
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

if results.failed > 0 then
  print("\nFailed tests:")
  for _, err in ipairs(results.errors) do
    print("  - " .. err.name)
  end
  error(string.format("%d test(s) failed", results.failed))
else
  print("\nAll tests passed!")
end
