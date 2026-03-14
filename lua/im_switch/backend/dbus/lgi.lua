local lib = require("im_switch.lib")

local M = {
  name = "lgi",
  initialized = false,
  bus = nil,
  fcitx_proxy = nil,
  rime_proxy = nil,
}

---Initialize the lgi D-Bus backend
---@return boolean: true if successful
M.init = function()
  -- Try to require lgi
  local ok, lgi = pcall(require, "lgi")
  if not ok then
    lib.info("lgi not available")
    return false
  end

  -- Create D-Bus proxy objects
  local Gio = lgi.require("Gio")
  local bus_ok, bus = pcall(function()
    return Gio.bus_get_sync(Gio.BusType.SESSION)
  end)

  if not bus_ok then
    lib.error("Failed to create D-Bus session bus: " .. tostring(bus))
    return false
  end

  M.bus = bus

  -- Create fcitx5 controller proxy
  local fcitx_ok, fcitx_proxy = pcall(function()
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

  if not fcitx_ok then
    lib.error("Failed to create fcitx5 controller proxy: " .. tostring(fcitx_proxy))
    return false
  end

  M.fcitx_proxy = fcitx_proxy

  -- Try to create Rime proxy (optional)
  local rime_ok, rime_proxy = pcall(function()
    return Gio.DBusProxy.new_sync(
      bus,
      Gio.DBusProxyFlags.NONE,
      nil,
      "org.fcitx.Fcitx5",
      "/rime",
      "org.fcitx.Fcitx.Rime1",
      nil
    )
  end)

  if rime_ok then
    M.rime_proxy = rime_proxy
    lib.info("Rime proxy created successfully")
  else
    lib.info("Rime proxy not available (Rime may not be enabled)")
  end

  M.initialized = true
  lib.info("lgi backend initialized successfully")
  return true
end

---Get current input method name
---@return string|nil: current IM name or nil if failed
M.get_current_im = function()
  if not M.initialized or not M.fcitx_proxy then
    return nil
  end

  local ok, result = pcall(function()
    return M.fcitx_proxy:call_sync("GetCurrentInputMethod", nil, Gio.DBusCallFlags.NONE, -1, nil)
  end)

  if ok and result then
    local imname = result and result[1] or result
    lib.info(string.format("Current IM (D-Bus via lgi): %s", tostring(imname)))
    return imname
  end

  lib.error("Failed to get current IM via D-Bus (lgi)")
  return nil
end

---Switch to a specific input method
---@param imname string: target input method name
---@return boolean: true if successful
M.switch_to_im = function(imname)
  if not M.initialized or not M.fcitx_proxy then
    return false
  end

  local ok, err = pcall(function()
    M.fcitx_proxy:call_sync("SetCurrentInputMethod", GLib.Variant("(s)", {imname}), Gio.DBusCallFlags.NONE, -1, nil)
  end)

  if ok then
    lib.info(string.format("Switched to IM (D-Bus via lgi): %s", imname))
    return true
  end

  lib.error(string.format("Failed to switch to IM %s: %s", imname, tostring(err)))
  return false
end

---Get Rime ascii_mode state
---@return boolean|nil: ascii_mode state or nil if not supported
M.get_rime_ascii_mode = function()
  if not M.initialized or not M.rime_proxy then
    return nil
  end

  local ok, result = pcall(function()
    return M.rime_proxy:call_sync("GetProperty", GLib.Variant("(s)", {"ascii_mode"}), Gio.DBusCallFlags.NONE, -1, nil)
  end)

  if ok and result then
    local value = result and result[1] or result
    lib.info(string.format("Rime ascii_mode: %s", tostring(value)))
    return value == true
  end

  lib.error("Failed to get Rime ascii_mode (lgi)")
  return nil
end

---Set Rime ascii_mode state
---@param ascii boolean: ascii_mode value
---@return boolean: true if successful
M.set_rime_ascii_mode = function(ascii)
  if not M.initialized or not M.rime_proxy then
    return false
  end

  local ok, err = pcall(function()
    M.rime_proxy:call_sync("SetProperty", GLib.Variant("(sb)", {"ascii_mode", ascii}), Gio.DBusCallFlags.NONE, -1, nil)
  end)

  if ok then
    lib.info(string.format("Set Rime ascii_mode: %s", tostring(ascii)))
    return true
  end

  lib.error(string.format("Failed to set Rime ascii_mode: %s", tostring(err)))
  return false
end

return M
