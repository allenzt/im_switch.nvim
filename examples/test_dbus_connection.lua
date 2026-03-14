-- Test script to verify D-Bus connection to fcitx5
-- Run with: nvim -u NONE -l test_dbus_connection.lua

local function test_dbus()
  print("=== Testing fcitx5 D-Bus Connection ===\n")

  -- Test 1: Check if fcitx5 is running
  print("1. Checking if fcitx5 is running...")
  local handle = io.popen("pgrep -x fcitx5 > /dev/null && echo 'Running' || echo 'Not running'")
  local result = handle:read("*a")
  handle:close()
  print("   fcitx5 status: " .. result)

  -- Test 2: Check if D-Bus session is available
  print("\n2. Checking D-Bus session bus...")
  local session_bus = os.getenv("DBUS_SESSION_BUS_ADDRESS")
  if session_bus then
    print("   DBUS_SESSION_BUS_ADDRESS: " .. session_bus)
  else
    print("   WARNING: DBUS_SESSION_BUS_ADDRESS not set")
  end

  -- Test 3: Try to list fcitx5 D-Bus services
  print("\n3. Checking fcitx5 D-Bus services...")
  handle = io.popen("gdbus list --session | grep -i fcitx || echo 'No fcitx5 services found'")
  result = handle:read("*a")
  handle:close()
  print("   D-Bus services:\n" .. result)

  -- Test 4: Try to call fcitx5 via gdbus
  print("\n4. Testing direct D-Bus call to fcitx5...")
  handle = io.popen("gdbus call --session --dest org.fcitx.Fcitx5 --object-path /controller --method org.fcitx.Fcitx.Controller1.CurrentInputMethod 2>&1")
  result = handle:read("*a")
  handle:close()
  print("   Current IM: " .. result)

  -- Test 5: Check lgi availability
  print("\n5. Checking lgi Lua module...")
  local ok, lgi = pcall(require, "lgi")
  if ok then
    print("   ✓ lgi module is available")
    local Gio = lgi.require("Gio")
    print("   ✓ Gio module loaded")

    -- Try to create proxy
    local bus = Gio.bus_get_sync(Gio.BusType.SESSION)
    if bus then
      print("   ✓ D-Bus session bus connected")

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

      if proxy_ok then
        print("   ✓ fcitx5 proxy created")

        local call_ok, call_result = pcall(function()
          return proxy:call_sync("CurrentInputMethod", nil, Gio.DBusCallFlags.NONE, -1)
        end)

        if call_ok then
          print("   ✓ CurrentInputMethod called successfully")
          print("   Result type: " .. type(call_result))
          print("   Result value: " .. vim.inspect(call_result))

          if call_result then
            local imname = nil
            local result_type = type(call_result)

            if result_type == "userdata" then
              -- GLib.Variant object - need to unwrap it
              local ok, value = pcall(function()
                local child = call_result:get_child_value(0)
                return child:get_string()
              end)
              if ok then
                imname = value
              end
            elseif result_type == "table" then
              if call_result.value and call_result.value[1] then
                imname = call_result.value[1]
              elseif call_result[1] then
                imname = call_result[1]
              end
            elseif result_type == "string" then
              imname = call_result
            end

            if imname then
              print("   ✓ Current IM: " .. tostring(imname))
            end
          end
        else
          print("   ✗ CurrentInputMethod call failed: " .. tostring(call_result))
        end
      else
        print("   ✗ Failed to create proxy: " .. tostring(proxy))
      end
    else
      print("   ✗ Failed to connect to D-Bus session bus")
    end
  else
    print("   ✗ lgi module not available")
    print("   Install with: luarocks --local install lgi")
  end

  print("\n=== Test Complete ===")
end

test_dbus()
