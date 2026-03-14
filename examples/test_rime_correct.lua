-- Test Rime status with correct methods
package.path = package.path .. ';/home/dengzt/.luarocks/share/lua/5.1/?.lua'
package.cpath = package.cpath .. ';/home/dengzt/.luarocks/lib/lua/5.1/?.so'

local lgi = require("lgi")
local Gio = lgi.require("Gio")

-- Create bus and proxy
local bus = Gio.bus_get_sync(Gio.BusType.SESSION)
local rime_proxy = Gio.DBusProxy.new_sync(
  bus,
  Gio.DBusProxyFlags.NONE,
  nil,
  "org.fcitx.Fcitx5",
  "/rime",
  "org.fcitx.Fcitx.Rime1",
  nil
)

if rime_proxy then
  print("Rime proxy created successfully")

  -- Test IsAsciiMode
  local ok, result = pcall(function()
    return rime_proxy:call_sync("IsAsciiMode", nil, Gio.DBusCallFlags.NONE, -1)
  end)

  if ok then
    print("IsAsciiMode call succeeded")
    print("Result type: " .. type(result))
    print("Result: " .. tostring(result))

    if type(result) == "userdata" then
      local unwrap_ok, value = pcall(function()
        local child = result:get_child_value(0)
        return child:get_boolean()
      end)
      if unwrap_ok then
        print("Unwrapped value: " .. tostring(value))
      else
        print("Unwrap failed: " .. tostring(value))
      end
    end
  else
    print("IsAsciiMode failed: " .. tostring(result))
  end

  print("")

  -- Test SetAsciiMode
  local set_ok, set_result = pcall(function()
    local GLib = lgi.require("GLib")
    local variant = GLib.Variant("(b)", {true})
    return rime_proxy:call_sync("SetAsciiMode", variant, Gio.DBusCallFlags.NONE, -1)
  end)

  if set_ok then
    print("SetAsciiMode(true) succeeded")
  else
    print("SetAsciiMode failed: " .. tostring(set_result))
  end
else
  print("Rime proxy not available")
end
