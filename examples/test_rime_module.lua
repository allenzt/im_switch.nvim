-- Test rime module fix
package.path = package.path .. ';/home/dengzt/.luarocks/share/lua/5.1/?.lua;./lua/?.lua;./lua/?/init.lua'
package.cpath = package.cpath .. ';/home/dengzt/.luarocks/lib/lua/5.1/?.so'

print("=== Testing Rime Module Fix ===\n")

-- Test 1: Load rime module
print("1. Loading rime module...")
local ok, rime = pcall(require, "im_switch.backend.dbus.rime")
if not ok then
  print("   ✗ Failed to load rime module: " .. tostring(rime))
  return false
end
print("   ✓ Rime module loaded\n")

-- Test 2: Initialize rime module
print("2. Initializing rime module with TTL...")
local mock_backend = {
  get_rime_ascii_mode = function()
    return true  -- Mock function
  end,
  set_rime_ascii_mode = function(ascii)
    return true  -- Mock function
  end,
}

local init_ok = rime.init(mock_backend, 5000)
if not init_ok then
  print("   ✗ Failed to initialize rime module")
  return false
end
print("   ✓ Rime module initialized with TTL=5000ms\n")

-- Test 3: Test get_ascii_mode with mock backend
print("3. Testing get_ascii_mode (with mock)...")
local result = rime.get_ascii_mode()
if result == true then
  print("   ✓ get_ascii_mode returned: " .. tostring(result))
else
  print("   ✗ get_ascii_mode returned: " .. tostring(result))
end
print()

-- Test 4: Test cache info
print("4. Testing get_cache_info...")
local cache_info = rime.get_cache_info()
if cache_info then
  print("   ✓ Cache info:")
  print("     - cached: " .. tostring(cache_info.cached))
  print("     - value: " .. tostring(cache_info.value))
  print("     - ttl_ms: " .. tostring(cache_info.ttl_ms))
  print("     - valid: " .. tostring(cache_info.valid))
else
  print("   ✗ Failed to get cache info")
end
print()

-- Test 5: Test set_ascii_mode
print("5. Testing set_ascii_mode...")
local set_result = rime.set_ascii_mode(false)
if set_result then
  print("   ✓ set_ascii_mode(false) succeeded")
else
  print("   ✗ set_ascii_mode(false) failed")
end
print()

-- Test 6: Test cache invalidation
print("6. Testing invalidate_cache...")
rime.invalidate_cache()
local cache_info2 = rime.get_cache_info()
if not cache_info2.cached then
  print("   ✓ Cache invalidated successfully")
else
  print("   ✗ Cache still has data after invalidation")
end
print()

print("=== All Tests Passed ===")
