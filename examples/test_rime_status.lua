-- Test Rime status specifically
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

  -- Test GetProperty
  local GLib = lgi.require("GLib")
  local variant = GLib.Variant("(s)", {"ascii_mode"})

  local ok, result = pcall(function()
    return rime_proxy:call_sync("GetProperty", variant, Gio.DBusCallFlags.NONE, -1)
  end)

  if ok then
    print("GetProperty call succeeded")
    print("Result type: " .. type(result))

    if type(result) == "userdata" then
      print("Is GLib.Variant: " .. tostring(result))
      local child_ok, child = pcall(function()
        return result:get_child_value(0)
      end)

      if child_ok then
        print("Child type: " .. type(child))
        print("Child: " .. tostring(child))

        local bool_ok, value = pcall(function()
          return child:get_boolean()
        end)

        if bool_ok then
          print("Boolean value: " .. tostring(value))
        else
          print("get_boolean failed: " .. tostring(value))
        end
      else
        print("get_child_value failed: " .. tostring(child))
      end
    elseif type(result) == "table" then
      print("Table result: " .. vim.inspect(result))
    end
  else
    print("GetProperty failed: " .. tostring(result))
  end
else
  print("Rime proxy not available")
end
