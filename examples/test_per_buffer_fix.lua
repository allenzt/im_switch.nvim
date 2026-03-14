-- Test suite for per-buffer state memory fix
-- Tests:
-- 1. Insert mode state saving (Normal mode is always English, no need to save)
-- 2. Multi-buffer state isolation
-- 3. Mode state retrieval

local M = {}

local state_manager = require("im_switch.state_manager")
local config = require("im_switch.config")

-- Test helper function
local function assert_equal(actual, expected, test_name)
  if actual == expected then
    print(string.format("✅ PASS: %s", test_name))
    return true
  else
    print(string.format("❌ FAIL: %s (expected: %s, got: %s)", test_name, tostring(expected), tostring(actual)))
    return false
  end
end

-- Test 1: Insert mode state saving
M.test_insert_mode_saving = function()
  print("\n=== Test 1: Insert mode state saving ===")

  -- Reset buffer state
  state_manager.buffer_state = {}

  -- Save Insert mode state (Chinese)
  state_manager.save_buffer_state(1, "ins", "rime", false)

  -- Verify Insert mode state was saved
  local ins_state = state_manager.get_buffer_state(1, "ins")
  local passed = assert_equal(ins_state ~= nil, true, "Insert mode state should be saved")
  passed = assert_equal(ins_state.im, "rime", "IM should be rime") and passed
  passed = assert_equal(ins_state.rime_ascii, false, "Rime should be in Chinese mode") and passed

  -- Note: Normal mode state is NOT saved (always English)
  local norm_state = state_manager.get_buffer_state(1, "norm")
  passed = assert_equal(norm_state, nil, "Normal mode state should NOT be saved (always English)") and passed

  return passed
end

-- Test 2: Multi-buffer state isolation
M.test_multi_buffer_isolation = function()
  print("\n=== Test 2: Multi-buffer state isolation ===")

  -- Reset buffer state
  state_manager.buffer_state = {}

  -- Save different states for different buffers
  state_manager.save_buffer_state(1, "ins", "rime", false)  -- Buffer 1: Chinese
  state_manager.save_buffer_state(2, "ins", "rime", true)   -- Buffer 2: English

  local passed = true

  -- Verify buffer 1 Insert mode state
  local buf1_ins = state_manager.get_buffer_state(1, "ins")
  passed = assert_equal(buf1_ins ~= nil, true, "Buffer 1 Insert state should exist") and passed
  passed = assert_equal(buf1_ins.rime_ascii, false, "Buffer 1 Insert should be Chinese") and passed

  -- Verify buffer 2 Insert mode state
  local buf2_ins = state_manager.get_buffer_state(2, "ins")
  passed = assert_equal(buf2_ins ~= nil, true, "Buffer 2 Insert state should exist") and passed
  passed = assert_equal(buf2_ins.rime_ascii, true, "Buffer 2 Insert should be English") and passed

  -- Verify buffers are isolated
  passed = assert_equal(buf1_ins.rime_ascii ~= buf2_ins.rime_ascii, true, "Buffer states should be isolated") and passed

  return passed
end

-- Test 3: get_prior_im
M.test_prior_im = function()
  print("\n=== Test 3: get_prior_im ===")

  -- Reset buffer state
  state_manager.buffer_state = {}

  -- Without buffer state, should use config
  local prior_im = state_manager.get_prior_im("ins")
  local passed = assert_equal(prior_im, config.imname.ins, "Should use config when buffer state is empty")

  -- With buffer state, should use buffer state
  state_manager.save_buffer_state(1, "ins", "rime", false)
  local prior_im_with_state = state_manager.get_prior_im("ins")
  passed = assert_equal(prior_im_with_state, "rime", "Should use buffer state when available") and passed

  return passed
end

-- Test 4: Buffer cleanup
M.test_buffer_cleanup = function()
  print("\n=== Test 4: Buffer cleanup ===")

  -- Save buffer state
  state_manager.save_buffer_state(1, "ins", "rime", false)

  -- Verify state exists
  local state_before = state_manager.get_buffer_state(1, "ins")
  local passed = assert_equal(state_before ~= nil, true, "State should exist before cleanup")

  -- Cleanup buffer
  state_manager.cleanup_buffer(1)

  -- Verify state is cleaned up
  local state_after = state_manager.get_buffer_state(1, "ins")
  passed = assert_equal(state_after, nil, "State should be nil after cleanup") and passed

  return passed
end

-- Run all tests
M.run_all = function()
  print("🧪 Running per-buffer state memory fix tests...")
  print("Configuration: enable_rime_memory = " .. tostring(config.enable_rime_memory))
  print("Note: Normal/Command modes are always in English state, no need to save their state")

  local results = {
    M.test_insert_mode_saving(),
    M.test_multi_buffer_isolation(),
    M.test_prior_im(),
    M.test_buffer_cleanup(),
  }

  local passed = 0
  for _, result in ipairs(results) do
    if result then passed = passed + 1 end
  end

  print(string.format("\n📊 Test Results: %d/%d passed", passed, #results))

  if passed == #results then
    print("✅ All tests passed!")
  else
    print("❌ Some tests failed. Please review the implementation.")
  end
end

return M
