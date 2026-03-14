-- Simple test for lgi GLib.Variant fix
-- Run with: nvim -u NONE -l test_lgi_fix.lua

local function test_variant_unwrap()
  print("=== Testing GLib.Variant Unwrap ===\n")

  -- Check lgi
  local ok, lgi = pcall(require, "lgi")
  if not ok then
    print("✗ lgi not available")
    return false
  end

  print("✓ lgi loaded")

  -- Create a variant similar to what D-Bus returns
  local GLib = lgi.require("GLib")
  local variant = GLib.Variant("(s)", {"rime"})

  print("✓ Created test variant: " .. tostring(variant))
  print("  Type: " .. type(variant))

  -- Test unwrapping
  local unwrap_ok, value = pcall(function()
    local child = variant:get_child_value(0)
    return child:get_string()
  end)

  if unwrap_ok then
    print("✓ Successfully unwrapped variant")
    print("  Value: " .. tostring(value))

    if value == "rime" then
      print("\n✓ Test PASSED: Variant unwrap works correctly!\n")
      return true
    else
      print("\n✗ Test FAILED: Expected 'rime', got '" .. tostring(value) .. "'\n")
      return false
    end
  else
    print("✗ Failed to unwrap variant: " .. tostring(value))
    return false
  end
end

local function test_dbus_call()
  print("\n=== Testing Actual D-Bus Call ===\n")

  local ok, lgi = pcall(require, "lgi")
  if not ok then
    print("✗ lgi not available")
    return false
  end

  local Gio = lgi.require("Gio")

  -- Create proxy
  local bus = Gio.bus_get_sync(Gio.BusType.SESSION)
  if not bus then
    print("✗ Failed to get D-Bus bus")
    return false
  end

  print("✓ D-Bus bus connected")

  local proxy_ok, proxy = pcall(function()
    return Gio.DBusProxy.new_sync(
      bus,
      Gio.DBusProxyFlags.NONE,
      nil,
      "org.fcitx.Fcitx5",
      "/controller",
      "org.fcitx.Fcitx.Controller1",
      nil
    )
  end)

  if not proxy_ok then
    print("✗ Failed to create proxy: " .. tostring(proxy))
    return false
  end

  print("✓ Proxy created")

  -- Call CurrentInputMethod
  local call_ok, result = pcall(function()
    return proxy:call_sync("CurrentInputMethod", nil, Gio.DBusCallFlags.NONE, -1)
  end)

  if not call_ok then
    print("✗ Call failed: " .. tostring(result))
    return false
  end

  print("✓ CurrentInputMethod called")
  print("  Result type: " .. type(result))

  -- Try to unwrap
  local imname = nil
  local result_type = type(result)

  if result_type == "userdata" then
    local unwrap_ok, value = pcall(function()
      local child = result:get_child_value(0)
      return child:get_string()
    end)
    if unwrap_ok then
      imname = value
      print("✓ Unwrapped GLib.Variant userdata")
    end
  elseif result_type == "table" then
    if result.value and result.value[1] then
      imname = result.value[1]
    elseif result[1] then
      imname = result[1]
    end
    print("✓ Extracted from table")
  elseif result_type == "string" then
    imname = result
    print("✓ Direct string value")
  end

  if imname then
    print("  Current IM: " .. tostring(imname))
    print("\n✓ D-Bus Test PASSED!\n")
    return true
  else
    print("✗ Failed to extract IM name\n")
    return false
  end
end

-- Run tests
local test1 = test_variant_unwrap()
local test2 = test_dbus_call()

if test1 and test2 then
  print("=== All Tests PASSED ===")
else
  print("=== Some Tests FAILED ===")
end
