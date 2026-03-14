-- Test the plugin in actual Neovim environment
-- Run with: nvim -u examples/test_in_neovim.lua

-- Minimal init for testing
vim.o.runtimepath = vim.o.runtimepath .. ',/home/dengzt/data/repo/input/im_switch.nvim'

-- Setup the plugin
vim.cmd([[
  lua <<EOF
local package_path = '/home/dengzt/.luarocks/share/lua/5.1/?.lua;'
package.path = package_path .. package.path

local im_switch = require('im_switch')

print("=== Testing im_switch.nvim in Neovim ===\n")

-- Test 1: Setup
print("1. Testing setup...")
local ok = im_switch.setup({
  imname = {
    norm = 'keyboard-us',
    ins = 'rime',
    cmd = 'keyboard-us'
  },
  enable_rime_memory = true,
  log_level = 'info'
})

if ok then
  print("   ✓ Setup successful\n")
else
  print("   ✗ Setup failed\n")
  return
end

-- Test 2: Get current IM
print("2. Testing get_current_im()...")
local backend = require('im_switch.backend')
local current_im = backend.get_current_im()
if current_im then
  print("   ✓ Current IM: " .. current_im .. "\n")
else
  print("   ✗ Failed to get current IM\n")
end

-- Test 3: Get Rime ascii_mode
print("3. Testing get_rime_ascii_mode()...")
local rime_mode = backend.get_rime_ascii_mode()
if rime_mode ~= nil then
  local mode_str = rime_mode and "英文" or "中文"
  print("   ✓ Rime ascii_mode: " .. mode_str .. "\n")
else
  print("   ⚠ Rime ascii_mode not available\n")
end

-- Test 4: Get Rime cache info
print("4. Testing get_rime_cache_info()...")
local cache_info = backend.get_rime_cache_info()
if cache_info then
  print("   ✓ Cache info:")
  print("     - cached: " .. tostring(cache_info.cached))
  print("     - value: " .. tostring(cache_info.value))
  print("     - ttl_ms: " .. tostring(cache_info.ttl_ms))
  print("     - valid: " .. tostring(cache_info.valid) .. "\n")
else
  print("   ⚠ Cache info not available\n")
end

-- Test 5: Switch IM
print("5. Testing switch_to_im()...")
local switch_ok = backend.switch_to_im('rime')
if switch_ok then
  print("   ✓ Switched to rime\n")
else
  print("   ✗ Failed to switch to rime\n")
end

print("=== All tests completed ===")
EOF
]])

-- Quit after tests
vim.cmd('qa')
