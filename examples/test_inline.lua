-- Quick inline test for im_switch
vim.cmd('set runtimepath+=.')

-- Add luarocks path BEFORE requiring any modules
package.path = '/home/dengzt/.luarocks/share/lua/5.1/?.lua;' .. package.path
package.cpath = '/home/dengzt/.luarocks/lib/lua/5.1/?.so;' .. package.cpath

-- Setup and test
print('=== im_switch.nvim Test ===\n')

print('1. Setup...')
local im_switch = require('im_switch')
im_switch.setup({
  imname = {
    norm = 'rime',    -- Normal mode: 使用 rime 英文模式
    ins = 'rime',     -- Insert mode: 使用 rime (恢复中英文状态)
    cmd = 'rime',     -- Command mode: 使用 rime 英文模式
  },
  enable_rime_memory = true,
  log_level = 'info'
})
print('   ✓ Setup complete\n')

print('2. Testing backend...')
local backend = require('im_switch.backend')

print('3. Getting current IM...')
local current_im = backend.get_current_im()
print('   Current IM: ' .. (current_im or 'nil'))

print('4. Getting Rime ascii_mode...')
local rime_mode = backend.get_rime_ascii_mode()
if rime_mode ~= nil then
  local mode_str = rime_mode and 'true' or 'false'
  print('   Rime ascii_mode: ' .. mode_str)
else
  print('   Rime ascii_mode: nil (not supported)')
end

print('5. Getting cache info...')
local cache_info = backend.get_rime_cache_info()
if cache_info then
  print('   Cache TTL: ' .. cache_info.ttl_ms .. 'ms')
  print('   Cache valid: ' .. (cache_info.valid and 'yes' or 'no'))
else
  print('   Cache info: nil (not supported)')
end

print('\n=== Test Complete ===')
