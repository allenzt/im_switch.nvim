local lib = require("im_switch.lib")

local M = {
  name = "ldbus",
  initialized = false,
  bus = nil,
  fcitx_proxy = nil,
  rime_proxy = nil,
}

---Initialize the ldbus D-Bus backend
---@return boolean: true if successful
M.init = function()
  -- Try to require ldbus
  local ok, dbus = pcall(require, "dbus.shared")
  if not ok then
    lib.info("ldbus not available")
    return false
  end

  -- Create session bus
  local bus_ok, session_bus = pcall(dbus.SessionBus)
  if not bus_ok then
    lib.error("Failed to create D-Bus session bus: " .. tostring(session_bus))
    return false
  end

  M.bus = session_bus

  -- Create fcitx5 controller proxy
  local fcitx_ok, fcitx_proxy = pcall(function()
    return M.bus:proxy(
      "org.fcitx.Fcitx5",
      "/controller",
      "org.fcitx.Fcitx.Controller1"
    )
  end)

  if not fcitx_ok then
    lib.error("Failed to create fcitx5 controller proxy: " .. tostring(fcitx_proxy))
    return false
  end

  M.fcitx_proxy = fcitx_proxy

  -- Try to create Rime proxy (optional)
  local rime_ok, rime_proxy = pcall(function()
    return M.bus:proxy(
      "org.fcitx.Fcitx5",
      "/rime",
      "org.fcitx.Fcitx.Rime1"
    )
  end)

  if rime_ok then
    M.rime_proxy = rime_proxy
    lib.info("Rime proxy created successfully")
  else
    lib.info("Rime proxy not available (Rime may not be enabled)")
  end

  M.initialized = true
  lib.info("ldbus backend initialized successfully")
  return true
end

---Get current input method name
---@return string|nil: current IM name or nil if failed
M.get_current_im = function()
  if not M.initialized or not M.fcitx_proxy then
    return nil
  end

  local ok, result = pcall(function()
    return M.fcitx_proxy:GetCurrentInputMethod()
  end)

  if ok and result then
    lib.info(string.format("Current IM (D-Bus): %s", result))
    return result
  end

  lib.error("Failed to get current IM via D-Bus")
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
    M.fcitx_proxy:SetCurrentInputMethod(imname)
  end)

  if ok then
    lib.info(string.format("Switched to IM (D-Bus): %s", imname))
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
    return M.rime_proxy:GetProperty("ascii_mode")
  end)

  if ok then
    lib.info(string.format("Rime ascii_mode: %s", tostring(result)))
    return result == true
  end

  lib.error("Failed to get Rime ascii_mode: " .. tostring(result))
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
    M.rime_proxy:SetProperty("ascii_mode", ascii)
  end)

  if ok then
    lib.info(string.format("Set Rime ascii_mode: %s", tostring(ascii)))
    return true
  end

  lib.error(string.format("Failed to set Rime ascii_mode: %s", tostring(err)))
  return false
end

return M
